package com.codewitheli.famcare.application;

import com.codewitheli.famcare.domain.model.ArrivalNotice;
import com.codewitheli.famcare.domain.model.Member;

import java.util.List;

/**
 * @param seenBy   members who tapped "Got it", in order
 * @param notified who the heads-up was sent to; only filled in right after announcing
 */
public record ArrivalView(ArrivalNotice notice, Member member, List<Member> seenBy, List<Member> notified) {
}
