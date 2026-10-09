package com.codewitheli.famcare.adapter.in.web.dto;

import java.util.Set;
import java.util.UUID;

/** Who to ring. Null (or no body, from older apps) rings everyone else in the family. */
public record RingRequest(Set<UUID> recipientIds) {
}
