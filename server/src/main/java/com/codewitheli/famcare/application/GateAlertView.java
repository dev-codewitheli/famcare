package com.codewitheli.famcare.application;

import com.codewitheli.famcare.domain.model.GateAlert;
import com.codewitheli.famcare.domain.model.Member;

/** A gate alert with the names the apps display. {@code acknowledgedBy} is null until answered. */
public record GateAlertView(GateAlert alert, Member sender, Member acknowledgedBy) {
}
