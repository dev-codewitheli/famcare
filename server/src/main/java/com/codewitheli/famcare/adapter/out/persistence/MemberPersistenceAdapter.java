package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.domain.model.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
class MemberPersistenceAdapter implements MemberRepository {

    interface Jpa extends JpaRepository<MemberEntity, UUID> {
        Optional<MemberEntity> findByAuthUidAndRemovedAtIsNull(String authUid);

        List<MemberEntity> findByFamilyIdAndRemovedAtIsNullOrderByJoinedAt(UUID familyId);
    }

    private final Jpa jpa;

    MemberPersistenceAdapter(Jpa jpa) {
        this.jpa = jpa;
    }

    @Override
    public Member save(Member member) {
        return jpa.save(MemberEntity.from(member)).toDomain();
    }

    @Override
    public Optional<Member> findById(UUID id) {
        return jpa.findById(id).map(MemberEntity::toDomain);
    }

    @Override
    public Optional<Member> findByAuthUid(String authUid) {
        return jpa.findByAuthUidAndRemovedAtIsNull(authUid).map(MemberEntity::toDomain);
    }

    @Override
    public List<Member> findByFamilyId(UUID familyId) {
        return jpa.findByFamilyIdAndRemovedAtIsNullOrderByJoinedAt(familyId).stream()
                .map(MemberEntity::toDomain)
                .toList();
    }

    @Override
    public void markRemoved(UUID memberId, Instant now) {
        jpa.findById(memberId).ifPresent(entity -> {
            entity.markRemoved(now);
            jpa.save(entity);
        });
    }
}
