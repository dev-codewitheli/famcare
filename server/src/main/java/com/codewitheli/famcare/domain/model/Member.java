package com.codewitheli.famcare.domain.model;

import java.time.Instant;
import java.util.UUID;

/**
 * A person in a family. {@code authUid} is the identity-provider subject (Firebase UID);
 * only a display name (nickname) and an optional icon are stored — no email, phone, photo, or
 * other personal data. {@code avatar} is a family-role icon key such as "mother", or null.
 */
public record Member(UUID id, UUID familyId, String authUid, String displayName, MemberRole role,
                     Instant joinedAt, String avatar) {

    public Member withDisplayName(String displayName) {
        return new Member(id, familyId, authUid, displayName, role, joinedAt, avatar);
    }

    public Member withRole(MemberRole role) {
        return new Member(id, familyId, authUid, displayName, role, joinedAt, avatar);
    }

    public Member withAvatar(String avatar) {
        return new Member(id, familyId, authUid, displayName, role, joinedAt, avatar);
    }
}
