package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RenameMeRequest(@NotBlank @Size(max = 40) String displayName) {
}
