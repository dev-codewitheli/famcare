package com.codewitheli.famcare.adapter.in.web.dto;

import com.codewitheli.famcare.application.FamilyView;

import java.util.List;
import java.util.UUID;

public record FamilyResponse(UUID id, String name, String inviteCode, MemberResponse me,
                             List<MemberResponse> members) {

    public static FamilyResponse from(FamilyView view) {
        return new FamilyResponse(view.family().id(), view.family().name(), view.family().inviteCode(),
                MemberResponse.from(view.me()), view.members().stream().map(MemberResponse::from).toList());
    }
}
