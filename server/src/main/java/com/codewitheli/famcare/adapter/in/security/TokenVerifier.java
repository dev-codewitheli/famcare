package com.codewitheli.famcare.adapter.in.security;

import com.codewitheli.famcare.application.AuthenticatedUser;

/** Turns a bearer token into a verified caller, or throws {@link InvalidTokenException}. */
public interface TokenVerifier {

    AuthenticatedUser verify(String bearerToken);

    class InvalidTokenException extends RuntimeException {
        public InvalidTokenException(String message, Throwable cause) {
            super(message, cause);
        }
    }
}
