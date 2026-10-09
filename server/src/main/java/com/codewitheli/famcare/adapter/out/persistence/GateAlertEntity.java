package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.domain.model.GateAlert;
import com.codewitheli.famcare.domain.model.GateAlertStatus;
import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

@Entity
@Table(name = "gate_alerts")
class GateAlertEntity {

    @Id
    private UUID id;
    private UUID familyId;
    private UUID senderId;
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "gate_alert_recipients", joinColumns = @JoinColumn(name = "alert_id"))
    @Column(name = "member_id")
    private Set<UUID> recipientIds = new HashSet<>();
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
        entity.recipientIds = new HashSet<>(alert.recipientIds());
        entity.createdAt = alert.createdAt();
        entity.status = alert.status();
        entity.ringCount = alert.ringCount();
        entity.lastRungAt = alert.lastRungAt();
        entity.acknowledgedBy = alert.acknowledgedBy();
        entity.resolvedAt = alert.resolvedAt();
        return entity;
    }

    GateAlert toDomain() {
        return new GateAlert(id, familyId, senderId, recipientIds, createdAt, status, ringCount, lastRungAt,
                acknowledgedBy, resolvedAt);
    }
}
