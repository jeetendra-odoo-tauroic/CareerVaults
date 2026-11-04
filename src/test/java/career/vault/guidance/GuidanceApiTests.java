package career.vault.guidance;

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
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@TestPropertySource(properties = {
        "spring.datasource.url=jdbc:h2:mem:guidance-test;DB_CLOSE_DELAY=-1",
        "careervault.guidance.image-dir=target/test-guidance-images",
        "careervault.auth.bootstrap-admin-email=guidance-admin@example.test",
        "careervault.auth.bootstrap-admin-password=guidance-test-admin-password"
})
class GuidanceApiTests {
    @LocalServerPort
    private int port;
    private String adminToken;

    @Test
    void managesArticlesSecuresAdminAndFiltersPublishedArticles() throws Exception {
        HttpClient client = HttpClient.newHttpClient();
        adminToken = login(client, "guidance-admin@example.test",
                "guidance-test-admin-password");
        assertEquals(9, occurrences(get(client, "/api/guidance/categories", null).body(), "\"code\":"));

        assertEquals(401, send(client, "GET", "/api/admin/guidance", "", null).statusCode());
        assertEquals(401, send(client, "GET", "/api/admin/guidance", "",
                "Bearer wrong-token").statusCode());
        assertEquals(200, send(client, "OPTIONS", "/api/admin/guidance", "", null).statusCode());

        HttpResponse<String> created = send(client, "POST", "/api/admin/guidance", """
                {
                  "title": "Java roadmap for freshers",
                  "category": "FRESHERS",
                  "shortDescription": "A practical start to a Java career.",
                  "content": "Learn core Java first.\\nThen practice building APIs.",
                  "status": "UNPUBLISHED"
                }
                """, bearer());
        assertEquals(200, created.statusCode(), created.body());
        long id = findId(created.body());
        assertTrue(created.body().contains("\"createdAt\":"));
        assertTrue(created.body().contains("\"updatedAt\":"));
        assertEquals(0, occurrences(get(client, "/api/guidance", null).body(),
                "Java roadmap for freshers"));
        assertEquals(404, get(client, "/api/guidance/" + id, null).statusCode());

        HttpResponse<String> updated = send(client, "PUT", "/api/admin/guidance/" + id, """
                {
                  "title": "Java Career Roadmap",
                  "category": "JAVA_ROADMAP",
                  "shortDescription": "Build practical Java skills step by step.",
                  "content": "Study the language, then build real projects.",
                  "status": "PUBLISHED"
                }
                """, bearer());
        assertEquals(200, updated.statusCode(), updated.body());
        assertTrue(updated.body().contains("\"title\":\"Java Career Roadmap\""));

        String boundary = "CareerVaultGuidanceBoundary";
        byte[] png = new byte[]{
                (byte) 0x89, 'P', 'N', 'G', 13, 10, 26, 10, 0, 0, 0, 0
        };
        assertEquals(200, uploadImage(client, id, png, boundary).statusCode());
        HttpResponse<byte[]> image = client.send(
                HttpRequest.newBuilder(uri("/api/guidance/" + id + "/image")).GET().build(),
                HttpResponse.BodyHandlers.ofByteArray());
        assertEquals(200, image.statusCode());
        assertEquals("image/png", image.headers().firstValue("Content-Type").orElseThrow());
        assertEquals(200, get(client, "/api/admin/guidance/" + id + "/image",
                bearer()).statusCode());

        HttpResponse<String> all = get(client, "/api/guidance", null);
        assertTrue(all.body().contains("Java Career Roadmap"));
        assertEquals(1, articleCount(get(client,
                "/api/guidance?category=JAVA_ROADMAP&search=career", null).body()));
        assertEquals(0, articleCount(get(client,
                "/api/guidance?category=PYTHON_ROADMAP", null).body()));
        assertEquals(1, articleCount(get(client, "/api/guidance?search=ROADMAP", null).body()));

        HttpResponse<String> detail = get(client, "/api/guidance/" + id, null);
        assertEquals(200, detail.statusCode(), detail.body());
        assertTrue(detail.body().contains("Study the language"));
        assertTrue(detail.body().contains("JAVA_ROADMAP"));

        HttpResponse<String> adminList = get(client, "/api/admin/guidance", bearer());
        assertTrue(adminList.body().contains("Java Career Roadmap"));
        assertEquals(200, send(client, "PUT", "/api/admin/guidance/" + id + "/status",
                "{\"status\":\"UNPUBLISHED\"}", bearer()).statusCode());
        assertEquals(404, get(client, "/api/guidance/" + id, null).statusCode());
        assertEquals(404, get(client, "/api/guidance/" + id + "/image", null).statusCode());
        assertEquals(200, get(client, "/api/admin/guidance/" + id, bearer()).statusCode());

        HttpResponse<String> invalid = send(client, "POST", "/api/admin/guidance", """
                {
                  "title": "",
                  "category": "NOT_A_CATEGORY",
                  "shortDescription": "Bad article",
                  "content": "Content",
                  "status": "PUBLISHED"
                }
                """, bearer());
        assertEquals(400, invalid.statusCode());

        assertEquals(204, send(client, "DELETE", "/api/admin/guidance/" + id, "", bearer()).statusCode());
        assertEquals(404, get(client, "/api/guidance/" + id, null).statusCode());
    }

    private HttpResponse<byte[]> uploadImage(HttpClient client, long id, byte[] bytes,
                                             String boundary) throws Exception {
        byte[] header = ("--" + boundary + "\r\n"
                + "Content-Disposition: form-data; name=\"file\"; filename=\"roadmap.png\"\r\n"
                + "Content-Type: image/png\r\n\r\n").getBytes(StandardCharsets.US_ASCII);
        byte[] footer = ("\r\n--" + boundary + "--\r\n").getBytes(StandardCharsets.US_ASCII);
        byte[] body = new byte[header.length + bytes.length + footer.length];
        System.arraycopy(header, 0, body, 0, header.length);
        System.arraycopy(bytes, 0, body, header.length, bytes.length);
        System.arraycopy(footer, 0, body, header.length + bytes.length, footer.length);
        return client.send(HttpRequest.newBuilder(uri("/api/admin/guidance/" + id + "/image"))
                        .header("Authorization", bearer())
                        .header("Content-Type", "multipart/form-data; boundary=" + boundary)
                        .POST(HttpRequest.BodyPublishers.ofByteArray(body)).build(),
                HttpResponse.BodyHandlers.ofByteArray());
    }

    private HttpResponse<String> get(HttpClient client, String path, String authorization) throws Exception {
        return send(client, "GET", path, "", authorization);
    }

    private HttpResponse<String> send(HttpClient client, String method, String path,
                                      String body, String authorization) throws Exception {
        HttpRequest.Builder request = HttpRequest.newBuilder(uri(path));
        if (authorization != null) request.header("Authorization", authorization);
        if ("GET".equals(method)) {
            request.GET();
        } else if ("DELETE".equals(method)) {
            request.DELETE();
        } else if ("OPTIONS".equals(method)) {
            request.method("OPTIONS", HttpRequest.BodyPublishers.noBody());
        } else {
            request.header("Content-Type", "application/json")
                    .method(method, HttpRequest.BodyPublishers.ofString(body));
        }
        return client.send(request.build(), HttpResponse.BodyHandlers.ofString());
    }

    private String bearer() {
        return "Bearer " + adminToken;
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
        assertTrue(matcher.find(), "Could not find token in " + response.body());
        return matcher.group(1);
    }

    private long findId(String json) {
        Matcher matcher = Pattern.compile("\"id\":(\\d+)").matcher(json);
        assertTrue(matcher.find(), "Could not find article id in " + json);
        return Long.parseLong(matcher.group(1));
    }

    private int articleCount(String responseBody) throws Exception {
        return occurrences(responseBody, "\"shortDescription\":");
    }

    private int occurrences(String value, String fragment) {
        return (value.length() - value.replace(fragment, "").length()) / fragment.length();
    }

    private URI uri(String path) {
        return URI.create("http://localhost:" + port + path);
    }
}
