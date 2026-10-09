package com.codewitheli.famcare.adapter.in.scheduling;

import com.codewitheli.famcare.application.port.in.RetentionUseCase;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Nightly, when nobody is waiting at the gate. */
@Component
class RetentionScheduler {

    private final RetentionUseCase retention;

    RetentionScheduler(RetentionUseCase retention) {
        this.retention = retention;
    }

    @Scheduled(cron = "${famcare.retention.cron:0 30 3 * * *}", zone = "Asia/Manila")
    void purge() {
        retention.purgeOldActivity();
    }
}
