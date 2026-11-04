package career.vault.accounts;

import tools.jackson.core.type.TypeReference;
import tools.jackson.core.JacksonException;
import tools.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.GeneralSecurityException;
import java.time.Instant;
import java.util.Base64;
import java.util.Map;

@Service
public class AuthTokenService {
    private static final long TOKEN_LIFETIME_SECONDS = 12 * 60 * 60;
    private final byte[] signingKey;
    private final ObjectMapper objectMapper;

    public AuthTokenService(
            @Value("${careervault.auth.jwt-secret}") String secret,
            ObjectMapper objectMapper) {
        if (secret.length() < 32) {
            throw new IllegalStateException("CAREERVAULT_JWT_SECRET must contain at least 32 characters.");
        }
        signingKey = secret.getBytes(StandardCharsets.UTF_8);
        this.objectMapper = objectMapper;
    }

    public String issue(UserAccount user) {
        try {
            String header = encode(objectMapper.writeValueAsBytes(Map.of("alg", "HS256", "typ", "JWT")));
            String payload = encode(objectMapper.writeValueAsBytes(Map.of(
                    "sub", user.getId(),
                    "ver", user.getTokenVersion(),
                    "iat", Instant.now().getEpochSecond(),
                    "exp", Instant.now().plusSeconds(TOKEN_LIFETIME_SECONDS).getEpochSecond())));
            String input = header + "." + payload;
            return input + "." + encode(sign(input));
        } catch (Exception exception) {
            throw new IllegalStateException("Could not create an authentication token.", exception);
        }
    }

    public AuthenticatedUser authenticate(String token, UserAccountRepository users) {
        try {
            String[] parts = token.split("\\.", -1);
            if (parts.length != 3) return null;
            String input = parts[0] + "." + parts[1];
            byte[] expected = sign(input);
            byte[] supplied = Base64.getUrlDecoder().decode(parts[2]);
            if (!MessageDigest.isEqual(expected, supplied)) return null;
            Map<String, Object> claims = objectMapper.readValue(
                    Base64.getUrlDecoder().decode(parts[1]),
                    new TypeReference<>() { });
            if (!(claims.get("sub") instanceof String userId)
                    || !(claims.get("exp") instanceof Number expiration)
                    || !(claims.get("ver") instanceof Number version)
                    || expiration.longValue() <= Instant.now().getEpochSecond()) return null;
            UserAccount user = users.findById(userId).orElse(null);
            if (user == null || !user.isActive()
                    || user.getTokenVersion() != version.intValue()) return null;
            return new AuthenticatedUser(user.getId(), user.getEmail(), user.getRole());
        } catch (IllegalArgumentException | JacksonException | GeneralSecurityException exception) {
            return null;
        }
    }

    private byte[] sign(String value) throws GeneralSecurityException {
        Mac mac = Mac.getInstance("HmacSHA256");
        mac.init(new SecretKeySpec(signingKey, "HmacSHA256"));
        return mac.doFinal(value.getBytes(StandardCharsets.US_ASCII));
    }

    private String encode(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }
}
