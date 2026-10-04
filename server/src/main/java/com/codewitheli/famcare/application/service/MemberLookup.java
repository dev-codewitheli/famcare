package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.NotInFamilyException;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.domain.model.Member;
import org.springframework.stereotype.Component;

@Component
class MemberLookup {

    private final MemberRepository members;

    MemberLookup(MemberRepository members) {
        this.members = members;
    }

    Member require(AuthenticatedUser user) {
        return members.findByAuthUid(user.uid()).orElseThrow(NotInFamilyException::new);
    }
}
