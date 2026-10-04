package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.FamilyView;
import com.codewitheli.famcare.application.NotFoundException;
import com.codewitheli.famcare.application.port.in.ManageFamilyUseCase;
import com.codewitheli.famcare.application.port.out.FamilyRepository;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.domain.model.Family;
import com.codewitheli.famcare.domain.model.Member;
import com.codewitheli.famcare.domain.model.MemberRole;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.util.Locale;
import java.util.UUID;

@Service
@Transactional
public class FamilyService implements ManageFamilyUseCase {

    private final FamilyRepository families;
    private final MemberRepository members;
    private final MemberLookup memberLookup;
    private final InviteCodeGenerator inviteCodes;
    private final Clock clock;

    FamilyService(FamilyRepository families, MemberRepository members, MemberLookup memberLookup,
                  InviteCodeGenerator inviteCodes, Clock clock) {
        this.families = families;
        this.members = members;
        this.memberLookup = memberLookup;
        this.inviteCodes = inviteCodes;
        this.clock = clock;
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
