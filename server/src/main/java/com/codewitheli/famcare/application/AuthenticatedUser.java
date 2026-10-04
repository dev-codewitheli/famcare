package com.codewitheli.famcare.application;

/** The verified caller, as reported by the identity provider (Firebase in production). */
public record AuthenticatedUser(String uid, String name) {
}
