package com.codewitheli.famcare.adapter.in.web.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Change what the family sees for me. Both fields are optional: null leaves it as is (older apps
 * only send a nickname). {@code avatar} is a family-role icon key; an empty string removes it.
 */
public record RenameMeRequest(@Size(min = 1, max = 40) @Pattern(regexp = "(?s).*\\S.*") String displayName,
                              @Pattern(regexp = "|[a-z_]{1,20}") String avatar) {
}
