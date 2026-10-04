package com.codewitheli.famcare.domain.model;

import org.junit.jupiter.api.Test;

import java.time.Duration;
import java.time.Instant;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class GateAlertTest {

    private static final Instant T0 = Instant.parse("2026-10-05T10:00:00Z");
    private final UUID family = UUID.randomUUID();
    private final UUID sender = UUID.randomUUID();
    private final UUID papa = UUID.randomUUID();

    @Test
    void newAlertRingsOnce() {
        var alert = GateAlert.ring(family, sender, T0);

        assertThat(alert.status()).isEqualTo(GateAlertStatus.RINGING);
        assertThat(alert.ringCount()).isEqualTo(1);
    }

    @Test
    void familyMemberCanAcknowledge() {
        var alert = GateAlert.ring(family, sender, T0);

        alert.acknowledge(papa, T0.plusSeconds(10));

        assertThat(alert.status()).isEqualTo(GateAlertStatus.ACKNOWLEDGED);
        assertThat(alert.acknowledgedBy()).isEqualTo(papa);
        assertThat(alert.resolvedAt()).isEqualTo(T0.plusSeconds(10));
    }

    @Test
    void senderCannotAcknowledgeTheirOwnAlert() {
        var alert = GateAlert.ring(family, sender, T0);

        assertThatThrownBy(() -> alert.acknowledge(sender, T0)).isInstanceOf(IllegalStateException.class);
    }

    @Test
    void onlyTheSenderCanCancel() {
        var alert = GateAlert.ring(family, sender, T0);

        assertThatThrownBy(() -> alert.cancel(papa, T0)).isInstanceOf(IllegalStateException.class);
        alert.cancel(sender, T0);
        assertThat(alert.status()).isEqualTo(GateAlertStatus.CANCELLED);
    }

    @Test
    void answeredAlertCannotBeAnsweredAgain() {
        var alert = GateAlert.ring(family, sender, T0);
        alert.acknowledge(papa, T0);

        assertThatThrownBy(() -> alert.acknowledge(UUID.randomUUID(), T0))
                .isInstanceOf(IllegalStateException.class)
                .hasMessageContaining("acknowledged");
    }

    @Test
    void isDueForAnotherRingOnlyAfterTheInterval() {
        var alert = GateAlert.ring(family, sender, T0);
        var interval = Duration.ofSeconds(30);

        assertThat(alert.isDueForRing(T0.plusSeconds(29), interval)).isFalse();
        assertThat(alert.isDueForRing(T0.plusSeconds(30), interval)).isTrue();

        alert.ringAgain(T0.plusSeconds(30));
        assertThat(alert.ringCount()).isEqualTo(2);
        assertThat(alert.isDueForRing(T0.plusSeconds(45), interval)).isFalse();
    }
}
