package com.codewitheli.famcare.application.port.out;

import com.codewitheli.famcare.domain.model.Member;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface MemberRepository {
    Member save(Member member);

    /** Includes removed members, so history can still show their nickname. */
    Optional<Member> findById(UUID id);

    /** Current members only. */
    Optional<Member> findByAuthUid(String authUid);

    /** Current members only, in joining order. */
    List<Member> findByFamilyId(UUID familyId);

    /** Soft delete: frees their sign-in to join (or rejoin) a family later. */
    void markRemoved(UUID memberId, Instant now);
}
