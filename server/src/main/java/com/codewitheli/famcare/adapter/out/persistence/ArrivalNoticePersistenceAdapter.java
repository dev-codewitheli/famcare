package com.codewitheli.famcare.adapter.out.persistence;

import com.codewitheli.famcare.application.port.out.ArrivalNoticeRepository;
import com.codewitheli.famcare.domain.model.ArrivalNotice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Component
class ArrivalNoticePersistenceAdapter implements ArrivalNoticeRepository {

    interface Jpa extends JpaRepository<ArrivalNoticeEntity, UUID> {
        List<ArrivalNoticeEntity> findByFamilyIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(UUID familyId,
                                                                                               Instant since);

        @Modifying
        @Query("delete from ArrivalNoticeEntity n where n.memberId = :memberId")
        void deleteByMemberId(UUID memberId);
    }

    private final Jpa jpa;

    ArrivalNoticePersistenceAdapter(Jpa jpa) {
        this.jpa = jpa;
    }

    @Override
    public ArrivalNotice save(ArrivalNotice notice) {
        return jpa.save(ArrivalNoticeEntity.from(notice)).toDomain();
    }

    @Override
    public List<ArrivalNotice> findByFamilyCreatedSince(UUID familyId, Instant since) {
        return jpa.findByFamilyIdAndCreatedAtGreaterThanEqualOrderByCreatedAtDesc(familyId, since).stream()
                .map(ArrivalNoticeEntity::toDomain)
                .toList();
    }

    @Override
    public void deleteByMember(UUID memberId) {
        jpa.deleteByMemberId(memberId);
    }
}
