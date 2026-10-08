package com.codewitheli.famcare.application;

/** The caller is in the family but isn't allowed to do this (e.g. only its creator can). */
public class ForbiddenException extends RuntimeException {
    public ForbiddenException(String message) {
        super(message);
    }
}
