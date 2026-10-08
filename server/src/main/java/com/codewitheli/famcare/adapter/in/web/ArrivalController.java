package com.codewitheli.famcare.adapter.in.web;

import com.codewitheli.famcare.adapter.in.web.dto.AnnounceArrivalRequest;
import com.codewitheli.famcare.adapter.in.web.dto.ArrivalResponse;
import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.ArrivalUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/arrivals")
class ArrivalController {

    private final ArrivalUseCase arrivals;

    ArrivalController(ArrivalUseCase arrivals) {
        this.arrivals = arrivals;
    }

    /** "On my way, about N minutes." Replaces the caller's previous heads-up. */
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    ArrivalResponse announce(@AuthenticationPrincipal AuthenticatedUser user,
                             @Valid @RequestBody AnnounceArrivalRequest request) {
        return ArrivalResponse.from(arrivals.announce(user, request.etaMinutes()));
    }

    @GetMapping("/active")
    List<ArrivalResponse> active(@AuthenticationPrincipal AuthenticatedUser user) {
        return arrivals.active(user).stream().map(ArrivalResponse::from).toList();
    }
}
