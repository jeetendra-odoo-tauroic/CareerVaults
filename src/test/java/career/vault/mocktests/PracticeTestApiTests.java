package career.vault.mocktests;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.TestPropertySource;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:mock-tests-test;DB_CLOSE_DELAY=-1",
        "careervault.auth.bootstrap-admin-email=mock-admin@example.test",
        "careervault.auth.bootstrap-admin-password=mock-test-admin-password"
})
class PracticeTestApiTests {
    @LocalServerPort
    private int port;
    @Autowired
    private JdbcTemplate jdbcTemplate;
    private String adminToken;

    @Test
    void createsPublishesEvaluatesAndRetainsGuestAttemptHistory() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client, "mock-admin@example.test", "mock-test-admin-password");
        String guest = UUID.randomUUID().toString();
        String otherGuest = UUID.randomUUID().toString();

        assertEquals(14, occurrences(get(client, "/api/test-categories", guest).body(), "\"code\":"));
        HttpResponse<String> draft = send(client, "POST", "/api/admin/tests", """
                {
                  "title": "Java evaluation test",
                  "description": "Evaluate correct, incorrect and unanswered choices.",
                  "category": "CORE_JAVA",
                  "kind": "MOCK_TEST",
                  "durationMinutes": 20,
                  "negativeMarking": 0.5,
                  "passingPercentage": 50,
                  "status": "DRAFT"
                }
                """, guest);
        assertEquals(200, draft.statusCode(), draft.body());
        long testId = findId(draft.body());

        assertEquals(404, send(client, "POST",
                "/api/tests/" + testId + "/attempts", "", guest).statusCode());
        assertEquals(200, send(client, "POST",
                "/api/admin/tests/" + testId + "/questions", question(
                        "Correct answer question", 0, 2, "Correct explanation"), guest).statusCode());
        assertEquals(200, send(client, "POST",
                "/api/admin/tests/" + testId + "/questions", question(
                        "Negative marking question", 1, 1, "Wrong answer explanation"), guest).statusCode());
        assertEquals(200, send(client, "POST",
                "/api/admin/tests/" + testId + "/questions", question(
                        "Unanswered question", 3, 3, "Unanswered explanation"), guest).statusCode());

        HttpResponse<String> invalidQuestion = send(client, "POST",
                "/api/admin/tests/" + testId + "/questions", question(
                        "Invalid key", 4, 1, "Invalid"), guest);
        assertEquals(400, invalidQuestion.statusCode(), invalidQuestion.body());

        assertEquals(200, send(client, "PUT", "/api/admin/tests/" + testId + "/status",
                "{\"status\":\"PUBLISHED\"}", guest).statusCode());
        HttpResponse<String> publicList = get(client, "/api/tests", guest);
        assertTrue(publicList.body().contains("Java evaluation test"));
        assertFalse(publicList.body().contains("\"correctOption\""));
        assertFalse(publicList.body().contains("Correct explanation"));

        HttpResponse<String> started = send(client, "POST",
                "/api/tests/" + testId + "/attempts", "", guest);
        assertEquals(200, started.statusCode(), started.body());
        assertFalse(started.body().contains("\"correctOption\""));
        assertFalse(started.body().contains("\"marks\""));
        assertFalse(started.body().contains("Correct explanation"));
        String attemptId = findAttemptId(started.body());
        long firstQuestionId = findFirstQuestionId(started.body());
        long secondQuestionId = findQuestionId(started.body(), 1);

        assertEquals(200, send(client, "PUT",
                "/api/admin/tests/" + testId + "/questions/" + firstQuestionId,
                question("Updated after attempt started", 2, 9, "Changed key"), guest).statusCode());

        String answers = """
                {"answers":{"%d":0,"%d":0}}
                """.formatted(firstQuestionId, secondQuestionId);
        HttpResponse<String> result = send(client, "POST",
                "/api/test-attempts/" + attemptId + "/submit", answers, guest);
        assertEquals(200, result.statusCode(), result.body());
        assertTrue(result.body().contains("\"totalQuestions\":3"));
        assertTrue(result.body().contains("\"attemptedQuestions\":2"));
        assertTrue(result.body().contains("\"correctAnswers\":1"));
        assertTrue(result.body().contains("\"incorrectAnswers\":1"));
        assertTrue(result.body().contains("\"unansweredQuestions\":1"));
        assertTrue(result.body().contains("\"totalMarks\":6.00"));
        assertTrue(result.body().contains("\"marksObtained\":1.50"));
        assertTrue(result.body().contains("\"percentage\":25.00"));
        assertTrue(result.body().contains("Correct answer question"));
        assertTrue(result.body().contains("Correct explanation"));
        assertFalse(result.body().contains("Updated after attempt started"));

        HttpResponse<String> duplicate = send(client, "POST",
                "/api/test-attempts/" + attemptId + "/submit",
                "{\"answers\":{\"" + firstQuestionId + "\":3}}", guest);
        assertEquals(200, duplicate.statusCode(), duplicate.body());
        assertTrue(duplicate.body().contains("\"marksObtained\":1.50"));
        String studentToken = registerAndLogin(client, "result-owner@example.test");
        assertEquals(404, sendAs(client, "GET", "/api/test-attempts/" + attemptId,
                "", studentToken).statusCode());

        HttpResponse<String> secondStart = send(client, "POST",
                "/api/tests/" + testId + "/attempts", "", guest);
        String secondAttemptId = findAttemptId(secondStart.body());
        long secondQuestion1 = findQuestionId(secondStart.body(), 0);
        long secondQuestion2 = findQuestionId(secondStart.body(), 1);
        long secondQuestion3 = findQuestionId(secondStart.body(), 2);
        HttpResponse<String> passingResult = send(client, "POST",
                "/api/test-attempts/" + secondAttemptId + "/submit",
                """
                {"answers":{"%d":2,"%d":1,"%d":3}}
                """.formatted(secondQuestion1, secondQuestion2, secondQuestion3), guest);
        assertEquals(200, passingResult.statusCode(), passingResult.body());
        assertTrue(passingResult.body().contains("\"percentage\":100.00"));
        assertTrue(passingResult.body().contains("\"passed\":true"));
        assertEquals(2, occurrences(get(client, "/api/test-attempts/history", guest).body(),
                "\"attemptId\":"));
        assertEquals(401, sendWithoutAuth(client, "POST",
                "/api/tests/" + testId + "/attempts", "").statusCode());
        HttpResponse<String> adminDetails = get(client, "/api/admin/tests/" + testId, guest);
        assertTrue(adminDetails.body().contains("\"correctOption\":2"));
        long thirdAdminQuestionId = findQuestionId(adminDetails.body(), 2);
        assertEquals(204, send(client, "DELETE",
                "/api/admin/tests/" + testId + "/questions/" + thirdAdminQuestionId,
                "", guest).statusCode());
        assertTrue(get(client, "/api/admin/tests/" + testId, guest).body()
                .contains("\"questionCount\":2"));

        String daily = """
                {
                  "title": "Daily quiz test",
                  "description": "Latest daily quiz.",
                  "category": "BANKING",
                  "kind": "DAILY_QUIZ",
                  "durationMinutes": 5,
                  "negativeMarking": 0,
                  "passingPercentage": null,
                  "status": "DRAFT"
                }
                """;
        long dailyId = findId(send(client, "POST", "/api/admin/tests", daily, guest).body());
        assertEquals(200, send(client, "POST",
                "/api/admin/tests/" + dailyId + "/questions",
                question("Daily quiz question", 2, 1, null), guest).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/tests/" + dailyId + "/status",
                "{\"status\":\"PUBLISHED\"}", guest).statusCode());
        HttpResponse<String> latestQuiz = get(client, "/api/daily-quiz", guest);
        assertTrue(latestQuiz.body().contains("Daily quiz test"));
        assertFalse(latestQuiz.body().contains("\"correctOption\""));

        assertEquals(204, send(client, "DELETE", "/api/admin/tests/" + testId, "", guest).statusCode());
        assertTrue(get(client, "/api/test-attempts/" + attemptId, guest).body()
                .contains("Java evaluation test"));
    }

    @Test
    void ignoresAnswersSubmittedAfterTheServerDeadline() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client, "mock-admin@example.test", "mock-test-admin-password");
        String guest = UUID.randomUUID().toString();
        HttpResponse<String> draft = send(client, "POST", "/api/admin/tests", """
                {
                  "title": "Timed quiz",
                  "description": "Deadline evaluation.",
                  "category": "REASONING",
                  "kind": "MOCK_TEST",
                  "durationMinutes": 1,
                  "passingPercentage": null,
                  "status": "DRAFT"
                }
                """, guest);
        assertEquals(200, draft.statusCode(), draft.body());
        long testId = findId(draft.body());
        assertEquals(200, send(client, "POST", "/api/admin/tests/" + testId + "/questions",
                question("Deadline question", 0, 1, null), guest).statusCode());
        assertEquals(200, send(client, "PUT", "/api/admin/tests/" + testId + "/status",
                "{\"status\":\"PUBLISHED\"}", guest).statusCode());
        HttpResponse<String> started = send(client, "POST",
                "/api/tests/" + testId + "/attempts", "", guest);
        long questionId = findFirstQuestionId(started.body());
        String attemptId = findAttemptId(started.body());
        jdbcTemplate.update(
                "UPDATE test_attempts SET started_at = DATEADD('MINUTE', -2, CURRENT_TIMESTAMP) WHERE id = ?",
                attemptId);

        HttpResponse<String> result = send(client, "POST",
                "/api/test-attempts/" + attemptId + "/submit",
                "{\"answers\":{\"" + questionId + "\":0}}", guest);
        assertEquals(200, result.statusCode(), result.body());
        assertTrue(result.body().contains("\"attemptedQuestions\":0"));
        assertTrue(result.body().contains("\"correctAnswers\":0"));
        assertTrue(result.body().contains("\"unansweredQuestions\":1"));
        assertTrue(result.body().contains("\"marksObtained\":0.00"));
    }

    private String question(String prompt, int correct, double marks, String explanation) {
        return """
                {
                  "question": "%s",
                  "options": ["Choice A", "Choice B", "Choice C", "Choice D"],
                  "correctOption": %d,
                  "marks": %s,
                  "explanation": %s
                }
                """.formatted(prompt, correct, marks,
                explanation == null ? "null" : "\"" + explanation + "\"");
    }

    private HttpResponse<String> get(HttpClient client, String path, String guest) throws Exception {
        return client.send(HttpRequest.newBuilder(uri(path))
                        .header("Authorization", bearer()).GET().build(),
                HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> send(HttpClient client, String method, String path,
                                      String body, String guest) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path))
                .header("Authorization", bearer());
        if ("GET".equals(method)) {
            request.GET();
        } else if ("DELETE".equals(method)) {
            request.DELETE();
        } else {
            request.header("Content-Type", "application/json")
                    .method(method, HttpRequest.BodyPublishers.ofString(body));
        }
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> sendAs(HttpClient client, String method, String path,
                                        String body, String token) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path))
                .header("Authorization", "Bearer " + token);
        if ("GET".equals(method)) request.GET();
        else request.header("Content-Type", "application/json")
                .method(method, HttpRequest.BodyPublishers.ofString(body));
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private HttpResponse<String> sendWithoutAuth(HttpClient client, String method,
                                                 String path, String body) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path));
        if ("GET".equals(method)) request.GET();
        else request.header("Content-Type", "application/json")
                .method(method, HttpRequest.BodyPublishers.ofString(body));
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private String registerAndLogin(HttpClient client, String email) throws Exception {
        HttpResponse<String> registered = client.send(HttpRequest.newBuilder(uri("/api/auth/register"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString("""
                                {"fullName":"Result Owner","email":"%s",
                                 "password":"student-password-123",
                                 "confirmPassword":"student-password-123"}
                                """.formatted(email))).build(),
                HttpResponse.BodyHandlers.ofString());
        assertEquals(201, registered.statusCode(), registered.body());
        return login(client, email, "student-password-123");
    }

    private String login(HttpClient client, String email, String password) throws Exception {
        HttpResponse<String> response = client.send(HttpRequest.newBuilder(uri("/api/auth/login"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString("""
                                {"email":"%s","password":"%s"}
                                """.formatted(email, password))).build(),
                HttpResponse.BodyHandlers.ofString());
        assertEquals(200, response.statusCode(), response.body());
        Matcher matcher = Pattern.compile("\"token\":\"([^\"]+)\"").matcher(response.body());
        assertTrue(matcher.find());
        return matcher.group(1);
    }

    private String bearer() {
        return "Bearer " + adminToken;
    }

    private long findId(String json) {
        Matcher matcher = Pattern.compile("\"id\":(\\d+)").matcher(json);
        assertTrue(matcher.find(), "Could not find test id in " + json);
        return Long.parseLong(matcher.group(1));
    }

    private String findAttemptId(String json) {
        Matcher matcher = Pattern.compile("\"attemptId\":\"([^\"]+)\"").matcher(json);
        assertTrue(matcher.find(), "Could not find attempt id in " + json);
        return matcher.group(1);
    }

    private long findFirstQuestionId(String json) {
        Matcher matcher = Pattern.compile("\"id\":(\\d+),\"question\":").matcher(json);
        assertTrue(matcher.find(), "Could not find question id in " + json);
        return Long.parseLong(matcher.group(1));
    }

    private long findQuestionId(String json, int index) {
        Matcher matcher = Pattern.compile("\"id\":(\\d+),\"question\":").matcher(json);
        for (int i = 0; i <= index; i++) {
            assertTrue(matcher.find(), "Could not find question id in " + json);
        }
        return Long.parseLong(matcher.group(1));
    }

    private int occurrences(String value, String fragment) {
        return (value.length() - value.replace(fragment, "").length()) / fragment.length();
    }

    private URI uri(String path) {
        return URI.create("http://localhost:" + port + path);
    }
}
