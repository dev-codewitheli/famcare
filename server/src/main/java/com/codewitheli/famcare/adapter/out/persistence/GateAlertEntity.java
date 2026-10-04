package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.domain.model.GateAlert;
import com.codewitheli.famcare.domain.model.GateAlertStatus;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "gate_alerts")
class GateAlertEntity {

    @Id
    private UUID id;
    private UUID familyId;
    private UUID senderId;
    private Instant createdAt;
    @Enumerated(EnumType.STRING)
    private GateAlertStatus status;
    private int ringCount;
    private Instant lastRungAt;
    private UUID acknowledgedBy;
    private Instant resolvedAt;

    protected GateAlertEntity() {
    }

    static GateAlertEntity from(GateAlert alert) {
        var entity = new GateAlertEntity();
        entity.id = alert.id();
        entity.familyId = alert.familyId();
        entity.senderId = alert.senderId();
        entity.createdAt = alert.createdAt();
        entity.status = alert.status();
        entity.ringCount = alert.ringCount();
        entity.lastRungAt = alert.lastRungAt();
        entity.acknowledgedBy = alert.acknowledgedBy();
        entity.resolvedAt = alert.resolvedAt();
        return entity;
    }

    GateAlert toDomain() {
        return new GateAlert(id, familyId, senderId, createdAt, status, ringCount, lastRungAt,
                acknowledgedBy, resolvedAt);
    }
}
