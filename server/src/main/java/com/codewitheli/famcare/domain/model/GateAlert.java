package com.codewitheli.famcare.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.Set;
import java.util.UUID;

/**
 * "I'm at the gate" — rings the family members the sender picked until someone
 * acknowledges it, the sender cancels it, or it expires unanswered.
 */
public class GateAlert {

    private final UUID id;
    private final UUID familyId;
    private final UUID senderId;
    /** Empty for alerts from before recipients could be picked: those ring everyone else. */
    private final Set<UUID> recipientIds;
    private final Instant createdAt;
    private GateAlertStatus status;
    private int ringCount;
    private Instant lastRungAt;
    private UUID acknowledgedBy;
    private Instant resolvedAt;

    public GateAlert(UUID id, UUID familyId, UUID senderId, Set<UUID> recipientIds, Instant createdAt,
                     GateAlertStatus status, int ringCount, Instant lastRungAt, UUID acknowledgedBy,
                     Instant resolvedAt) {
        this.id = id;
        this.familyId = familyId;
        this.senderId = senderId;
        this.recipientIds = Set.copyOf(recipientIds);
        this.createdAt = createdAt;
        this.status = status;
        this.ringCount = ringCount;
        this.lastRungAt = lastRungAt;
        this.acknowledgedBy = acknowledgedBy;
        this.resolvedAt = resolvedAt;
    }

    /** A new alert counts as its first ring. */
    public static GateAlert ring(UUID familyId, UUID senderId, Set<UUID> recipientIds, Instant now) {
        if (recipientIds.contains(senderId)) {
            throw new IllegalArgumentException("The person at the gate can't ring themselves");
        }
        return new GateAlert(UUID.randomUUID(), familyId, senderId, recipientIds, now, GateAlertStatus.RINGING,
                1, now, null, null);
    }

    /** Whether this member's phone rings for the alert. */
    public boolean rings(UUID memberId) {
        return !memberId.equals(senderId) && (recipientIds.isEmpty() || recipientIds.contains(memberId));
    }

    /** The sender and everyone rung: who hears how the alert ends. */
    public boolean involves(UUID memberId) {
        return memberId.equals(senderId) || rings(memberId);
    }

    public void acknowledge(UUID memberId, Instant now) {
        requireRinging();
        if (memberId.equals(senderId)) {
            throw new IllegalStateException("The person at the gate can't answer their own alert");
        }
        status = GateAlertStatus.ACKNOWLEDGED;
        acknowledgedBy = memberId;
        resolvedAt = now;
    }

    public void cancel(UUID memberId, Instant now) {
        requireRinging();
        if (!memberId.equals(senderId)) {
            throw new IllegalStateException("Only the person at the gate can cancel the alert");
        }
        status = GateAlertStatus.CANCELLED;
        resolvedAt = now;
    }

    public boolean isDueForRing(Instant now, Duration interval) {
        return status == GateAlertStatus.RINGING && !lastRungAt.plus(interval).isAfter(now);
    }

    public void ringAgain(Instant now) {
        requireRinging();
        ringCount++;
        lastRungAt = now;
    }

    public void expire(Instant now) {
        requireRinging();
        status = GateAlertStatus.EXPIRED;
        resolvedAt = now;
    }

    private void requireRinging() {
        if (status != GateAlertStatus.RINGING) {
            throw new IllegalStateException("Alert is already " + status.name().toLowerCase());
        }
    }

    public UUID id() { return id; }
    public UUID familyId() { return familyId; }
    public UUID senderId() { return senderId; }
    public Set<UUID> recipientIds() { return recipientIds; }
    public Instant createdAt() { return createdAt; }
    public GateAlertStatus status() { return status; }
    public int ringCount() { return ringCount; }
    public Instant lastRungAt() { return lastRungAt; }
    public UUID acknowledgedBy() { return acknowledgedBy; }
    public Instant resolvedAt() { return resolvedAt; }
}
