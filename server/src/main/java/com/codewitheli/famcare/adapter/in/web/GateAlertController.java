package com.codewitheli.famcare.adapter.in.web;

import com.codewitheli.famcare.adapter.in.web.dto.GateAlertResponse;
import com.codewitheli.famcare.adapter.in.web.dto.RingRequest;
import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.GateAlertUseCase;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/gate-alerts")
class GateAlertController {

    private final GateAlertUseCase gateAlerts;

    GateAlertController(GateAlertUseCase gateAlerts) {
        this.gateAlerts = gateAlerts;
    }

    /**
     * "I'm at the gate", ringing the chosen members (no body: everyone else). Tapping twice doesn't
     * double-ring: the active alert is returned.
     */
    @PostMapping
    GateAlertResponse ring(@AuthenticationPrincipal AuthenticatedUser user,
                           @RequestBody(required = false) RingRequest request) {
        return GateAlertResponse.from(gateAlerts.ring(user, request == null ? null : request.recipientIds()));
    }

    /** 204 when nobody is at the gate. */
    @GetMapping("/active")
    ResponseEntity<GateAlertResponse> active(@AuthenticationPrincipal AuthenticatedUser user) {
        return gateAlerts.active(user)
                .map(GateAlertResponse::from)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    /** Newest first, for the activity list. */
    @GetMapping("/recent")
    List<GateAlertResponse> recent(@AuthenticationPrincipal AuthenticatedUser user,
                                   @RequestParam(defaultValue = "10") int limit) {
        return gateAlerts.recent(user, limit).stream().map(GateAlertResponse::from).toList();
    }

    @GetMapping("/{id}")
    GateAlertResponse get(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) {
        return GateAlertResponse.from(gateAlerts.get(user, id));
    }

    /** "Coming!" */
    @PostMapping("/{id}/acknowledge")
    GateAlertResponse acknowledge(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) {
        return GateAlertResponse.from(gateAlerts.acknowledge(user, id));
    }

    @PostMapping("/{id}/cancel")
    GateAlertResponse cancel(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID id) {
        return GateAlertResponse.from(gateAlerts.cancel(user, id));
    }
}
