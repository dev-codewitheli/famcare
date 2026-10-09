package com.codewitheli.famcare.application.port.in;

import com.codewitheli.famcare.application.AuthenticatedUser;

public interface RegisterDeviceUseCase {

    /** Stores (or moves) an FCM registration token so the caller's phone receives pushes. */
    void registerDevice(AuthenticatedUser user, String pushToken);

    /** On sign-out: this phone stops getting the caller's family pushes. */
    void unregisterDevice(AuthenticatedUser user, String pushToken);
}
