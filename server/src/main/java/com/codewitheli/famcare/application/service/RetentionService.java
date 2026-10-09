package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.port.in.RetentionUseCase;
import com.codewitheli.famcare.application.port.out.ArrivalNoticeRepository;
import com.codewitheli.famcare.application.port.out.GateAlertRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.Duration;

/** Keeps only recent activity, as the privacy policy promises. */
@Service
@Transactional
public class RetentionService implements RetentionUseCase {

    private static final Logger log = LoggerFactory.getLogger(RetentionService.class);

    /** Heads-ups are useless an hour or so after they're sent; a day leaves room for debugging. */
    private static final Duration ARRIVAL_RETENTION = Duration.ofDays(1);

    private final GateAlertRepository alerts;
    private final ArrivalNoticeRepository arrivals;
    private final Duration gateAlertRetention;
    private final Clock clock;

    RetentionService(GateAlertRepository alerts, ArrivalNoticeRepository arrivals,
                     @Value("${famcare.retention.gate-alerts:90d}") Duration gateAlertRetention, Clock clock) {
        this.alerts = alerts;
        this.arrivals = arrivals;
        this.gateAlertRetention = gateAlertRetention;
        this.clock = clock;
    }

    @Override
    public void purgeOldActivity() {
        var now = clock.instant();
        var gateAlerts = alerts.deleteFinishedCreatedBefore(now.minus(gateAlertRetention));
        var notices = arrivals.deleteCreatedBefore(now.minus(ARRIVAL_RETENTION));
        if (gateAlerts + notices > 0) {
            log.info("Retention: deleted {} gate alerts and {} heads-ups", gateAlerts, notices);
        }
    }
}
