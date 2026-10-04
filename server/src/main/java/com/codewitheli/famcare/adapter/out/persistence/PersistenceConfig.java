package com.codewitheli.famcare.adapter.out.persistence;

import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/** Each adapter keeps its Spring Data interface nested and private to this package. */
@Configuration
@EnableJpaRepositories(considerNestedRepositories = true)
class PersistenceConfig {
}
