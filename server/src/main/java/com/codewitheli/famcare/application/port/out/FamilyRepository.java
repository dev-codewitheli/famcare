package com.codewitheli.famcare.application.port.out;

import com.codewitheli.famcare.domain.model.Family;

import java.util.Optional;
import java.util.UUID;

public interface FamilyRepository {
    Family save(Family family);

    Optional<Family> findById(UUID id);

    Optional<Family> findByInviteCode(String inviteCode);
}
