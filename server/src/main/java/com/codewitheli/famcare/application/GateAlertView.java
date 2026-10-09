package com.codewitheli.famcare.application;

import com.codewitheli.famcare.domain.model.GateAlert;
import com.codewitheli.famcare.domain.model.Member;

import java.util.List;

/**
 * A gate alert with the names the apps display. {@code acknowledgedBy} is null until answered;
 * {@code recipients} is empty for alerts from before recipients could be picked (they rang everyone).
 */
public record GateAlertView(GateAlert alert, Member sender, Member acknowledgedBy, List<Member> recipients) {
}
