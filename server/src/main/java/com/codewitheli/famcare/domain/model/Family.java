package com.codewitheli.famcare.domain.model;

import java.time.Instant;
import java.util.UUID;

/** A household. Members join it with a short, shareable invite code. */
public record Family(UUID id, String name, String inviteCode, Instant createdAt) {
}
