package com.codewitheli.famcare.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * A person in a family. {@code authUid} is the identity-provider subject (Firebase UID);
 * only a display name (nickname) is stored — no email, phone, or other personal data.
 */
public record Member(UUID id, UUID familyId, String authUid, String displayName, MemberRole role,
                     Instant joinedAt) {
}
