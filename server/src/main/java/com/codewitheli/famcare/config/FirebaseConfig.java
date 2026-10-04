package com.codewitheli.famcare.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Profile;

import java.io.FileInputStream;
import java.io.IOException;

/**
 * Connects to the Firebase project with a service-account key. The key file is a secret:
 * keep it out of git and point {@code FIREBASE_CREDENTIALS_FILE} at it (or rely on
 * {@code GOOGLE_APPLICATION_CREDENTIALS}).
 */
@Configuration
@Profile("firebase")
class FirebaseConfig {

    @Bean
    FirebaseApp firebaseApp(@Value("${famcare.firebase.credentials-file:}") String credentialsFile)
            throws IOException {
        GoogleCredentials credentials;
        if (credentialsFile.isBlank()) {
            credentials = GoogleCredentials.getApplicationDefault();
        } else {
            try (var in = new FileInputStream(credentialsFile)) {
                credentials = GoogleCredentials.fromStream(in);
            }
        }
        var options = FirebaseOptions.builder().setCredentials(credentials).build();
        return FirebaseApp.getApps().isEmpty() ? FirebaseApp.initializeApp(options) : FirebaseApp.getInstance();
    }
}
