package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.port.out.DeviceRepository;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.application.port.out.PushNotifier;
import com.codewitheli.famcare.domain.model.Member;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;
import java.util.function.Predicate;

/** Sends a data push to selected members of a family, pruning tokens the push service rejects. */
@Component
class FamilyNotifier {

    /** Heads-ups stay useful for a while; gate rings use the shorter, configured TTL instead. */
    static final Duration DEFAULT_TTL = Duration.ofMinutes(10);

    private final MemberRepository members;
    private final DeviceRepository devices;
    private final PushNotifier push;

    FamilyNotifier(MemberRepository members, DeviceRepository devices, PushNotifier push) {
        this.members = members;
        this.devices = devices;
        this.push = push;
    }

    void notifyOthers(Member me, String type, Map<String, String> data) {
        notify(me.familyId(), m -> !m.id().equals(me.id()), type, data, DEFAULT_TTL);
    }

    void notify(UUID familyId, Predicate<Member> recipients, String type, Map<String, String> data,
                Duration timeToLive) {
        var memberIds = members.findByFamilyId(familyId).stream()
                .filter(recipients)
                .map(Member::id)
                .toList();
        var tokens = devices.tokensFor(memberIds);
        if (tokens.isEmpty()) {
            return;
        }
        var payload = new HashMap<>(data);
        payload.put("type", type);
        var invalid = push.send(tokens, new PushMessage(type, Map.copyOf(payload), timeToLive));
        if (!invalid.isEmpty()) {
            devices.deleteTokens(invalid);
        }
    }
}
