package com.codewitheli.famcare.application;

import com.codewitheli.famcare.domain.model.ArrivalNotice;
import com.codewitheli.famcare.domain.model.Member;

public record ArrivalView(ArrivalNotice notice, Member member) {
}
