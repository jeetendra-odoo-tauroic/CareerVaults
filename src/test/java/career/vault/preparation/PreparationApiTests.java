package career.vault.preparation;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.TestPropertySource;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:preparation-test;DB_CLOSE_DELAY=-1",
        "careervault.preparation-resource-dir=target/test-preparation-resources",
        "careervault.auth.bootstrap-admin-email=preparation-admin@example.test",
        "careervault.auth.bootstrap-admin-password=preparation-test-admin-password"
})
class PreparationApiTests {
    @LocalServerPort
    private int port;
    private String adminToken;

    @Test
    void servesSeededCategoriesHidesDraftsAndPublishesLessonsBySeoUrl() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client);

        HttpResponse<String> categories = get(client, "/api/preparation/categories");
        assertEquals(200, categories.statusCode());
        assertTrue(categories.body().contains("Java Development"));
        assertTrue(categories.body().contains("Python Development"));

        HttpResponse<String> adminTopics = get(client, "/api/admin/preparation/topics?page=0&size=50");
        assertEquals(200, adminTopics.statusCode());
        assertTrue(adminTopics.body().contains("\"totalElements\":44"));

        HttpResponse<String> publicTopics = get(client, "/api/preparation/topics");
        assertEquals(200, publicTopics.statusCode());
        assertTrue(publicTopics.body().contains("\"totalElements\":0"));

        String topic = """
                {
                  "categoryId": 1,
                  "title": "Java API Test Topic",
                  "introduction": "An API test lesson.",
                  "explanation": "Detailed test lesson content.",
                  "published": true,
                  "subtopics": [{"title":"Overview","content":"Topic content","sortOrder":0}]
                }
                """;
        HttpRequest create = HttpRequest.newBuilder(uri("/api/admin/preparation/topics"))
                .header("Authorization", bearer())
                .header("Content-Type", "application/json")
                .POST(HttpRequest.BodyPublishers.ofString(topic))
                .build();
        HttpResponse<String> created = client.send(create, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, created.statusCode(), created.body());
        assertTrue(created.body().contains("\"slug\":\"java-api-test-topic\""));
        assertTrue(created.body().contains("\"title\":\"Overview\""));

        String boundary = "CareerVaultTestBoundary";
        String multipartBody = "--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"file\"; filename=\"notice.pdf\"\r\n"
                + "Content-Type: application/pdf\r\n\r\n"
                + "%PDF-1.4\nTest notification\n"
                + "\r\n--" + boundary + "--\r\n";
        HttpRequest upload = HttpRequest.newBuilder(
                        uri("/api/admin/preparation/topics/45/resources?kind=RESOURCE"))
                .header("Authorization", bearer())
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(
                        multipartBody.getBytes(StandardCharsets.US_ASCII)))
                .build();
        HttpResponse<String> resource = client.send(
                upload, HttpResponse.BodyHandlers.ofString());
        assertEquals(200, resource.statusCode(), resource.body());
        assertTrue(resource.body().contains("notice.pdf"));

        HttpResponse<String> publishedResource = get(client, "/api/preparation/resources/1");
        assertEquals(200, publishedResource.statusCode());
        assertTrue(publishedResource.body().startsWith("%PDF-1.4"));

        HttpRequest unpublish = HttpRequest.newBuilder(
                        uri("/api/admin/preparation/topics/45/publication"))
                .header("Authorization", bearer())
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString("{\"published\":false}"))
                .build();
        assertEquals(200, client.send(
                unpublish, HttpResponse.BodyHandlers.ofString()).statusCode());
        assertEquals(404, get(client,
                "/api/preparation/categories/java-development/topics/java-api-test-topic").statusCode());
        assertEquals(404, get(client, "/api/preparation/resources/1").statusCode());

        HttpRequest republish = HttpRequest.newBuilder(
                        uri("/api/admin/preparation/topics/45/publication"))
                .header("Authorization", bearer())
                .header("Content-Type", "application/json")
                .PUT(HttpRequest.BodyPublishers.ofString("{\"published\":true}"))
                .build();
        assertEquals(200, client.send(
                republish, HttpResponse.BodyHandlers.ofString()).statusCode());

        HttpResponse<String> detail = get(client,
                "/api/preparation/categories/java-development/topics/java-api-test-topic");
        assertEquals(200, detail.statusCode(), detail.body());
        assertTrue(detail.body().contains("Java API Test Topic"));
    }

    private HttpResponse<String> get(HttpClient client, String path) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path));
        if (path.startsWith("/api/admin/")) request.header("Authorization", bearer());
        return client.send(request.GET().build(),
                HttpResponse.BodyHandlers.ofString());
    }

    private URI uri(String path) {
        return URI.create("http://localhost:" + port + path);
    }

    private String login(HttpClient client) throws Exception {
        HttpResponse<String> response = client.send(HttpRequest.newBuilder(uri("/api/auth/login"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString("""
                                {"email":"preparation-admin@example.test","password":"preparation-test-admin-password"}
                                """)).build(),
                HttpResponse.BodyHandlers.ofString());
        assertEquals(200, response.statusCode(), response.body());
        java.util.regex.Matcher matcher = java.util.regex.Pattern
                .compile("\"token\":\"([^\"]+)\"").matcher(response.body());
        assertTrue(matcher.find());
        return matcher.group(1);
    }

    private String bearer() {
        return "Bearer " + adminToken;
    }
}
