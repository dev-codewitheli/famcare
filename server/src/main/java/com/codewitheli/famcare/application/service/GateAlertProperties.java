package com.codewitheli.famcare.application.service;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

import java.time.Duration;

/**
 * @param ringInterval how long to wait for a "Coming!" before ringing again
 * @param maxRings     total rings (including the first) before the alert expires
 * @param pushTtl      drop undelivered ring pushes after this long
 */
@ConfigurationProperties("famcare.gate")
public record GateAlertProperties(
        @DefaultValue("30s") Duration ringInterval,
        @DefaultValue("4") int maxRings,
        @DefaultValue("2m") Duration pushTtl) {
}
