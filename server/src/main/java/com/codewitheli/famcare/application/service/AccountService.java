package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.AccountUseCase;
import com.codewitheli.famcare.application.port.out.IdentityProvider;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class AccountService implements AccountUseCase {

    private final MemberRepository members;
    private final FamilyService families;
    private final IdentityProvider identity;

    AccountService(MemberRepository members, FamilyService families, IdentityProvider identity) {
        this.members = members;
        this.families = families;
        this.identity = identity;
    }

    @Override
    public void deleteAccount(AuthenticatedUser user) {
        members.findByAuthUid(user.uid()).ifPresent(me -> families.depart(me, true));
        identity.deleteUser(user.uid());
    }
}
