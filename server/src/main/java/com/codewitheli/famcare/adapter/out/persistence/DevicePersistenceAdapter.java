package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.DeviceRepository;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.util.Collection;
import java.util.List;
import java.util.UUID;

@Component
class DevicePersistenceAdapter implements DeviceRepository {

    interface Jpa extends JpaRepository<DeviceEntity, String> {
        List<DeviceEntity> findByMemberIdIn(Collection<UUID> memberIds);

        @Modifying
        @Query("delete from DeviceEntity d where d.pushToken in :tokens")
        void deleteByPushTokenIn(Collection<String> tokens);

        @Modifying
        @Query("delete from DeviceEntity d where d.memberId = :memberId")
        void deleteByMemberId(UUID memberId);

        @Modifying
        @Query("delete from DeviceEntity d where d.memberId = :memberId and d.pushToken = :token")
        void deleteByMemberIdAndToken(UUID memberId, String token);

        @Modifying
        @Query("delete from DeviceEntity d where d.memberId in "
                + "(select m.id from MemberEntity m where m.familyId = :familyId)")
        void deleteByFamilyId(UUID familyId);
    }

    private final Jpa jpa;
    private final Clock clock;

    DevicePersistenceAdapter(Jpa jpa, Clock clock) {
        this.jpa = jpa;
        this.clock = clock;
    }

    @Override
    public void upsert(UUID memberId, String pushToken) {
        jpa.save(new DeviceEntity(pushToken, memberId, clock.instant()));
    }

    @Override
    public List<String> tokensFor(Collection<UUID> memberIds) {
        if (memberIds.isEmpty()) {
            return List.of();
        }
        return jpa.findByMemberIdIn(memberIds).stream().map(DeviceEntity::pushToken).toList();
    }

    @Override
    public void deleteTokens(Collection<String> pushTokens) {
        jpa.deleteByPushTokenIn(pushTokens);
    }

    @Override
    public void deleteByMember(UUID memberId) {
        jpa.deleteByMemberId(memberId);
    }

    @Override
    public void deleteToken(UUID memberId, String pushToken) {
        jpa.deleteByMemberIdAndToken(memberId, pushToken);
    }

    @Override
    public void deleteByFamily(UUID familyId) {
        jpa.deleteByFamilyId(familyId);
    }
}
