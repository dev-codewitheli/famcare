package com.codewitheli.famcare.application.port.in;

public interface RetentionUseCase {

    /** Deletes gate activity past its retention period and long-expired heads-ups. Runs daily. */
    void purgeOldActivity();
}
