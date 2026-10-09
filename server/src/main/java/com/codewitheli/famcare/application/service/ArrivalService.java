package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.ArrivalView;
import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.NotFoundException;
import com.codewitheli.famcare.application.port.in.ArrivalUseCase;
import com.codewitheli.famcare.application.port.out.ArrivalNoticeRepository;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.domain.model.ArrivalNotice;
import com.codewitheli.famcare.domain.model.Member;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
@Transactional
public class ArrivalService implements ArrivalUseCase {

    private final ArrivalNoticeRepository notices;
    private final MemberRepository members;
    private final MemberLookup memberLookup;
    private final FamilyNotifier notifier;
    private final Clock clock;

    ArrivalService(ArrivalNoticeRepository notices, MemberRepository members, MemberLookup memberLookup,
                   FamilyNotifier notifier, Clock clock) {
        this.notices = notices;
        this.members = members;
        this.memberLookup = memberLookup;
        this.notifier = notifier;
        this.clock = clock;
    }

    @Override
    public ArrivalView announce(AuthenticatedUser user, int etaMinutes) {
        var me = memberLookup.require(user);
        notices.deleteByMember(me.id());
        var notice = notices.save(ArrivalNotice.announce(me.familyId(), me.id(), etaMinutes, clock.instant()));
        notifier.notifyOthers(me, PushMessage.ARRIVAL_HEADS_UP, Map.of(
                "noticeId", notice.id().toString(),
                "senderName", me.displayName(),
                "etaMinutes", String.valueOf(etaMinutes)));
        var notified = members.findByFamilyId(me.familyId()).stream()
                .filter(m -> !m.id().equals(me.id()))
                .toList();
        return new ArrivalView(notice, me, List.of(), notified);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ArrivalView> active(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        var now = clock.instant();
        var family = familyById(me.familyId());
        var active = notices.findByFamilyCreatedSince(me.familyId(), ArrivalNotice.oldestActiveCreatedAt(now)).stream()
                .filter(n -> n.isActive(now))
                .sorted(Comparator.comparing(ArrivalNotice::expectedAt))
                .toList();
        var seen = notices.seenBy(active.stream().map(ArrivalNotice::id).toList());
        return active.stream()
                .map(n -> new ArrivalView(n, family.get(n.memberId()), names(seen.get(n.id()), family), List.of()))
                .toList();
    }

    @Override
    public void cancelMine(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        var now = clock.instant();
        var hadActive = notices.findByFamilyCreatedSince(me.familyId(), ArrivalNotice.oldestActiveCreatedAt(now))
                .stream()
                .anyMatch(n -> n.memberId().equals(me.id()) && n.isActive(now));
        notices.deleteByMember(me.id());
        if (hadActive) {
            // Their "on the way" card and notification go away.
            notifier.notifyOthers(me, PushMessage.ARRIVAL_CANCELLED, Map.of("senderName", me.displayName()));
        }
    }

    @Override
    public ArrivalView markSeen(AuthenticatedUser user, UUID noticeId) {
        var me = memberLookup.require(user);
        var notice = notices.findById(noticeId)
                .filter(n -> n.familyId().equals(me.familyId()) && n.isActive(clock.instant()))
                .orElseThrow(() -> new NotFoundException("That heads-up has ended"));
        var family = familyById(me.familyId());
        if (!notice.memberId().equals(me.id())) {
            var alreadySeen = notices.seenBy(List.of(noticeId)).getOrDefault(noticeId, List.of()).contains(me.id());
            notices.markSeen(noticeId, me.id(), clock.instant());
            if (!alreadySeen) {
                notifier.notifyMember(notice.familyId(), notice.memberId(), PushMessage.ARRIVAL_SEEN, Map.of(
                        "noticeId", noticeId.toString(),
                        "seenByName", me.displayName()));
            }
        }
        var seen = notices.seenBy(List.of(noticeId)).get(noticeId);
        return new ArrivalView(notice, family.get(notice.memberId()), names(seen, family), List.of());
    }

    @Override
    public void sendDueReminders() {
        var now = clock.instant();
        for (var notice : notices.findUnremindedCreatedSince(ArrivalNotice.oldestActiveCreatedAt(now))) {
            if (!notice.needsDueReminder(now)) {
                continue;
            }
            notices.save(notice.dueNotified(now));
            notifier.notifyMember(notice.familyId(), notice.memberId(), PushMessage.ARRIVAL_DUE, Map.of(
                    "noticeId", notice.id().toString(),
                    "etaMinutes", String.valueOf(notice.etaMinutes())));
        }
    }

    private Map<UUID, Member> familyById(UUID familyId) {
        return members.findByFamilyId(familyId).stream().collect(Collectors.toMap(Member::id, Function.identity()));
    }

    /** Members who've since left the family drop out of the "seen by" list. */
    private static List<Member> names(List<UUID> memberIds, Map<UUID, Member> family) {
        return memberIds == null ? List.of() : memberIds.stream().map(family::get).filter(Objects::nonNull).toList();
    }
}
