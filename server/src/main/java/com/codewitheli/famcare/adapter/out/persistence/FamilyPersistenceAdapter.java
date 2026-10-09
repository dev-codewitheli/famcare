package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.FamilyRepository;
import com.codewitheli.famcare.domain.model.Family;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;
import java.util.UUID;

@Component
class FamilyPersistenceAdapter implements FamilyRepository {

    interface Jpa extends JpaRepository<FamilyEntity, UUID> {
        Optional<FamilyEntity> findByInviteCode(String inviteCode);
    }

    private final Jpa jpa;

    FamilyPersistenceAdapter(Jpa jpa) {
        this.jpa = jpa;
    }

    @Override
    public Family save(Family family) {
        return jpa.save(FamilyEntity.from(family)).toDomain();
    }

    @Override
    public Optional<Family> findById(UUID id) {
        return jpa.findById(id).map(FamilyEntity::toDomain);
    }

    @Override
    public Optional<Family> findByInviteCode(String inviteCode) {
        return jpa.findByInviteCode(inviteCode).map(FamilyEntity::toDomain);
    }

    @Override
    public void deleteById(UUID id) {
        jpa.deleteById(id);
    }
}
