package com.codewitheli.famcare.application.port.out;

/** The sign-in service (Firebase Authentication in production). */
public interface IdentityProvider {

    /** Deletes the sign-in account itself. Succeeds if it's already gone. */
    void deleteUser(String uid);
}
