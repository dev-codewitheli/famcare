package com.codewitheli.famcare.application;

/** The caller is signed in but hasn't created or joined a family yet. */
public class NotInFamilyException extends RuntimeException {
    public NotInFamilyException() {
        super("Create or join a family first");
    }
}
