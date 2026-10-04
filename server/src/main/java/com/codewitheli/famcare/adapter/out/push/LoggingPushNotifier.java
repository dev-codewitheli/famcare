package com.codewitheli.famcare.adapter.out.push;

import com.codewitheli.famcare.application.port.out.PushMessage;
import com.codewitheli.famcare.application.port.out.PushNotifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

/** Demo mode: logs pushes instead of sending them, so the server runs without Firebase. */
@Component
@Profile("!firebase")
class LoggingPushNotifier implements PushNotifier {

    private static final Logger log = LoggerFactory.getLogger(LoggingPushNotifier.class);

    @Override
    public Set<String> send(List<String> pushTokens, PushMessage message) {
        log.info("[push] {} -> {} device(s): {}", message.type(), pushTokens.size(), message.data());
        return Set.of();
    }
}
