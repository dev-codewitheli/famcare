package com.codewitheli.famcare.adapter.out.persistence;

import jakarta.persistence.Embeddable;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "arrival_seen")
class ArrivalSeenEntity {

    @Embeddable
    record Key(UUID noticeId, UUID memberId) implements Serializable {
    }

    @EmbeddedId
    private Key key;
    private Instant seenAt;

    protected ArrivalSeenEntity() {
    }

    ArrivalSeenEntity(UUID noticeId, UUID memberId, Instant seenAt) {
        this.key = new Key(noticeId, memberId);
        this.seenAt = seenAt;
    }

    UUID noticeId() {
        return key.noticeId();
    }

    UUID memberId() {
        return key.memberId();
    }
}
