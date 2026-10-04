package com.codewitheli.famcare.adapter.in.security;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** Verifies Firebase Authentication ID tokens sent by the apps (signature, expiry, project). */
@Component
@Profile("firebase")
class FirebaseTokenVerifier implements TokenVerifier {

    private final FirebaseAuth auth;

    FirebaseTokenVerifier(FirebaseApp app) {
        this.auth = FirebaseAuth.getInstance(app);
    }

    @Override
    public AuthenticatedUser verify(String bearerToken) {
        try {
            var token = auth.verifyIdToken(bearerToken);
            return new AuthenticatedUser(token.getUid(), token.getName());
        } catch (FirebaseAuthException | IllegalArgumentException e) {
            throw new InvalidTokenException("Invalid Firebase ID token", e);
        }
    }
}
