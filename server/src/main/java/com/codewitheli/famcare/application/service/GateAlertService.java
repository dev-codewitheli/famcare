package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.GateAlertView;
import com.codewitheli.famcare.application.NotFoundException;
import com.codewitheli.famcare.application.port.in.GateAlertUseCase;
import com.codewitheli.famcare.application.port.out.DeviceRepository;
import com.codewitheli.famcare.application.port.out.GateAlertRepository;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.application.port.out.PushNotifier;
import com.codewitheli.famcare.domain.model.GateAlert;
import com.codewitheli.famcare.domain.model.Member;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.function.Predicate;

@Service
@Transactional
public class GateAlertService implements GateAlertUseCase {

    private static final Logger log = LoggerFactory.getLogger(GateAlertService.class);

    private final GateAlertRepository alerts;
    private final MemberRepository members;
    private final DeviceRepository devices;
    private final PushNotifier push;
    private final MemberLookup memberLookup;
    private final GateAlertProperties properties;
    private final Clock clock;

    GateAlertService(GateAlertRepository alerts, MemberRepository members, DeviceRepository devices,
                     PushNotifier push, MemberLookup memberLookup, GateAlertProperties properties, Clock clock) {
        this.alerts = alerts;
        this.members = members;
        this.devices = devices;
        this.push = push;
        this.memberLookup = memberLookup;
        this.properties = properties;
        this.clock = clock;
    }

    @Override
    public GateAlertView ring(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        var existing = alerts.findRingingByFamily(me.familyId());
        if (existing.isPresent()) {
            return view(existing.get());
        }
        var alert = alerts.save(GateAlert.ring(me.familyId(), me.id(), clock.instant()));
        sendRing(alert, me);
        return view(alert);
    }

    @Override
    public GateAlertView acknowledge(AuthenticatedUser user, UUID alertId) {
        var me = memberLookup.require(user);
        var alert = requireFamilyAlert(alertId, me);
        alert.acknowledge(me.id(), clock.instant());
        alerts.save(alert);
        // Everyone else gets it: the sender sees "Papa is coming", the others stop ringing.
        notifyFamily(alert, m -> !m.id().equals(me.id()), PushMessage.GATE_ACKNOWLEDGED,
                Map.of("acknowledgedByName", me.displayName()));
        return view(alert);
    }

    @Override
    public GateAlertView cancel(AuthenticatedUser user, UUID alertId) {
        var me = memberLookup.require(user);
        var alert = requireFamilyAlert(alertId, me);
        alert.cancel(me.id(), clock.instant());
        alerts.save(alert);
        notifyFamily(alert, m -> !m.id().equals(me.id()), PushMessage.GATE_CANCELLED, Map.of());
        return view(alert);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<GateAlertView> active(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        return alerts.findRingingByFamily(me.familyId()).map(this::view);
    }

    @Override
    @Transactional(readOnly = true)
    public GateAlertView get(AuthenticatedUser user, UUID alertId) {
        return view(requireFamilyAlert(alertId, memberLookup.require(user)));
    }

    @Override
    public void processRingingAlerts() {
        var now = clock.instant();
        for (var alert : alerts.findAllRinging()) {
            if (!alert.isDueForRing(now, properties.ringInterval())) {
                continue;
            }
            if (alert.ringCount() >= properties.maxRings()) {
                alert.expire(now);
                alerts.save(alert);
                // The sender gets "nobody answered — try calling"; everyone else's phone goes quiet.
                notifyFamily(alert, m -> true, PushMessage.GATE_EXPIRED, Map.of());
                log.info("Gate alert {} expired after {} rings", alert.id(), alert.ringCount());
            } else {
                alert.ringAgain(now);
                alerts.save(alert);
                sendRing(alert, members.findById(alert.senderId()).orElseThrow());
            }
        }
    }

    private void sendRing(GateAlert alert, Member sender) {
        notifyFamily(alert, m -> !m.id().equals(sender.id()), PushMessage.GATE_RING,
                Map.of("senderName", sender.displayName(), "ringCount", String.valueOf(alert.ringCount())));
    }

    private void notifyFamily(GateAlert alert, Predicate<Member> recipients, String type,
                              Map<String, String> extra) {
        var memberIds = members.findByFamilyId(alert.familyId()).stream()
                .filter(recipients)
                .map(Member::id)
                .toList();
        var tokens = devices.tokensFor(memberIds);
        if (tokens.isEmpty()) {
            return;
        }
        var data = new HashMap<>(extra);
        data.put("type", type);
        data.put("alertId", alert.id().toString());
        // Lets each phone tell whether it's the one at the gate (e.g., "Papa is coming!" vs. silently stop ringing).
        data.put("senderId", alert.senderId().toString());
        var invalid = push.send(tokens, new PushMessage(type, Map.copyOf(data), properties.pushTtl()));
        if (!invalid.isEmpty()) {
            devices.deleteTokens(invalid);
        }
    }

    private GateAlert requireFamilyAlert(UUID alertId, Member me) {
        return alerts.findById(alertId)
                .filter(a -> a.familyId().equals(me.familyId()))
                .orElseThrow(() -> new NotFoundException("Gate alert not found"));
    }

    private GateAlertView view(GateAlert alert) {
        var sender = members.findById(alert.senderId()).orElseThrow();
        var acknowledgedBy = alert.acknowledgedBy() == null ? null
                : members.findById(alert.acknowledgedBy()).orElse(null);
        return new GateAlertView(alert, sender, acknowledgedBy);
    }
}
