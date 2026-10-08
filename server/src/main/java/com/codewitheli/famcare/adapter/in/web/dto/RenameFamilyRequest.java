package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RenameFamilyRequest(@NotBlank @Size(max = 80) String familyName) {
}
