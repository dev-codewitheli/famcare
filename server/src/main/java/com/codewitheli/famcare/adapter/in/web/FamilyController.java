package com.codewitheli.famcare.adapter.in.web;

import com.codewitheli.famcare.adapter.in.web.dto.CreateFamilyRequest;
import com.codewitheli.famcare.adapter.in.web.dto.FamilyResponse;
import com.codewitheli.famcare.adapter.in.web.dto.JoinFamilyRequest;
import com.codewitheli.famcare.adapter.in.web.dto.RenameFamilyRequest;
import com.codewitheli.famcare.adapter.in.web.dto.RenameMeRequest;
import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.ManageFamilyUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/families")
class FamilyController {

    private final ManageFamilyUseCase families;

    FamilyController(ManageFamilyUseCase families) {
        this.families = families;
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    FamilyResponse create(@AuthenticationPrincipal AuthenticatedUser user,
                          @Valid @RequestBody CreateFamilyRequest request) {
        return FamilyResponse.from(families.createFamily(user, request.familyName(), request.displayName()));
    }

    @PostMapping("/join")
    FamilyResponse join(@AuthenticationPrincipal AuthenticatedUser user,
                        @Valid @RequestBody JoinFamilyRequest request) {
        return FamilyResponse.from(families.joinFamily(user, request.inviteCode(), request.displayName()));
    }

    /** The apps call this on start-up: 409 NOT_IN_FAMILY means "show onboarding". */
    @GetMapping("/mine")
    FamilyResponse mine(@AuthenticationPrincipal AuthenticatedUser user) {
        return FamilyResponse.from(families.myFamily(user));
    }

    /** Family creator only (403 otherwise). */
    @PatchMapping("/mine")
    FamilyResponse rename(@AuthenticationPrincipal AuthenticatedUser user,
                          @Valid @RequestBody RenameFamilyRequest request) {
        return FamilyResponse.from(families.renameFamily(user, request.familyName()));
    }

    /** Change what the family calls me. */
    @PatchMapping("/mine/me")
    FamilyResponse renameMe(@AuthenticationPrincipal AuthenticatedUser user,
                            @Valid @RequestBody RenameMeRequest request) {
        return FamilyResponse.from(families.renameMe(user, request.displayName()));
    }

    /** Family creator only (403 otherwise); can't remove themselves. */
    @DeleteMapping("/mine/members/{memberId}")
    FamilyResponse removeMember(@AuthenticationPrincipal AuthenticatedUser user, @PathVariable UUID memberId) {
        return FamilyResponse.from(families.removeMember(user, memberId));
    }
}
