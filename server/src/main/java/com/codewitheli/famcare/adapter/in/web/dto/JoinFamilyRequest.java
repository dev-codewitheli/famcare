package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record JoinFamilyRequest(
        @NotBlank @Size(min = 6, max = 6) String inviteCode,
        @NotBlank @Size(max = 40) String displayName) {
}
