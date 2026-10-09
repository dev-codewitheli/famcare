package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.AuthenticatedUser;

public interface AccountUseCase {

    /**
     * Deletes everything about the caller: leaves their family (handing it over if they set it
     * up), forgets their phones and heads-ups, replaces their nickname in past activity with
     * "Former member", and deletes their sign-in account.
     */
    void deleteAccount(AuthenticatedUser user);
}
