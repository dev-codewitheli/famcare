package com.codewitheli.famcare.adapter.in.web.dto;

import com.codewitheli.famcare.application.GateAlertView;
import com.codewitheli.famcare.domain.model.GateAlertStatus;

import java.time.Instant;
import java.util.UUID;

public record GateAlertResponse(UUID id, GateAlertStatus status, MemberResponse sender,
                                MemberResponse acknowledgedBy, int ringCount, Instant createdAt,
                                Instant resolvedAt) {

    public static GateAlertResponse from(GateAlertView view) {
        var alert = view.alert();
        return new GateAlertResponse(alert.id(), alert.status(), MemberResponse.from(view.sender()),
                MemberResponse.from(view.acknowledgedBy()), alert.ringCount(), alert.createdAt(),
                alert.resolvedAt());
    }
}
