package com.codewitheli.famcare.adapter.in.web;

import com.codewitheli.famcare.application.NotFoundException;
import com.codewitheli.famcare.application.NotInFamilyException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ProblemDetail;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

/** RFC 9457 problem details. {@code code} gives the apps a stable value to branch on. */
@RestControllerAdvice
class ApiExceptionHandler extends ResponseEntityExceptionHandler {

    @ExceptionHandler(NotFoundException.class)
    ProblemDetail notFound(NotFoundException e) {
        return problem(HttpStatus.NOT_FOUND, "NOT_FOUND", e.getMessage());
    }

    @ExceptionHandler(NotInFamilyException.class)
    ProblemDetail notInFamily(NotInFamilyException e) {
        return problem(HttpStatus.CONFLICT, "NOT_IN_FAMILY", e.getMessage());
    }

    /** Invalid values a domain object refuses, e.g. an out-of-range ETA. */
    @ExceptionHandler(IllegalArgumentException.class)
    ProblemDetail badRequest(IllegalArgumentException e) {
        return problem(HttpStatus.BAD_REQUEST, "BAD_REQUEST", e.getMessage());
    }

    /** Domain rule violations, e.g. acknowledging an alert that was already answered. */
    @ExceptionHandler(IllegalStateException.class)
    ProblemDetail conflict(IllegalStateException e) {
        return problem(HttpStatus.CONFLICT, "CONFLICT", e.getMessage());
    }

    private static ProblemDetail problem(HttpStatus status, String code, String detail) {
        var problem = ProblemDetail.forStatusAndDetail(status, detail);
        problem.setProperty("code", code);
        return problem;
    }
}
