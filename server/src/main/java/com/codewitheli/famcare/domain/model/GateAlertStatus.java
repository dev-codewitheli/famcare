package com.codewitheli.famcare.domain.model;

public enum GateAlertStatus {
    /** Someone is at the gate and the family's phones are ringing. */
    RINGING,
    /** A family member tapped "Coming!". */
    ACKNOWLEDGED,
    /** The person at the gate cancelled (e.g., they got in another way). */
    CANCELLED,
    /** Nobody answered after the maximum number of rings. */
    EXPIRED
}
