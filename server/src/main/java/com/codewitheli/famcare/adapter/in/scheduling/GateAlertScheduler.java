package com.codewitheli.famcare.adapter.in.scheduling;

import com.codewitheli.famcare.application.port.in.ArrivalUseCase;
import com.codewitheli.famcare.application.port.in.GateAlertUseCase;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * Every few seconds: re-ring or expire unanswered gate alerts, and send "time's up" reminders
 * for "on my way" heads-ups.
 */
@Component
class GateAlertScheduler {

    private final GateAlertUseCase gateAlerts;
    private final ArrivalUseCase arrivals;

    GateAlertScheduler(GateAlertUseCase gateAlerts, ArrivalUseCase arrivals) {
        this.gateAlerts = gateAlerts;
        this.arrivals = arrivals;
    }

    @Scheduled(fixedDelayString = "${famcare.gate.check-every:5s}")
    void tick() {
        gateAlerts.processRingingAlerts();
        arrivals.sendDueReminders();
    }
}
