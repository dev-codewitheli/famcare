package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterDeviceRequest(@NotBlank @Size(max = 512) String pushToken) {
}
