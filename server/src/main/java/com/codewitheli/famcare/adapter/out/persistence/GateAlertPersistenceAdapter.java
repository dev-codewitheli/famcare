package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.GateAlertRepository;
import com.codewitheli.famcare.domain.model.GateAlert;
import com.codewitheli.famcare.domain.model.GateAlertStatus;
import org.springframework.data.domain.Limit;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Component
class GateAlertPersistenceAdapter implements GateAlertRepository {

    interface Jpa extends JpaRepository<GateAlertEntity, UUID> {
        Optional<GateAlertEntity> findFirstByFamilyIdAndStatusOrderByCreatedAtDesc(UUID familyId,
                                                                                   GateAlertStatus status);

        List<GateAlertEntity> findByStatus(GateAlertStatus status);

        List<GateAlertEntity> findByFamilyIdOrderByCreatedAtDesc(UUID familyId, Limit limit);

        @Modifying
        @Query("delete from GateAlertEntity a where a.createdAt < :cutoff and a.status <> :ringing")
        int deleteCreatedBefore(Instant cutoff, GateAlertStatus ringing);
    }

    private final Jpa jpa;

    GateAlertPersistenceAdapter(Jpa jpa) {
        this.jpa = jpa;
    }

    @Override
    public GateAlert save(GateAlert alert) {
        return jpa.save(GateAlertEntity.from(alert)).toDomain();
    }

    @Override
    public Optional<GateAlert> findById(UUID id) {
        return jpa.findById(id).map(GateAlertEntity::toDomain);
    }

    @Override
    public Optional<GateAlert> findRingingByFamily(UUID familyId) {
        return jpa.findFirstByFamilyIdAndStatusOrderByCreatedAtDesc(familyId, GateAlertStatus.RINGING)
                .map(GateAlertEntity::toDomain);
    }

    @Override
    public List<GateAlert> findAllRinging() {
        return jpa.findByStatus(GateAlertStatus.RINGING).stream().map(GateAlertEntity::toDomain).toList();
    }

    @Override
    public int deleteFinishedCreatedBefore(Instant cutoff) {
        return jpa.deleteCreatedBefore(cutoff, GateAlertStatus.RINGING);
    }

    @Override
    public List<GateAlert> findRecentByFamily(UUID familyId, int limit) {
        return jpa.findByFamilyIdOrderByCreatedAtDesc(familyId, Limit.of(limit)).stream()
                .map(GateAlertEntity::toDomain)
                .toList();
    }
}
