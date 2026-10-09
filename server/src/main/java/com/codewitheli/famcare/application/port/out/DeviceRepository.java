package com.codewitheli.famcare.application.port.out;

import java.util.Collection;
import java.util.List;
import java.util.UUID;

public interface DeviceRepository {
    /** A token belongs to one member; registering it again moves it (e.g., a shared phone). */
    void upsert(UUID memberId, String pushToken);

    List<String> tokensFor(Collection<UUID> memberIds);

    void deleteTokens(Collection<String> pushTokens);

    void deleteByMember(UUID memberId);

    /** Removes the token only if it's registered to that member. */
    void deleteToken(UUID memberId, String pushToken);

    /** Every phone of anyone who was ever in the family. */
    void deleteByFamily(UUID familyId);
}
