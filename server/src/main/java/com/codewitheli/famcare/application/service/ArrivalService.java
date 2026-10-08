package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.ArrivalView;
import com.codewitheli.famcare.application.AuthenticatedUser;
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
        return new ArrivalView(notice, me);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ArrivalView> active(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        var now = clock.instant();
        Map<java.util.UUID, Member> family = members.findByFamilyId(me.familyId()).stream()
                .collect(Collectors.toMap(Member::id, Function.identity()));
        return notices.findByFamilyCreatedSince(me.familyId(), ArrivalNotice.oldestActiveCreatedAt(now)).stream()
                .filter(n -> n.isActive(now))
                .sorted(Comparator.comparing(ArrivalNotice::expectedAt))
                .map(n -> new ArrivalView(n, family.get(n.memberId())))
                .toList();
    }
}
