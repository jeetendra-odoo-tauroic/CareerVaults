package career.vault.courses;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.TestPropertySource;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:course-test;DB_CLOSE_DELAY=-1",
        "careervault.course-image-dir=target/test-course-images",
        "careervault.auth.bootstrap-admin-email=course-admin@example.test",
        "careervault.auth.bootstrap-admin-password=course-test-admin-password"
})
class CourseApiTests {
    @LocalServerPort
    private int port;
    private String adminToken;

    @Test
    void managesCoursesAndOnlyServesPublishedCoursesAndImages() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client);
        String course = """
                {
                  "name": "Course API Test",
                  "category": "Software Development",
                  "description": "A complete course description.",
                  "price": 149.50,
                  "status": "PUBLISHED"
                }
                """;
        HttpResponse<String> created = send(client, "POST", "/api/admin/courses", course);
        assertEquals(200, created.statusCode(), created.body());
        assertTrue(created.body().contains("\"price\":149.50"));
        long id = findId(created.body());

        assertTrue(get(client, "/api/courses").body().contains("Course API Test"));
        assertTrue(get(client, "/api/courses/" + id).body().contains("A complete course description."));
        assertTrue(get(client, "/api/admin/courses").body().contains("Course API Test"));

        byte[] image = new byte[]{
                (byte) 0x89, 'P', 'N', 'G', 13, 10, 26, 10, 0, 0, 0, 0
        };
        HttpResponse<byte[]> uploaded = uploadImage(client, id, image, "cover.png", "image/png");
        assertEquals(200, uploaded.statusCode());
        assertTrue(new String(uploaded.body(), StandardCharsets.UTF_8).contains("\"imageUrl\""));
        HttpResponse<byte[]> imageResponse = client.send(
                HttpRequest.newBuilder(uri("/api/courses/" + id + "/image")).GET().build(),
                HttpResponse.BodyHandlers.ofByteArray());
        assertEquals(200, imageResponse.statusCode());
        assertEquals("image/png", imageResponse.headers().firstValue("Content-Type").orElseThrow());

        HttpResponse<String> updated = send(client, "PUT", "/api/admin/courses/" + id, """
                {
                  "name": "Course API Test Updated",
                  "category": "Backend",
                  "description": "Updated course description.",
                  "price": 0,
                  "status": "PUBLISHED"
                }
                """);
        assertEquals(200, updated.statusCode(), updated.body());
        assertTrue(updated.body().contains("\"price\":0.00"));

        HttpResponse<String> unpublished = send(client, "PUT",
                "/api/admin/courses/" + id + "/status", "{\"status\":\"UNPUBLISHED\"}");
        assertEquals(200, unpublished.statusCode(), unpublished.body());
        assertFalse(get(client, "/api/courses").body().contains("Course API Test Updated"));
        assertEquals(404, send(client, "GET", "/api/courses/" + id, "").statusCode());
        assertEquals(404, send(client, "GET", "/api/courses/" + id + "/image", "").statusCode());
        assertEquals(200, send(client, "GET",
                "/api/admin/courses/" + id + "/image", "").statusCode());
        assertTrue(get(client, "/api/admin/courses").body().contains("Course API Test Updated"));

        HttpResponse<String> invalid = send(client, "POST", "/api/admin/courses", """
                {
                  "name": "Invalid Course",
                  "category": "Testing",
                  "description": "Invalid price.",
                  "price": -1,
                  "status": "UNPUBLISHED"
                }
                """);
        assertEquals(400, invalid.statusCode(), invalid.body());

        assertEquals(204, send(client, "DELETE", "/api/admin/courses/" + id, "").statusCode());
        assertEquals(404, send(client, "GET", "/api/admin/courses/" + id, "").statusCode());
    }

    @Test
    void rejectsImageContentThatDoesNotMatchItsDeclaredFormat() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client);
        HttpResponse<String> created = send(client, "POST", "/api/admin/courses", """
                {
                  "name": "Invalid Image Test",
                  "category": "Testing",
                  "description": "Testing image validation.",
                  "price": 0,
                  "status": "UNPUBLISHED"
                }
                """);
        assertEquals(200, created.statusCode(), created.body());
        HttpResponse<byte[]> response = uploadImage(client, findId(created.body()),
                "not an image".getBytes(StandardCharsets.UTF_8), "cover.png", "image/png");
        assertEquals(400, response.statusCode());
    }

    private HttpResponse<String> get(HttpClient client, String path) throws Exception {
        return send(client, "GET", path, "");
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

    private HttpResponse<byte[]> uploadImage(HttpClient client, long id, byte[] bytes,
                                             String filename, String contentType) throws Exception {
        String boundary = "CareerVaultCourseBoundary";
        byte[] header = ("--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"file\"; filename=\"" + filename + "\"\r\n"
                + "Content-Type: " + contentType + "\r\n\r\n").getBytes(StandardCharsets.US_ASCII);
        byte[] footer = ("\r\n--" + boundary + "--\r\n").getBytes(StandardCharsets.US_ASCII);
        byte[] body = new byte[header.length + bytes.length + footer.length];
        System.arraycopy(header, 0, body, 0, header.length);
        System.arraycopy(bytes, 0, body, header.length, bytes.length);
        System.arraycopy(footer, 0, body, header.length + bytes.length, footer.length);
        HttpRequest request = HttpRequest.newBuilder(uri("/api/admin/courses/" + id + "/image"))
                .header("Authorization", bearer())
                .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                .POST(HttpRequest.BodyPublishers.ofByteArray(body))
                .build();
        return client.send(request, HttpResponse.BodyHandlers.ofByteArray());
    }

    private long findId(String json) {
        Matcher matcher = Pattern.compile("\"id\":(\\d+)").matcher(json);
        assertTrue(matcher.find(), "Could not find course id in " + json);
        return Long.parseLong(matcher.group(1));
    }

    private URI uri(String path) {
        return URI.create("http://localhost:" + port + path);
    }

    private String login(HttpClient client) throws Exception {
        HttpResponse<String> response = client.send(HttpRequest.newBuilder(uri("/api/auth/login"))
                        .header("Content-Type", "application/json")
                        .POST(HttpRequest.BodyPublishers.ofString("""
                                {"email":"course-admin@example.test","password":"course-test-admin-password"}
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
