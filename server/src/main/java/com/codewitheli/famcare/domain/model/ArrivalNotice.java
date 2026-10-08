package com.codewitheli.famcare.domain.model;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

/**
 * "I'm on my way, about N minutes." Lets someone at home head to the gate before the ring.
 * A notice stays relevant a little past its expected arrival, then quietly expires.
 */
public record ArrivalNotice(UUID id, UUID familyId, UUID memberId, int etaMinutes, Instant createdAt) {

    public static final int MIN_ETA_MINUTES = 1;
    public static final int MAX_ETA_MINUTES = 60;

    /** How long after the expected arrival the notice still shows (traffic happens). */
    public static final Duration GRACE = Duration.ofMinutes(10);

    public ArrivalNotice {
        if (etaMinutes < MIN_ETA_MINUTES || etaMinutes > MAX_ETA_MINUTES) {
            throw new IllegalArgumentException("ETA must be between %d and %d minutes"
                    .formatted(MIN_ETA_MINUTES, MAX_ETA_MINUTES));
        }
    }

    public static ArrivalNotice announce(UUID familyId, UUID memberId, int etaMinutes, Instant now) {
        return new ArrivalNotice(UUID.randomUUID(), familyId, memberId, etaMinutes, now);
    }

    public Instant expectedAt() {
        return createdAt.plus(Duration.ofMinutes(etaMinutes));
    }

    public boolean isActive(Instant now) {
        return now.isBefore(expectedAt().plus(GRACE));
    }

    /** Oldest creation time a notice can have and still be active, for repository queries. */
    public static Instant oldestActiveCreatedAt(Instant now) {
        return now.minus(Duration.ofMinutes(MAX_ETA_MINUTES)).minus(GRACE);
    }
}
