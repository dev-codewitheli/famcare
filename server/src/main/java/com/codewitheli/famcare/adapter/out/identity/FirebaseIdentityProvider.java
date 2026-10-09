package com.codewitheli.famcare.adapter.out.identity;

import com.codewitheli.famcare.application.port.out.IdentityProvider;
import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.AuthErrorCode;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseAuthException;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("firebase")
class FirebaseIdentityProvider implements IdentityProvider {

    private final FirebaseAuth auth;

    FirebaseIdentityProvider(FirebaseApp app) {
        this.auth = FirebaseAuth.getInstance(app);
    }

    @Override
    public void deleteUser(String uid) {
        try {
            auth.deleteUser(uid);
        } catch (FirebaseAuthException e) {
            if (e.getAuthErrorCode() != AuthErrorCode.USER_NOT_FOUND) {
                throw new IllegalStateException("Couldn't delete the sign-in account", e);
            }
        }
    }
}
