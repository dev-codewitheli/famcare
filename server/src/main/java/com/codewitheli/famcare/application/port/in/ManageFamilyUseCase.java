package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.FamilyView;

import java.util.UUID;

public interface ManageFamilyUseCase {

    /** Creates a family with the caller as its first (PARENT) member. */
    FamilyView createFamily(AuthenticatedUser user, String familyName, String displayName);

    FamilyView joinFamily(AuthenticatedUser user, String inviteCode, String displayName);

    FamilyView myFamily(AuthenticatedUser user);

    /** Anyone can change what the family calls them. */
    FamilyView renameMe(AuthenticatedUser user, String displayName);

    /** Family creator only. */
    FamilyView renameFamily(AuthenticatedUser user, String familyName);

    /**
     * Family creator only, and not themselves. The member stops getting rings and their app
     * returns to the join screen; their past gate activity keeps their nickname.
     */
    FamilyView removeMember(AuthenticatedUser user, UUID memberId);

    /**
     * Leave the family. If the caller set it up, the longest-standing remaining member becomes
     * its creator. Past gate activity keeps their nickname.
     */
    void leave(AuthenticatedUser user);

    /** Family creator only: a new invite code, e.g. if the old one was shared too widely. */
    FamilyView resetInviteCode(AuthenticatedUser user);
}
