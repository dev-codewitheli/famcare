package com.codewitheli.famcare.adapter.in.web;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.AccountUseCase;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/account")
class AccountController {

    private final AccountUseCase accounts;

    AccountController(AccountUseCase accounts) {
        this.accounts = accounts;
    }

    /** "Delete my account": in-app account deletion, as Google Play requires. */
    @DeleteMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void delete(@AuthenticationPrincipal AuthenticatedUser user) {
        accounts.deleteAccount(user);
    }
}
