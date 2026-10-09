package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.ArrivalNoticeRepository;
import com.codewitheli.famcare.domain.model.ArrivalNotice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
class ArrivalNoticePersistenceAdapter implements ArrivalNoticeRepository {

    interface Jpa extends JpaRepository<ArrivalNoticeEntity, UUID> {
        List<ArrivalNoticeEntity> findByFamilyIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(UUID familyId,
                                                                                               Instant since);

        List<ArrivalNoticeEntity> findByDueNotifiedAtIsNullAndCreatedAtGreaterThanEqual(Instant since);

        @Modifying
        @Query("delete from ArrivalNoticeEntity n where n.memberId = :memberId")
        void deleteByMemberId(UUID memberId);

        @Modifying
        @Query("delete from ArrivalNoticeEntity n where n.createdAt < :cutoff")
        int deleteCreatedBefore(Instant cutoff);

        @Modifying
        @Query("delete from ArrivalNoticeEntity n where n.familyId = :familyId")
        void deleteByFamilyId(UUID familyId);
    }

    interface SeenJpa extends JpaRepository<ArrivalSeenEntity, ArrivalSeenEntity.Key> {
        @Query("select s from ArrivalSeenEntity s where s.key.noticeId in :noticeIds order by s.seenAt")
        List<ArrivalSeenEntity> findByNoticeIds(Collection<UUID> noticeIds);
    }

    private final Jpa jpa;
    private final SeenJpa seen;

    ArrivalNoticePersistenceAdapter(Jpa jpa, SeenJpa seen) {
        this.jpa = jpa;
        this.seen = seen;
    }

    @Override
    public ArrivalNotice save(ArrivalNotice notice) {
        return jpa.save(ArrivalNoticeEntity.from(notice)).toDomain();
    }

    @Override
    public Optional<ArrivalNotice> findById(UUID id) {
        return jpa.findById(id).map(ArrivalNoticeEntity::toDomain);
    }

    @Override
    public List<ArrivalNotice> findByFamilyCreatedSince(UUID familyId, Instant since) {
        return jpa.findByFamilyIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(familyId, since).stream()
                .map(ArrivalNoticeEntity::toDomain)
                .toList();
    }

    @Override
    public List<ArrivalNotice> findUnremindedCreatedSince(Instant since) {
        return jpa.findByDueNotifiedAtIsNullAndCreatedAtGreaterThanEqual(since).stream()
                .map(ArrivalNoticeEntity::toDomain)
                .toList();
    }

    @Override
    public void deleteByMember(UUID memberId) {
        // The database removes the matching arrival_seen rows (ON DELETE CASCADE).
        jpa.deleteByMemberId(memberId);
    }

    @Override
    public int deleteCreatedBefore(Instant cutoff) {
        // arrival_seen rows go with them (ON DELETE CASCADE).
        return jpa.deleteCreatedBefore(cutoff);
    }

    @Override
    public void deleteByFamily(UUID familyId) {
        // arrival_seen rows go with them (ON DELETE CASCADE).
        jpa.deleteByFamilyId(familyId);
    }

    @Override
    public void markSeen(UUID noticeId, UUID memberId, Instant now) {
        if (!seen.existsById(new ArrivalSeenEntity.Key(noticeId, memberId))) {
            seen.save(new ArrivalSeenEntity(noticeId, memberId, now));
        }
    }

    @Override
    public Map<UUID, List<UUID>> seenBy(Collection<UUID> noticeIds) {
        if (noticeIds.isEmpty()) {
            return Map.of();
        }
        return seen.findByNoticeIds(noticeIds).stream().collect(Collectors.groupingBy(
                ArrivalSeenEntity::noticeId,
                Collectors.mapping(ArrivalSeenEntity::memberId, Collectors.toList())));
    }
}
