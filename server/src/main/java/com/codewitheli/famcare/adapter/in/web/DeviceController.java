package com.codewitheli.famcare.adapter.in.web;

import com.codewitheli.famcare.adapter.in.web.dto.RegisterDeviceRequest;
import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.RegisterDeviceUseCase;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/devices")
class DeviceController {

    private final RegisterDeviceUseCase devices;

    DeviceController(RegisterDeviceUseCase devices) {
        this.devices = devices;
    }

    /** Idempotent: apps call it on every start and whenever FCM rotates the token. */
    @PutMapping
    @ResponseStatus(HttpStatus.NO_CONTENT)
    void register(@AuthenticationPrincipal AuthenticatedUser user,
                  @Valid @RequestBody RegisterDeviceRequest request) {
        devices.registerDevice(user, request.pushToken());
    }
}
