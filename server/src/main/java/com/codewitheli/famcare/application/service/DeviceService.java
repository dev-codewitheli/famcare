package com.codewitheli.famcare.application.service;

import com.codewitheli.famcare.application.AuthenticatedUser;
import com.codewitheli.famcare.application.port.in.RegisterDeviceUseCase;
import com.codewitheli.famcare.application.port.out.DeviceRepository;
import com.codewitheli.famcare.application.port.out.MemberRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class DeviceService implements RegisterDeviceUseCase {

    private final DeviceRepository devices;
    private final MemberRepository members;
    private final MemberLookup memberLookup;

    DeviceService(DeviceRepository devices, MemberRepository members, MemberLookup memberLookup) {
        this.devices = devices;
        this.members = members;
        this.memberLookup = memberLookup;
    }

    @Override
    public void registerDevice(AuthenticatedUser user, String pushToken) {
        devices.upsert(memberLookup.require(user).id(), pushToken);
    }

    /** Only the caller's own registration; quietly does nothing for someone else's token. */
    @Override
    public void unregisterDevice(AuthenticatedUser user, String pushToken) {
        members.findByAuthUid(user.uid()).ifPresent(me -> devices.deleteToken(me.id(), pushToken));
    }
}
