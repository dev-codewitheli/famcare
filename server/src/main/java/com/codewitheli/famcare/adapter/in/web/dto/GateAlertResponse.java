package com.codewitheli.famcare.adapter.in.web.dto;

import com.codewitheli.famcare.application.GateAlertView;
import com.codewitheli.famcare.domain.model.GateAlertStatus;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

/** {@code recipients}: who was rung; empty means everyone else (alerts from older versions). */
public record GateAlertResponse(UUID id, GateAlertStatus status, MemberResponse sender,
                                MemberResponse acknowledgedBy, List<MemberResponse> recipients, int ringCount,
                                Instant createdAt, Instant resolvedAt) {

    public static GateAlertResponse from(GateAlertView view) {
        var alert = view.alert();
        return new GateAlertResponse(alert.id(), alert.status(), MemberResponse.from(view.sender()),
                MemberResponse.from(view.acknowledgedBy()),
                view.recipients().stream().map(MemberResponse::from).toList(), alert.ringCount(),
                alert.createdAt(), alert.resolvedAt());
    }
}
