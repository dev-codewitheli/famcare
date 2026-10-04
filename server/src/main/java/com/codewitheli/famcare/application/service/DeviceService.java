package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.RegisterDeviceUseCase;
import com.codewitheli.famcare.application.port.out.DeviceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class DeviceService implements RegisterDeviceUseCase {

    private final DeviceRepository devices;
    private final MemberLookup memberLookup;

    DeviceService(DeviceRepository devices, MemberLookup memberLookup) {
        this.devices = devices;
        this.memberLookup = memberLookup;
    }

    @Override
    public void registerDevice(AuthenticatedUser user, String pushToken) {
        devices.upsert(memberLookup.require(user).id(), pushToken);
    }
}
