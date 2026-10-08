package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.ArrivalView;
import com.codewitheli.famcare.application.AuthenticatedUser;

import java.util.List;
import java.util.UUID;

public interface ArrivalUseCase {

    /** "On my way, about N minutes": a gentle (non-alarm) notification to everyone else. */
    ArrivalView announce(AuthenticatedUser user, int etaMinutes);

    /** Who's on their way right now, soonest first. */
    List<ArrivalView> active(AuthenticatedUser user);

    /** "Got it": the sender is told who has seen their heads-up. */
    ArrivalView markSeen(AuthenticatedUser user, UUID noticeId);

    /** Sends "Time's up — are you at the gate?" to senders whose expected time has come. Runs on a schedule. */
    void sendDueReminders();
}
