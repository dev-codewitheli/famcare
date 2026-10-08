package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.FamilyView;
import com.codewitheli.famcare.application.ForbiddenException;
import com.codewitheli.famcare.application.NotFoundException;
import com.codewitheli.famcare.application.port.in.ManageFamilyUseCase;
import com.codewitheli.famcare.application.port.out.ArrivalNoticeRepository;
import com.codewitheli.famcare.application.port.out.DeviceRepository;
import com.codewitheli.famcare.application.port.out.FamilyRepository;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.domain.model.Family;
import com.codewitheli.famcare.domain.model.Member;
import com.codewitheli.famcare.domain.model.MemberRole;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@Service
@Transactional
public class FamilyService implements ManageFamilyUseCase {

    private final FamilyRepository families;
    private final MemberRepository members;
    private final DeviceRepository devices;
    private final ArrivalNoticeRepository arrivals;
    private final FamilyNotifier notifier;
    private final MemberLookup memberLookup;
    private final InviteCodeGenerator inviteCodes;
    private final Clock clock;

    FamilyService(FamilyRepository families, MemberRepository members, DeviceRepository devices,
                  ArrivalNoticeRepository arrivals, FamilyNotifier notifier, MemberLookup memberLookup,
                  InviteCodeGenerator inviteCodes, Clock clock) {
        this.families = families;
        this.members = members;
        this.devices = devices;
        this.arrivals = arrivals;
        this.notifier = notifier;
        this.memberLookup = memberLookup;
        this.inviteCodes = inviteCodes;
        this.clock = clock;
    }

    @Override
    public FamilyView renameMe(AuthenticatedUser user, String displayName) {
        var me = memberLookup.require(user);
        members.save(new Member(me.id(), me.familyId(), me.authUid(), displayName.trim(), me.role(), me.joinedAt()));
        return myFamily(user);
    }

    @Override
    public FamilyView renameFamily(AuthenticatedUser user, String familyName) {
        var me = requireCreator(user);
        var family = families.findById(me.familyId()).orElseThrow();
        families.save(new Family(family.id(), familyName.trim(), family.inviteCode(), family.createdAt()));
        return myFamily(user);
    }

    @Override
    public FamilyView removeMember(AuthenticatedUser user, UUID memberId) {
        var me = requireCreator(user);
        if (memberId.equals(me.id())) {
            throw new IllegalStateException("You can't remove yourself");
        }
        var member = members.findByFamilyId(me.familyId()).stream()
                .filter(m -> m.id().equals(memberId))
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Member not found"));
        // Tell their phone first (while it's still registered), then cut them off.
        notifier.notifyMember(member.familyId(), member.id(), PushMessage.MEMBER_REMOVED, Map.of());
        arrivals.deleteByMember(member.id());
        devices.deleteByMember(member.id());
        members.markRemoved(member.id(), clock.instant());
        return myFamily(user);
    }

    private Member requireCreator(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        if (me.role() != MemberRole.PARENT) {
            throw new ForbiddenException("Only the person who set up the family can do this");
        }
        return me;
    }

    @Override
    public FamilyView createFamily(AuthenticatedUser user, String familyName, String displayName) {
        requireNotInFamily(user);
        var family = families.save(new Family(UUID.randomUUID(), familyName.trim(), uniqueInviteCode(),
                clock.instant()));
        addMember(user, family, displayName, MemberRole.PARENT);
        return myFamily(user);
    }

    @Override
    public FamilyView joinFamily(AuthenticatedUser user, String inviteCode, String displayName) {
        requireNotInFamily(user);
        var family = families.findByInviteCode(inviteCode.trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new NotFoundException("No family has that invite code"));
        addMember(user, family, displayName, MemberRole.MEMBER);
        return myFamily(user);
    }

    @Override
    @Transactional(readOnly = true)
    public FamilyView myFamily(AuthenticatedUser user) {
        var me = memberLookup.require(user);
        var family = families.findById(me.familyId()).orElseThrow();
        return new FamilyView(family, me, members.findByFamilyId(family.id()));
    }

    private void addMember(AuthenticatedUser user, Family family, String displayName, MemberRole role) {
        members.save(new Member(UUID.randomUUID(), family.id(), user.uid(), displayName.trim(), role,
                clock.instant()));
    }

    private void requireNotInFamily(AuthenticatedUser user) {
        if (members.findByAuthUid(user.uid()).isPresent()) {
            throw new IllegalStateException("You're already in a family");
        }
    }

    private String uniqueInviteCode() {
        String code;
        do {
            code = inviteCodes.next();
        } while (families.findByInviteCode(code).isPresent());
        return code;
    }
}
