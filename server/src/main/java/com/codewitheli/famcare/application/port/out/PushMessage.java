package com.codewitheli.famcare.application.port.out;

import java.time.Duration;
import java.util.Map;

/**
 * A data-only push. The apps decide how to present it (e.g., a full-screen alarm for
 * {@code GATE_RING}), which is why there's no notification title/body here.
 *
 * @param data       always includes {@code type}
 * @param timeToLive drop the message if it can't be delivered in time — a stale ring is useless
 */
public record PushMessage(String type, Map<String, String> data, Duration timeToLive) {

    public static final String GATE_RING = "GATE_RING";
    public static final String GATE_ACKNOWLEDGED = "GATE_ACKNOWLEDGED";
    public static final String GATE_CANCELLED = "GATE_CANCELLED";
    public static final String GATE_EXPIRED = "GATE_EXPIRED";
    /** "On my way, about N minutes": a normal notification, not an alarm. */
    public static final String ARRIVAL_HEADS_UP = "ARRIVAL_HEADS_UP";
    /** To the sender: a family member tapped "Got it" on their heads-up. */
    public static final String ARRIVAL_SEEN = "ARRIVAL_SEEN";
    /** To the sender: "Time's up — are you at the gate?" */
    public static final String ARRIVAL_DUE = "ARRIVAL_DUE";
    /** To the rest of the family: the sender cancelled their heads-up. */
    public static final String ARRIVAL_CANCELLED = "ARRIVAL_CANCELLED";
    /** To someone removed from the family, so their app goes back to the join screen. */
    public static final String MEMBER_REMOVED = "MEMBER_REMOVED";
}
