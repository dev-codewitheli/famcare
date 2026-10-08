package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

public record AnnounceArrivalRequest(@Min(1) @Max(60) int etaMinutes) {
}
