package com.codewitheli.famcare.application.port.out;

import com.codewitheli.famcare.domain.model.ArrivalNotice;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface ArrivalNoticeRepository {
    ArrivalNotice save(ArrivalNotice notice);

    Optional<ArrivalNotice> findById(UUID id);

    /** Notices created at or after {@code since}, newest first; callers filter by {@link ArrivalNotice#isActive}. */
    List<ArrivalNotice> findByFamilyCreatedSince(UUID familyId, Instant since);

    /** Across all families: candidates for the "time's up" reminder (not yet reminded). */
    List<ArrivalNotice> findUnremindedCreatedSince(Instant since);

    /** A member has one notice at a time: a new one replaces it, and ringing the gate clears it. */
    void deleteByMember(UUID memberId);

    /** Idempotent: tapping "Got it" twice counts once. */
    void markSeen(UUID noticeId, UUID memberId, Instant now);

    /** Retention: notices created before the cutoff (long expired). Returns how many were deleted. */
    int deleteCreatedBefore(Instant cutoff);

    void deleteByFamily(UUID familyId);

    /** Who has seen each notice, in the order they tapped "Got it". */
    Map<UUID, List<UUID>> seenBy(Collection<UUID> noticeIds);
}
