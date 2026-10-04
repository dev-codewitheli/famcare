package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.FamilyView;

public interface ManageFamilyUseCase {

    /** Creates a family with the caller as its first (PARENT) member. */
    FamilyView createFamily(AuthenticatedUser user, String familyName, String displayName);

    FamilyView joinFamily(AuthenticatedUser user, String inviteCode, String displayName);

    FamilyView myFamily(AuthenticatedUser user);
}
