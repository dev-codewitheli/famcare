package com.codewitheli.famcare.adapter.in.web.dto;

import com.codewitheli.famcare.domain.model.Member;
import com.codewitheli.famcare.domain.model.MemberRole;

import java.util.UUID;

/** What other family members may see about a person — the auth UID stays server-side. */
public record MemberResponse(UUID id, String displayName, MemberRole role, String avatar) {

    public static MemberResponse from(Member member) {
        return member == null ? null
                : new MemberResponse(member.id(), member.displayName(), member.role(), member.avatar());
    }
}
