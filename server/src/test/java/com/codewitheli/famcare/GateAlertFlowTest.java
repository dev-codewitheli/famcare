package com.codewitheli.famcare;

import com.codewitheli.famcare.application.port.in.GateAlertUseCase;
import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.application.port.out.PushNotifier;
import com.jayway.jsonpath.JsonPath;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Primary;
import org.springframework.http.MediaType;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.web.servlet.assertj.MockMvcTester;
import org.springframework.test.web.servlet.assertj.MvcTestResult;

import java.io.UnsupportedEncodingException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * End-to-end through HTTP, security (demo tokens), JPA/Flyway on H2, and the scheduler logic.
 * Pushes are captured instead of logged so we can assert who would have been rung.
 */
@SpringBootTest(properties = "famcare.gate.check-every=1h")
@AutoConfigureMockMvc
@Import(GateAlertFlowTest.TestBeans.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
class GateAlertFlowTest {

    @Autowired
    MockMvcTester mvc;
    @Autowired
    RecordingPushNotifier pushes;
    @Autowired
    MutableClock clock;
    @Autowired
    GateAlertUseCase gateAlerts;

    @BeforeEach
    void setUpFamily() {
        var created = mvc.post().uri("/api/families").header("Authorization", "Bearer ate")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"familyName": "Centeno", "displayName": "Ate"}""")
                .exchange();
        assertThat(created).hasStatus(201);
        String inviteCode = JsonPath.read(body(created), "$.inviteCode");

        joinAs("papa", "Papa", inviteCode);
        joinAs("mama", "Mama", inviteCode);
        registerDevice("ate", "token-ate");
        registerDevice("papa", "token-papa");
        registerDevice("mama", "token-mama");
    }

    @Test
    void requestsWithoutATokenAreRejected() {
        assertThat(mvc.get().uri("/api/families/mine")).hasStatus(401);
    }

    @Test
    void livenessIsPublicForPlatformHealthChecks() {
        assertThat(mvc.get().uri("/actuator/health/liveness")).hasStatusOk()
                .bodyJson().extractingPath("$.status").isEqualTo("UP");
    }

    @Test
    void signedInUserWithoutAFamilyIsToldToJoinOne() {
        assertThat(mvc.get().uri("/api/families/mine").header("Authorization", "Bearer stranger"))
                .hasStatus(409)
                .bodyJson().extractingPath("$.code").isEqualTo("NOT_IN_FAMILY");
    }

    @Test
    void familyListsMembersWithoutExposingAuthIds() {
        assertThat(mvc.get().uri("/api/families/mine").header("Authorization", "Bearer papa"))
                .hasStatusOk()
                .bodyJson()
                .satisfies(json -> assertThat(json.getJson()).doesNotContain("authUid"))
                .extractingPath("$.members[*].displayName").asArray().containsExactly("Ate", "Papa", "Mama");
    }

    @Test
    void ringingAtTheGateAlertsEveryoneElseAndComingNotifiesTheSender() {
        var alertId = ring("ate");

        var ring = pushes.last();
        assertThat(ring.message().type()).isEqualTo(PushMessage.GATE_RING);
        assertThat(ring.message().data()).containsEntry("senderName", "Ate").containsKeys("alertId", "senderId");
        assertThat(ring.tokens()).containsExactlyInAnyOrder("token-papa", "token-mama");

        assertThat(mvc.post().uri("/api/gate-alerts/{id}/acknowledge", alertId).header("Authorization", "Bearer papa"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.acknowledgedBy.displayName").isEqualTo("Papa");

        var coming = pushes.last();
        assertThat(coming.message().type()).isEqualTo(PushMessage.GATE_ACKNOWLEDGED);
        assertThat(coming.message().data()).containsEntry("acknowledgedByName", "Papa");
        assertThat(coming.tokens()).containsExactlyInAnyOrder("token-ate", "token-mama");

        assertThat(mvc.get().uri("/api/gate-alerts/active").header("Authorization", "Bearer mama")).hasStatus(204);
        assertThat(mvc.get().uri("/api/gate-alerts/{id}", alertId).header("Authorization", "Bearer ate"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.status").isEqualTo("ACKNOWLEDGED");
    }

    @Test
    void tappingTwiceDoesNotRingTwice() {
        var first = ring("ate");
        var second = ring("ate");

        assertThat(second).isEqualTo(first);
        assertThat(pushes.sent).hasSize(1);
    }

    @Test
    void unansweredAlertRingsAgainThenExpires() {
        ring("ate");

        clock.advance(Duration.ofSeconds(29));
        gateAlerts.processRingingAlerts();
        assertThat(pushes.sent).hasSize(1);                      // not due yet

        for (int ring = 2; ring <= 4; ring++) {
            clock.advance(Duration.ofSeconds(30));
            gateAlerts.processRingingAlerts();
            assertThat(pushes.last().message().data()).containsEntry("ringCount", String.valueOf(ring));
        }

        clock.advance(Duration.ofSeconds(30));
        gateAlerts.processRingingAlerts();
        var expired = pushes.last();
        assertThat(expired.message().type()).isEqualTo(PushMessage.GATE_EXPIRED);
        assertThat(expired.tokens()).contains("token-ate");       // "nobody answered — try calling"
    }

    @Test
    void onlyTheSenderCanCancel() {
        var alertId = ring("ate");

        assertThat(mvc.post().uri("/api/gate-alerts/{id}/cancel", alertId).header("Authorization", "Bearer papa"))
                .hasStatus(409);
        assertThat(mvc.post().uri("/api/gate-alerts/{id}/cancel", alertId).header("Authorization", "Bearer ate"))
                .hasStatusOk()
                .bodyJson().extractingPath("$.status").isEqualTo("CANCELLED");
    }

    @Test
    void otherFamiliesCannotSeeOrAnswerTheAlert() {
        var alertId = ring("ate");
        mvc.post().uri("/api/families").header("Authorization", "Bearer neighbor")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                        {"familyName": "Neighbors", "displayName": "Kuya"}""")
                .exchange();

        assertThat(mvc.post().uri("/api/gate-alerts/{id}/acknowledge", alertId)
                .header("Authorization", "Bearer neighbor")).hasStatus(404);
    }

    @Test
    void onMyWayHeadsUpNotifiesOthersAndClearsWhenTheyRing() {
        assertThat(mvc.post().uri("/api/arrivals").header("Authorization", "Bearer ate")
                .contentType(MediaType.APPLICATION_JSON).content("{\"etaMinutes\": 10}"))
                .hasStatus(201);

        var headsUp = pushes.last();
        assertThat(headsUp.message().type()).isEqualTo(PushMessage.ARRIVAL_HEADS_UP);
        assertThat(headsUp.message().data()).containsEntry("senderName", "Ate").containsEntry("etaMinutes", "10");
        assertThat(headsUp.tokens()).containsExactlyInAnyOrder("token-papa", "token-mama");

        assertThat(mvc.get().uri("/api/arrivals/active").header("Authorization", "Bearer papa"))
                .hasStatusOk()
                .bodyJson().extractingPath("$[*].member.displayName").asArray().containsExactly("Ate");

        ring("ate");
        assertThat(mvc.get().uri("/api/arrivals/active").header("Authorization", "Bearer papa"))
                .hasStatusOk()
                .bodyJson().extractingPath("$").asArray().isEmpty();
    }

    @Test
    void onMyWayExpiresTenMinutesAfterTheExpectedArrival() {
        mvc.post().uri("/api/arrivals").header("Authorization", "Bearer ate")
                .contentType(MediaType.APPLICATION_JSON).content("{\"etaMinutes\": 5}").exchange();

        clock.advance(Duration.ofMinutes(14));
        assertThat(mvc.get().uri("/api/arrivals/active").header("Authorization", "Bearer papa"))
                .bodyJson().extractingPath("$").asArray().hasSize(1);

        clock.advance(Duration.ofMinutes(2));
        assertThat(mvc.get().uri("/api/arrivals/active").header("Authorization", "Bearer papa"))
                .bodyJson().extractingPath("$").asArray().isEmpty();
    }

    @Test
    void onMyWayRejectsUnrealisticEtas() {
        assertThat(mvc.post().uri("/api/arrivals").header("Authorization", "Bearer ate")
                .contentType(MediaType.APPLICATION_JSON).content("{\"etaMinutes\": 0}"))
                .hasStatus(400);
        assertThat(mvc.post().uri("/api/arrivals").header("Authorization", "Bearer ate")
                .contentType(MediaType.APPLICATION_JSON).content("{\"etaMinutes\": 61}"))
                .hasStatus(400);
    }

    @Test
    void recentActivityListsTheFamilysAlertsNewestFirst() {
        var first = ring("ate");
        mvc.post().uri("/api/gate-alerts/{id}/acknowledge", first).header("Authorization", "Bearer papa").exchange();
        clock.advance(Duration.ofMinutes(1));
        var second = ring("mama");

        assertThat(mvc.get().uri("/api/gate-alerts/recent").header("Authorization", "Bearer papa"))
                .hasStatusOk()
                .bodyJson()
                .satisfies(json -> assertThat(json).extractingPath("$[*].id").asArray().containsExactly(second, first))
                .extractingPath("$[1].acknowledgedBy.displayName").isEqualTo("Papa");
    }

    private String ring(String user) {
        var result = mvc.post().uri("/api/gate-alerts").header("Authorization", "Bearer " + user).exchange();
        assertThat(result).hasStatusOk();
        return JsonPath.read(body(result), "$.id");
    }

    private static String body(MvcTestResult result) {
        try {
            return result.getResponse().getContentAsString();
        } catch (UnsupportedEncodingException e) {
            throw new IllegalStateException(e);
        }
    }

    private void joinAs(String user, String name, String inviteCode) {
        assertThat(mvc.post().uri("/api/families/join").header("Authorization", "Bearer " + user)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"inviteCode\": \"%s\", \"displayName\": \"%s\"}".formatted(inviteCode, name)))
                .hasStatusOk();
    }

    private void registerDevice(String user, String token) {
        assertThat(mvc.put().uri("/api/devices").header("Authorization", "Bearer " + user)
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"pushToken\": \"%s\"}".formatted(token)))
                .hasStatus(204);
    }

    record SentPush(List<String> tokens, PushMessage message) {
    }

    static class RecordingPushNotifier implements PushNotifier {
        final List<SentPush> sent = new ArrayList<>();

        @Override
        public Set<String> send(List<String> pushTokens, PushMessage message) {
            sent.add(new SentPush(List.copyOf(pushTokens), message));
            return Set.of();
        }

        SentPush last() {
            return sent.getLast();
        }
    }

    static class MutableClock extends Clock {
        private Instant now = Instant.parse("2026-10-05T10:00:00Z");

        void advance(Duration duration) {
            now = now.plus(duration);
        }

        @Override
        public Instant instant() {
            return now;
        }

        @Override
        public ZoneOffset getZone() {
            return ZoneOffset.UTC;
        }

        @Override
        public Clock withZone(java.time.ZoneId zone) {
            return this;
        }
    }

    @TestConfiguration
    static class TestBeans {
        @Bean
        @Primary
        RecordingPushNotifier recordingPushNotifier() {
            return new RecordingPushNotifier();
        }

        @Bean
        @Primary
        MutableClock mutableClock() {
            return new MutableClock();
        }
    }
}
