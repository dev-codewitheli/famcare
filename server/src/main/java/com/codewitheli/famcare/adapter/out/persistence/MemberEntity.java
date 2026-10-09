package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.domain.model.Member;
import com.codewitheli.famcare.domain.model.MemberRole;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "members")
class MemberEntity {

    @Id
    private UUID id;
    private UUID familyId;
    private String authUid;
    private String displayName;
    @Enumerated(EnumType.STRING)
    private MemberRole role;
    private Instant joinedAt;
    private Instant removedAt;

    protected MemberEntity() {
    }

    /**
     * auth_uid is unique, so it's released (replaced with a placeholder) to let the same Google
     * account join a family again later.
     */
    void markRemoved(Instant now, boolean anonymize) {
        removedAt = now;
        authUid = "removed:" + id;
        if (anonymize) {
            displayName = "Former member";
        }
    }

    static MemberEntity from(Member member) {
        var entity = new MemberEntity();
        entity.id = member.id();
        entity.familyId = member.familyId();
        entity.authUid = member.authUid();
        entity.displayName = member.displayName();
        entity.role = member.role();
        entity.joinedAt = member.joinedAt();
        return entity;
    }

    Member toDomain() {
        return new Member(id, familyId, authUid, displayName, role, joinedAt);
    }
}
