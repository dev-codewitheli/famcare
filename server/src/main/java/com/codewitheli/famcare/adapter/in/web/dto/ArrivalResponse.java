package com.codewitheli.famcare.adapter.in.web.dto;

import com.codewitheli.famcare.application.ArrivalView;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/**
 * @param seenBy   who tapped "Got it"
 * @param notified who the heads-up was sent to (only in the response to announcing)
 */
public record ArrivalResponse(UUID id, MemberResponse member, int etaMinutes, Instant createdAt,
                              Instant expectedAt, List<MemberResponse> seenBy, List<MemberResponse> notified) {

    public static ArrivalResponse from(ArrivalView view) {
        var notice = view.notice();
        return new ArrivalResponse(notice.id(), MemberResponse.from(view.member()), notice.etaMinutes(),
                notice.createdAt(), notice.expectedAt(),
                view.seenBy().stream().map(MemberResponse::from).toList(),
                view.notified().stream().map(MemberResponse::from).toList());
    }
}
