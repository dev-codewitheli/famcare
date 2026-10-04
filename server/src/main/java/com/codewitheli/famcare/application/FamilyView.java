package com.codewitheli.famcare.application;

import com.codewitheli.famcare.domain.model.Family;
import com.codewitheli.famcare.domain.model.Member;

import java.util.List;

/** The caller's family, as the apps see it. */
public record FamilyView(Family family, Member me, List<Member> members) {
}
