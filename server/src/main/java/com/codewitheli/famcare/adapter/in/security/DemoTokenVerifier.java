package com.codewitheli.famcare.adapter.in.security;

import com.codewitheli.famcare.application.AuthenticatedUser;
import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/**
 * Demo mode only: the bearer token <em>is</em> the user id ({@code Authorization: Bearer demo-papa}),
 * so the API can be explored with curl and the apps can run without a Firebase project.
 * Never active together with the "firebase" profile.
 */
@Component
@Profile("!firebase")
class DemoTokenVerifier implements TokenVerifier {

    private static final Logger log = LoggerFactory.getLogger(DemoTokenVerifier.class);

    @PostConstruct
    void warn() {
        log.warn("DEMO AUTH is enabled — any bearer token is accepted as a user id. "
                + "Activate the 'firebase' profile in production.");
    }

    @Override
    public AuthenticatedUser verify(String bearerToken) {
        if (bearerToken.isBlank() || bearerToken.length() > 128) {
            throw new InvalidTokenException("Demo token must be 1-128 characters", null);
        }
        return new AuthenticatedUser(bearerToken, null);
    }
}
