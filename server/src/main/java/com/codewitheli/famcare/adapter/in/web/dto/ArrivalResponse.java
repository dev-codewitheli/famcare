package com.codewitheli.famcare.adapter.in.web.dto;

import com.codewitheli.famcare.application.ArrivalView;

import java.time.Instant;
import java.util.UUID;

public record ArrivalResponse(UUID id, MemberResponse member, int etaMinutes, Instant createdAt,
                              Instant expectedAt) {

    public static ArrivalResponse from(ArrivalView view) {
        var notice = view.notice();
        return new ArrivalResponse(notice.id(), MemberResponse.from(view.member()), notice.etaMinutes(),
                notice.createdAt(), notice.expectedAt());
    }
}
