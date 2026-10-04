package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.domain.model.Family;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "families")
class FamilyEntity {

    @Id
    private UUID id;
    private String name;
    private String inviteCode;
    private Instant createdAt;

    protected FamilyEntity() {
    }

    static FamilyEntity from(Family family) {
        var entity = new FamilyEntity();
        entity.id = family.id();
        entity.name = family.name();
        entity.inviteCode = family.inviteCode();
        entity.createdAt = family.createdAt();
        return entity;
    }

    Family toDomain() {
        return new Family(id, name, inviteCode, createdAt);
    }
}
