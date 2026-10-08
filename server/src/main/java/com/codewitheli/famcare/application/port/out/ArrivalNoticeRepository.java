package com.codewitheli.famcare.application.port.out;

import com.codewitheli.famcare.domain.model.ArrivalNotice;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

public interface ArrivalNoticeRepository {
    ArrivalNotice save(ArrivalNotice notice);

    /** Notices created at or after {@code since}, newest first; callers filter by {@link ArrivalNotice#isActive}. */
    List<ArrivalNotice> findByFamilyCreatedSince(UUID familyId, Instant since);

    /** A member has one notice at a time: a new one replaces it, and ringing the gate clears it. */
    void deleteByMember(UUID memberId);
}
