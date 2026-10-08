package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.domain.model.ArrivalNotice;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "arrival_notices")
class ArrivalNoticeEntity {

    @Id
    private UUID id;
    private UUID familyId;
    private UUID memberId;
    private int etaMinutes;
    private Instant createdAt;
    private Instant dueNotifiedAt;

    protected ArrivalNoticeEntity() {
    }

    static ArrivalNoticeEntity from(ArrivalNotice notice) {
        var entity = new ArrivalNoticeEntity();
        entity.id = notice.id();
        entity.familyId = notice.familyId();
        entity.memberId = notice.memberId();
        entity.etaMinutes = notice.etaMinutes();
        entity.createdAt = notice.createdAt();
        entity.dueNotifiedAt = notice.dueNotifiedAt();
        return entity;
    }

    ArrivalNotice toDomain() {
        return new ArrivalNotice(id, familyId, memberId, etaMinutes, createdAt, dueNotifiedAt);
    }
}
