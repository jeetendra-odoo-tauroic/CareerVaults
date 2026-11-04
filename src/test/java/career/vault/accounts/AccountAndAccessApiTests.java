package career.vault.accounts;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.TestPropertySource;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:account-access-test;DB_CLOSE_DELAY=-1",
        "careervault.auth.bootstrap-admin-email=phase9-admin@example.test",
        "careervault.auth.bootstrap-admin-password=phase9-secure-admin-password"
})
class AccountAndAccessApiTests {
    @LocalServerPort
    private int port;

    @Test
    void managesStudentAccountsRolesAndDynamicAccessSettings() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        String admin = login(client, "phase9-admin@example.test", "phase9-secure-admin-password");

        assertEquals(200, get(client, "/api/jobs", null).statusCode());
        assertEquals(200, get(client, "/api/courses", null).statusCode());
        assertEquals(200, get(client, "/api/guidance", null).statusCode());
        assertEquals(401, get(client, "/api/account/profile", null).statusCode());
        assertEquals(401, get(client, "/api/test-attempts/history", null).statusCode());
        assertEquals(401, send(client, "POST", "/api/tests/1/attempts", "{}", null).statusCode());
        assertEquals(401, get(client, "/api/admin/users", null).statusCode());
        assertEquals(200, get(client, "/api/admin/users", bearer(admin)).statusCode());

        HttpResponse<String> registered = send(client, "POST", "/api/auth/register", """
                {
                  "fullName": "Phase 9 Student",
                  "email": "phase9-student@example.test",
                  "password": "student-password-123",
                  "confirmPassword": "student-password-123",
                  "role": "ADMIN"
                }
                """, null);
        assertEquals(201, registered.statusCode(), registered.body());
        assertTrue(registered.body().contains("\"role\":\"STUDENT\""));
        assertFalse(registered.body().toLowerCase().contains("password"));
        assertEquals(400, send(client, "POST", "/api/auth/register", """
                {
                  "fullName": "Duplicate Student",
                  "email": "PHASE9-STUDENT@EXAMPLE.TEST",
                  "password": "student-password-123",
                  "confirmPassword": "student-password-123"
                }
                """, null).statusCode());

        assertEquals(401, send(client, "POST", "/api/auth/login",
                "{\"email\":\"phase9-student@example.test\",\"password\":\"wrong-password\"}",
                null).statusCode());
        String student = login(client, "phase9-student@example.test", "student-password-123");
        HttpResponse<String> profile = get(client, "/api/auth/me", bearer(student));
        assertEquals(200, profile.statusCode());
        assertTrue(profile.body().contains("\"role\":\"STUDENT\""));
        assertTrue(profile.body().contains("\"registeredAt\":"));
        assertFalse(profile.body().toLowerCase().contains("password"));
        assertEquals(403, get(client, "/api/admin/users", bearer(student)).statusCode());
        assertEquals(403, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"CAREER_GUIDANCE\",\"mode\":\"LOGIN_REQUIRED\"}",
                bearer(student)).statusCode());

        HttpResponse<String> updatedProfile = send(client, "PUT", "/api/account/profile", """
                {"fullName":"Updated Phase 9 Student","mobileNumber":"+1 555 0100","email":"changed@example.test"}
                """, bearer(student));
        assertEquals(200, updatedProfile.statusCode(), updatedProfile.body());
        assertTrue(updatedProfile.body().contains("Updated Phase 9 Student"));
        assertTrue(updatedProfile.body().contains("phase9-student@example.test"));
        assertFalse(updatedProfile.body().contains("changed@example.test"));
        assertEquals(400, send(client, "POST", "/api/account/password", """
                {"currentPassword":"incorrect","newPassword":"new-student-password-456",
                 "confirmNewPassword":"new-student-password-456"}
                """, bearer(student)).statusCode());
        assertEquals(204, send(client, "POST", "/api/account/password", """
                {"currentPassword":"student-password-123",
                 "newPassword":"new-student-password-456",
                 "confirmNewPassword":"new-student-password-456"}
                """, bearer(student)).statusCode());
        assertEquals(401, get(client, "/api/account/profile", bearer(student)).statusCode());
        assertEquals(401, send(client, "POST", "/api/auth/login",
                "{\"email\":\"phase9-student@example.test\",\"password\":\"student-password-123\"}",
                null).statusCode());
        String refreshedStudent = login(client, "phase9-student@example.test",
                "new-student-password-456");

        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"CAREER_GUIDANCE\",\"mode\":\"LOGIN_REQUIRED\"}",
                bearer(admin)).statusCode());
        assertEquals(401, get(client, "/api/guidance", null).statusCode());
        assertEquals(200, get(client, "/api/guidance", bearer(refreshedStudent)).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"GUIDANCE_ARTICLE_LISTINGS\",\"mode\":\"PUBLIC\"}",
                bearer(admin)).statusCode());
        assertEquals(200, get(client, "/api/guidance", null).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"GUIDANCE_ARTICLE_LISTINGS\",\"mode\":\"LOGIN_REQUIRED\"}",
                bearer(admin)).statusCode());
        assertEquals(401, get(client, "/api/guidance", null).statusCode());
        assertEquals(400, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"PERSONAL_PROFILE\",\"mode\":\"PUBLIC\"}",
                bearer(admin)).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"MOCK_TESTS\",\"mode\":\"LOGIN_REQUIRED\"}",
                bearer(admin)).statusCode());
        assertEquals(401, get(client, "/api/tests", null).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"MOCK_TEST_LISTINGS\",\"mode\":\"PUBLIC\"}",
                bearer(admin)).statusCode());
        assertEquals(200, get(client, "/api/tests", null).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"DAILY_QUIZZES\",\"mode\":\"LOGIN_REQUIRED\"}",
                bearer(admin)).statusCode());
        assertEquals(401, get(client, "/api/daily-quiz", null).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/access-settings",
                "{\"key\":\"DAILY_QUIZ_LISTINGS\",\"mode\":\"PUBLIC\"}",
                bearer(admin)).statusCode());
        assertEquals(204, get(client, "/api/daily-quiz", null).statusCode());

        HttpResponse<String> users = get(client, "/api/admin/users?search=phase9-student",
                bearer(admin));
        assertEquals(200, users.statusCode());
        assertTrue(users.body().contains("phase9-student@example.test"));
        assertFalse(users.body().toLowerCase().contains("password"));
        String studentId = findId(users.body());
        assertEquals(200, send(client, "PUT", "/api/admin/users/" + studentId + "/activation",
                "{\"active\":false}", bearer(admin)).statusCode());
        assertEquals(401, get(client, "/api/account/profile", bearer(refreshedStudent)).statusCode());
        assertEquals(401, send(client, "POST", "/api/auth/login",
                "{\"email\":\"phase9-student@example.test\",\"password\":\"new-student-password-456\"}",
                null).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/users/" + studentId + "/activation",
                "{\"active\":true}", bearer(admin)).statusCode());

        String adminId = findId(get(client, "/api/admin/users?search=phase9-admin", bearer(admin)).body());
        assertEquals(400, send(client, "PUT", "/api/admin/users/" + adminId + "/activation",
                "{\"active\":false}", bearer(admin)).statusCode());
    }

    private String login(HttpClient client, String email, String password) throws Exception {
        HttpResponse<String> response = send(client, "POST", "/api/auth/login",
                "{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}", null);
        assertEquals(200, response.statusCode(), response.body());
        Matcher matcher = Pattern.compile("\"token\":\"([^\"]+)\"").matcher(response.body());
        assertTrue(matcher.find());
        return matcher.group(1);
    }

    private String findId(String json) {
        Matcher matcher = Pattern.compile("\"id\":\"([^\"]+)\"").matcher(json);
        assertTrue(matcher.find());
        return matcher.group(1);
    }

    private String bearer(String token) {
        return "Bearer " + token;
    }

    private HttpResponse<String> get(HttpClient client, String path, String authorization)
            throws Exception {
        return send(client, "GET", path, "", authorization);
    }

    private HttpResponse<String> send(HttpClient client, String method, String path,
                                      String body, String authorization) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path));
        if (authorization != null) request.header("Authorization", authorization);
        if ("GET".equals(method)) request.GET();
        else request.header("Content-Type", "application/json")
                .method(method, HttpRequest.BodyPublishers.ofString(body));
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private URI uri(String path) {
        return URI.create("http://localhost:" + port + path);
    }
}
