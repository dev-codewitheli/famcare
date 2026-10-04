package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateFamilyRequest(
        @NotBlank @Size(max = 80) String familyName,
        @NotBlank @Size(max = 40) String displayName) {
}
