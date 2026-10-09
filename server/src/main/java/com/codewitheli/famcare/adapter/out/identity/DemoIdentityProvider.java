package com.codewitheli.famcare.adapter.out.identity;

import com.codewitheli.famcare.application.port.out.IdentityProvider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** Demo mode has no real sign-in accounts to delete. */
@Component
@Profile("!firebase")
class DemoIdentityProvider implements IdentityProvider {

    private static final Logger log = LoggerFactory.getLogger(DemoIdentityProvider.class);

    @Override
    public void deleteUser(String uid) {
        log.info("[identity] would delete sign-in account {}", uid);
    }
}
