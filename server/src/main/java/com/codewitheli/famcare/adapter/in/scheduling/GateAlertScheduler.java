package com.codewitheli.famcare.adapter.in.scheduling;

import com.codewitheli.famcare.application.port.in.GateAlertUseCase;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/** Checks every few seconds for gate alerts that need another ring or should expire. */
@Component
class GateAlertScheduler {

    private final GateAlertUseCase gateAlerts;

    GateAlertScheduler(GateAlertUseCase gateAlerts) {
        this.gateAlerts = gateAlerts;
    }

    @Scheduled(fixedDelayString = "${famcare.gate.check-every:5s}")
    void processRingingAlerts() {
        gateAlerts.processRingingAlerts();
    }
}
