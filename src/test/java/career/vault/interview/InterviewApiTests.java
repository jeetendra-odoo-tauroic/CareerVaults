package career.vault.interview;

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
        "spring.datasource.url=jdbc:h2:mem:interview-test;DB_CLOSE_DELAY=-1",
        "careervault.auth.bootstrap-admin-email=interview-admin@example.test",
        "careervault.auth.bootstrap-admin-password=interview-test-admin-password"
})
class InterviewApiTests {
    @LocalServerPort
    private int port;
    private String adminToken;

    @Test
    void seedsCategoriesSupportsExperienceSearchAndManagesArticlesBySeoUrl() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client);
        HttpResponse<String> categories = get(client, "/api/interviews/categories");
        assertEquals(200, categories.statusCode(), categories.body());
        assertEquals(7, occurrences(categories.body(), "\"slug\":"));
        assertTrue(categories.body().contains("Java Interviews"));
        assertTrue(categories.body().contains("Architecture and Design"));

        HttpResponse<String> adminTopics = get(client, "/api/admin/interviews/topics?page=0&size=50");
        assertTrue(adminTopics.body().contains("\"totalElements\":43"));
        assertTrue(get(client, "/api/interviews/topics").body().contains("\"totalElements\":0"));

        long javaCategoryId = findId(categories.body(), "java-interviews");

        String article = """
                {
                  "categoryId": %d,
                  "title": "Java Interview Foundations",
                  "introduction": "A guide to Java interview preparation.",
                  "article": "Review Java language concepts and their trade-offs.",
                  "experienceLevels": ["Fresher", "0–2 years"],
                  "published": true
                }
                """.formatted(javaCategoryId);
        HttpResponse<String> created = send(client, "POST", "/api/admin/interviews/topics", article);
        assertEquals(200, created.statusCode(), created.body());
        assertTrue(created.body().contains("\"slug\":\"java-interview-foundations\""));
        assertTrue(created.body().contains("\"article\":"));
        assertFalse(created.body().contains("\"questions\""));
        assertFalse(created.body().contains("\"answers\""));
        assertEquals(400, send(client, "DELETE",
                "/api/admin/interviews/categories/" + javaCategoryId, "").statusCode());

        String updatedArticle = """
                {
                  "categoryId": %d,
                  "title": "Java Interview Foundations",
                  "introduction": "Updated interview article introduction.",
                  "article": "Updated Java article content.",
                  "experienceLevels": ["Fresher"],
                  "published": true
                }
                """.formatted(javaCategoryId);
        HttpResponse<String> updatedTopic = send(client, "PUT",
                "/api/admin/interviews/topics/" + findTopicId(created.body()),
                updatedArticle);
        assertEquals(200, updatedTopic.statusCode(), updatedTopic.body());
        assertTrue(updatedTopic.body().contains("Updated Java article content."));

        HttpResponse<String> filtered = get(client,
                "/api/interviews/topics?search=foundations&experienceLevel=Fresher");
        assertTrue(filtered.body().contains("\"totalElements\":1"));
        assertTrue(filtered.body().contains("Java Interview Foundations"));
        HttpResponse<String> categoryTopics = get(client,
                "/api/interviews/categories/java-interviews/topics?search=foundations&experienceLevel=Fresher");
        assertTrue(categoryTopics.body().contains("\"totalElements\":1"));
        assertTrue(categoryTopics.body().contains("Java Interview Foundations"));
        assertTrue(get(client, "/api/interviews/topics?experienceLevel=12%2B%20years")
                .body().contains("\"totalElements\":0"));

        long topicId = findTopicId(updatedTopic.body());
        HttpResponse<String> unpublished = send(client, "PUT",
                "/api/admin/interviews/topics/" + topicId + "/publication",
                "{\"published\":false}");
        assertEquals(200, unpublished.statusCode(), unpublished.body());
        assertEquals(404, send(client, "GET",
                "/api/interviews/categories/java-interviews/topics/java-interview-foundations", "")
                .statusCode());
        HttpResponse<String> published = send(client, "PUT",
                "/api/admin/interviews/topics/" + topicId + "/publication",
                "{\"published\":true}");
        assertEquals(200, published.statusCode(), published.body());

        HttpResponse<String> detail = get(client,
                "/api/interviews/categories/java-interviews/topics/java-interview-foundations");
        assertTrue(detail.body().contains("Java Interview Foundations"));
        assertTrue(detail.body().contains("Updated Java article content."));
        assertEquals(204, send(client, "DELETE",
                "/api/admin/interviews/topics/" + topicId, "").statusCode());
        assertEquals(404, send(client, "GET",
                "/api/interviews/categories/java-interviews/topics/java-interview-foundations", "")
                .statusCode());

        HttpResponse<String> newCategory = send(client, "POST", "/api/admin/interviews/categories",
                """
                {"name":"API Testing Interviews","description":"Category CRUD test","published":true}
                """);
        assertEquals(200, newCategory.statusCode(), newCategory.body());
        long categoryId = findId(newCategory.body(), "api-testing-interviews");
        HttpResponse<String> updated = send(client, "PUT", "/api/admin/interviews/categories/" + categoryId,
                """
                {"name":"API Testing Interviews","description":"Updated category","published":true}
                """);
        assertEquals(200, updated.statusCode(), updated.body());
        assertEquals(204, send(client, "DELETE",
                "/api/admin/interviews/categories/" + categoryId, "").statusCode());
        assertEquals(400, send(client, "GET",
                "/api/interviews/topics?experienceLevel=Expert", "").statusCode());
    }

    private HttpResponse<String> get(HttpClient client, String path) throws Exception {
        HttpResponse<String> response = send(client, "GET", path, "");
        assertEquals(200, response.statusCode(), response.body());
        return response;
    }

    private long findId(String json, String slug) {
        Matcher category = Pattern.compile("\\{[^{}]*\"id\":(\\d+),\"name\":\"[^\"]*\","
                + "\"slug\":\"" + Pattern.quote(slug) + "\"[^{}]*}").matcher(json);
        assertTrue(category.find(), "Could not find category slug " + slug + " in " + json);
        return Long.parseLong(category.group(1));
    }

    private long findTopicId(String json) {
        Matcher topic = Pattern.compile("\"id\":(\\d+),\"category\":").matcher(json);
        assertTrue(topic.find(), "Could not find topic id in " + json);
        return Long.parseLong(topic.group(1));
    }

    private int occurrences(String value, String fragment) {
        return (value.length() - value.replace(fragment, "").length()) / fragment.length();
    }

    private HttpResponse<String> send(HttpClient client, String method, String path,
                                      String body) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path));
        if (path.startsWith("/api/admin/")) request.header("Authorization", bearer());
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

    private URI uri(String path) {
        return URI.create("http://localhost:" + port + path);
    }

    private String login(HttpClient client) throws Exception {
        HttpResponse<String> response = client.send(HttpRequest.newBuilder(uri("/api/auth/login"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString("""
                                {"email":"interview-admin@example.test","password":"interview-test-admin-password"}
                                """)).build(),
                HttpResponse.BodyHandlers.ofString());
        assertEquals(200, response.statusCode(), response.body());
        Matcher matcher = Pattern.compile("\"token\":\"([^\"]+)\"").matcher(response.body());
        assertTrue(matcher.find());
        return matcher.group(1);
    }

    private String bearer() {
        return "Bearer " + adminToken;
    }
}
