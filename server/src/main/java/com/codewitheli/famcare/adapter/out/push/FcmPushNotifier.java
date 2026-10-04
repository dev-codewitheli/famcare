package com.codewitheli.famcare.adapter.out.push;

import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.application.port.out.PushNotifier;
import com.google.firebase.FirebaseApp;
import com.google.firebase.messaging.AndroidConfig;
import com.google.firebase.messaging.FirebaseMessaging;
import com.google.firebase.messaging.FirebaseMessagingException;
import com.google.firebase.messaging.MessagingErrorCode;
import com.google.firebase.messaging.MulticastMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Sends data-only, high-priority FCM messages. Data-only means the app's background handler
 * always runs and decides the presentation (full-screen alarm, silent dismiss, …) — a
 * "notification" message would be shown by the system instead, without our alarm behavior.
 */
@Component
@Profile("firebase")
class FcmPushNotifier implements PushNotifier {

    private static final Logger log = LoggerFactory.getLogger(FcmPushNotifier.class);
    private static final int MAX_TOKENS_PER_REQUEST = 500;
    private static final Set<MessagingErrorCode> STALE_TOKEN_ERRORS =
            Set.of(MessagingErrorCode.UNREGISTERED, MessagingErrorCode.INVALID_ARGUMENT,
                    MessagingErrorCode.SENDER_ID_MISMATCH);

    private final FirebaseMessaging messaging;

    FcmPushNotifier(FirebaseApp app) {
        this.messaging = FirebaseMessaging.getInstance(app);
    }

    @Override
    public Set<String> send(List<String> pushTokens, PushMessage message) {
        var invalid = new HashSet<String>();
        var android = AndroidConfig.builder()
                .setPriority(AndroidConfig.Priority.HIGH)
                .setTtl(message.timeToLive().toMillis())
                .build();
        for (int from = 0; from < pushTokens.size(); from += MAX_TOKENS_PER_REQUEST) {
            var batch = pushTokens.subList(from, Math.min(from + MAX_TOKENS_PER_REQUEST, pushTokens.size()));
            var multicast = MulticastMessage.builder()
                    .addAllTokens(batch)
                    .putAllData(message.data())
                    .setAndroidConfig(android)
                    .build();
            try {
                var responses = messaging.sendEachForMulticast(multicast).getResponses();
                for (int i = 0; i < responses.size(); i++) {
                    var error = responses.get(i).getException();
                    if (error != null && STALE_TOKEN_ERRORS.contains(error.getMessagingErrorCode())) {
                        invalid.add(batch.get(i));
                    } else if (error != null) {
                        log.warn("FCM delivery failed ({}): {}", message.type(), error.getMessage());
                    }
                }
            } catch (FirebaseMessagingException e) {
                log.error("FCM request failed ({})", message.type(), e);
            }
        }
        return invalid;
    }
}
