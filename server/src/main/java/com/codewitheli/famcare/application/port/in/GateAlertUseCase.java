package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.GateAlertView;

import java.util.Optional;
import java.util.UUID;

public interface GateAlertUseCase {

    /** "I'm at the gate" — rings everyone else. Returns the existing alert if one is already ringing. */
    GateAlertView ring(AuthenticatedUser user);

    /** "Coming!" */
    GateAlertView acknowledge(AuthenticatedUser user, UUID alertId);

    GateAlertView cancel(AuthenticatedUser user, UUID alertId);

    Optional<GateAlertView> active(AuthenticatedUser user);

    /** Lets the sender see how their alert ended (who's coming, or that nobody answered). */
    GateAlertView get(AuthenticatedUser user, UUID alertId);

    /** Re-rings unanswered alerts and expires the ones that rang too many times. Runs on a schedule. */
    void processRingingAlerts();
}
