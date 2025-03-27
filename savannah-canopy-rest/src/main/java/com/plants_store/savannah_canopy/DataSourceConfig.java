package com.plants_store.savannah_canopy;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.services.secretsmanager.SecretsManagerClient;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueRequest;
import software.amazon.awssdk.services.secretsmanager.model.GetSecretValueResponse;
import com.fasterxml.jackson.databind.ObjectMapper;
import javax.sql.DataSource;
import com.zaxxer.hikari.HikariConfig;
import com.zaxxer.hikari.HikariDataSource;
import java.io.IOException;
import java.util.Map;

@Configuration
public class DataSourceConfig {

    @Value("${spring.datasource.url}")
    private String dbUrl;

    @Value("${aws.secretsmanager.secret-name:db_credentials}") //default to db_credentials
    private String secretName;

    @Bean
    public DataSource dataSource(SecretsManagerClient secretsManagerClient) throws IOException {
        GetSecretValueRequest request = GetSecretValueRequest.builder()
                .secretId(secretName)
                .build();

        GetSecretValueResponse response = secretsManagerClient.getSecretValue(request);
        String secretString = response.secretString();

        ObjectMapper objectMapper = new ObjectMapper();
        Map<String, String> secrets = objectMapper.readValue(secretString, Map.class);

        String username = secrets.get("username");
        String password = secrets.get("password");

        HikariConfig config = new HikariConfig();
        config.setJdbcUrl(dbUrl);
        config.setUsername(username);
        config.setPassword(password);
        config.setDriverClassName("org.postgresql.Driver");
        config.setMaximumPoolSize(10);
        config.setMinimumIdle(5);

        return new HikariDataSource(config);
    }

    @Bean
    public SecretsManagerClient secretsManagerClient() {
        return SecretsManagerClient.create();
    }
}