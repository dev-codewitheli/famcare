package com.codewitheli.famcare.adapter.out.persistence;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "devices")
class DeviceEntity {

    @Id
    private String pushToken;
    private UUID memberId;
    private Instant updatedAt;

    protected DeviceEntity() {
    }

    DeviceEntity(String pushToken, UUID memberId, Instant updatedAt) {
        this.pushToken = pushToken;
        this.memberId = memberId;
        this.updatedAt = updatedAt;
    }

    String pushToken() {
        return pushToken;
    }
}
