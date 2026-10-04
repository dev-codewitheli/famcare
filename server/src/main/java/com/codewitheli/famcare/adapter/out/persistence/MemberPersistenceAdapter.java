package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.MemberRepository;
import com.codewitheli.famcare.domain.model.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
class MemberPersistenceAdapter implements MemberRepository {

    interface Jpa extends JpaRepository<MemberEntity, UUID> {
        Optional<MemberEntity> findByAuthUid(String authUid);

        List<MemberEntity> findByFamilyIdOrderByJoinedAt(UUID familyId);
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
        return jpa.findByAuthUid(authUid).map(MemberEntity::toDomain);
    }

    @Override
    public List<Member> findByFamilyId(UUID familyId) {
        return jpa.findByFamilyIdOrderByJoinedAt(familyId).stream().map(MemberEntity::toDomain).toList();
    }
}
