package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.ArrivalView;
import com.codewitheli.famcare.application.AuthenticatedUser;

import java.util.List;

public interface ArrivalUseCase {

    /** "On my way, about N minutes": a gentle (non-alarm) notification to everyone else. */
    ArrivalView announce(AuthenticatedUser user, int etaMinutes);

    /** Who's on their way right now, soonest first. */
    List<ArrivalView> active(AuthenticatedUser user);
}
