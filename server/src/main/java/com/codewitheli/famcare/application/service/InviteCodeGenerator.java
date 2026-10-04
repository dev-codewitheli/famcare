package com.codewitheli.famcare.application.service;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;

/** Short codes that are easy to read aloud or text — no 0/O or 1/I/L lookalikes. */
@Component
class InviteCodeGenerator {

    private static final String ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
    private static final int LENGTH = 6;

    private final SecureRandom random = new SecureRandom();

    String next() {
        var code = new StringBuilder(LENGTH);
        for (int i = 0; i < LENGTH; i++) {
            code.append(ALPHABET.charAt(random.nextInt(ALPHABET.length())));
        }
        return code.toString();
    }
}
