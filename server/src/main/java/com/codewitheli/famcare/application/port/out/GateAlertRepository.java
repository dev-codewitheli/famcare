package com.codewitheli.famcare.application.port.out;

import com.codewitheli.famcare.domain.model.GateAlert;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GateAlertRepository {
    GateAlert save(GateAlert alert);

    Optional<GateAlert> findById(UUID id);

    Optional<GateAlert> findRingingByFamily(UUID familyId);

    List<GateAlert> findAllRinging();

    /** Newest first. */
    List<GateAlert> findRecentByFamily(UUID familyId, int limit);

    /** Retention: finished alerts created before the cutoff. Returns how many were deleted. */
    int deleteFinishedCreatedBefore(Instant cutoff);

    /** Ringing ones too. */
    void deleteByFamily(UUID familyId);
}
