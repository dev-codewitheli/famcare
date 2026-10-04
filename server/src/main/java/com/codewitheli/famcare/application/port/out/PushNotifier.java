package com.codewitheli.famcare.application.port.out;

import java.util.List;
import java.util.Set;

public interface PushNotifier {

    /**
     * Sends with high priority so it wakes phones in Doze.
     *
     * @return tokens the push service reported as no longer valid, to be pruned
     */
    Set<String> send(List<String> pushTokens, PushMessage message);
}
