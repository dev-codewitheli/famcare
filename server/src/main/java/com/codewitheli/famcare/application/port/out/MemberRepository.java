package com.codewitheli.famcare.application.port.out;

import com.codewitheli.famcare.domain.model.Member;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MemberRepository {
    Member save(Member member);

    Optional<Member> findById(UUID id);

    Optional<Member> findByAuthUid(String authUid);

    List<Member> findByFamilyId(UUID familyId);
}
