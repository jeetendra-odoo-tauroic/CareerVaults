package career.vault.courses;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.http.ContentDisposition;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api")
public class CourseController {
    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024;
    private final CourseService service;
    private final Path imageDirectory;

    public CourseController(CourseService service,
                            @Value("${careervault.course-image-dir}") String imageDirectory) {
        this.service = service;
        this.imageDirectory = Path.of(imageDirectory).toAbsolutePath().normalize();
    }

    @GetMapping("/courses")
    public java.util.List<CourseViews.CourseView> publicCourses() {
        return service.publicCourses();
    }

    @GetMapping("/courses/{id}")
    public CourseViews.CourseView publicCourse(@PathVariable long id) {
        return service.publicCourse(id);
    }

    @GetMapping("/admin/courses")
    public java.util.List<CourseViews.CourseView> adminCourses() {
        return service.adminCourses();
    }

    @GetMapping("/admin/courses/{id}")
    public CourseViews.CourseView adminCourse(@PathVariable long id) {
        return CourseViews.CourseView.from(service.adminCourse(id), true);
    }

    @PostMapping("/admin/courses")
    public CourseViews.CourseView create(@Valid @RequestBody CourseInput input) {
        return service.create(input);
    }

    @PutMapping("/admin/courses/{id}")
    public CourseViews.CourseView update(
            @PathVariable long id, @Valid @RequestBody CourseInput input) {
        return service.update(id, input);
    }

    @DeleteMapping("/admin/courses/{id}")
    public ResponseEntity<Void> delete(@PathVariable long id) throws IOException {
        Course course = service.adminCourse(id);
        service.delete(id);
        if (course.getImageFileName() != null) {
            Files.deleteIfExists(resolveImage(course.getImageFileName()));
        }
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/admin/courses/{id}/status")
    public CourseViews.CourseView setStatus(
            @PathVariable long id, @RequestBody Map<String, CourseStatus> request) {
        CourseStatus status = request.get("status");
        if (status == null) {
            throw new IllegalArgumentException("Status must be PUBLISHED or UNPUBLISHED.");
        }
        return service.setStatus(id, status);
    }

    @PostMapping(value = "/admin/courses/{id}/image",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public CourseViews.CourseView uploadImage(
            @PathVariable long id, @RequestParam("file") MultipartFile file) throws IOException {
        if (file.isEmpty() || file.getSize() > MAX_IMAGE_SIZE) {
            throw new IllegalArgumentException("Choose a non-empty PNG, JPEG or WebP image smaller than 5 MB.");
        }
        byte[] content = file.getBytes();
        String extension = validatedExtension(file.getOriginalFilename(), file.getContentType(), content);
        Course course = service.adminCourse(id);
        Files.createDirectories(imageDirectory);
        String storedName = UUID.randomUUID() + extension;
        Files.write(resolveImage(storedName), content);
        String previousImage = course.getImageFileName();
        course.setImageFileName(storedName);
        Course saved = service.save(course);
        if (previousImage != null) {
            Files.deleteIfExists(resolveImage(previousImage));
        }
        return CourseViews.CourseView.from(saved, true);
    }

    @GetMapping("/courses/{id}/image")
    public ResponseEntity<Resource> image(@PathVariable long id) throws IOException {
        Course course = service.adminCourse(id);
        if (course.getStatus() != CourseStatus.PUBLISHED || course.getImageFileName() == null) {
            return ResponseEntity.notFound().build();
        }
        return imageResponse(id, course);
    }

    @GetMapping("/admin/courses/{id}/image")
    public ResponseEntity<Resource> adminImage(@PathVariable long id) throws IOException {
        Course course = service.adminCourse(id);
        if (course.getImageFileName() == null) return ResponseEntity.notFound().build();
        return imageResponse(id, course);
    }

    private ResponseEntity<Resource> imageResponse(long id, Course course) throws IOException {
        Path path = resolveImage(course.getImageFileName());
        if (!Files.isRegularFile(path)) return ResponseEntity.notFound().build();
        String extension = course.getImageFileName().substring(
                course.getImageFileName().lastIndexOf('.')).toLowerCase(Locale.ROOT);
        MediaType contentType = switch (extension) {
            case ".png" -> MediaType.IMAGE_PNG;
            case ".jpg", ".jpeg" -> MediaType.IMAGE_JPEG;
            case ".webp" -> MediaType.parseMediaType("image/webp");
            default -> throw new IllegalArgumentException("Unsupported course image format.");
        };
        return ResponseEntity.ok()
                .contentType(contentType)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.inline().filename("course-image-" + id + extension).build().toString())
                .header("X-Content-Type-Options", "nosniff")
                .body(new ByteArrayResource(Files.readAllBytes(path)));
    }

    private String validatedExtension(String filename, String contentType, byte[] bytes) {
        if (filename == null || contentType == null) {
            throw new IllegalArgumentException("The selected course image is invalid.");
        }
        String extension = extension(filename);
        boolean png = ".png".equals(extension) && "image/png".equalsIgnoreCase(contentType)
                && startsWith(bytes, new byte[]{(byte) 0x89, 'P', 'N', 'G', 13, 10, 26, 10});
        boolean jpeg = (".jpg".equals(extension) || ".jpeg".equals(extension))
                && "image/jpeg".equalsIgnoreCase(contentType) && bytes.length > 3
                && (bytes[0] & 0xff) == 0xff && (bytes[1] & 0xff) == 0xd8
                && (bytes[2] & 0xff) == 0xff;
        boolean webp = ".webp".equals(extension) && "image/webp".equalsIgnoreCase(contentType)
                && bytes.length > 12 && ascii(bytes, 0, "RIFF") && ascii(bytes, 8, "WEBP");
        if (!(png || jpeg || webp)) {
            throw new IllegalArgumentException("Only valid PNG, JPEG or WebP course images are supported.");
        }
        return extension;
    }

    private String extension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot < 0 ? "" : filename.substring(dot).toLowerCase(Locale.ROOT);
    }

    private boolean startsWith(byte[] bytes, byte[] prefix) {
        if (bytes.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) {
            if (bytes[i] != prefix[i]) return false;
        }
        return true;
    }

    private boolean ascii(byte[] bytes, int offset, String marker) {
        for (int i = 0; i < marker.length(); i++) {
            if (bytes[offset + i] != marker.charAt(i)) return false;
        }
        return true;
    }

    private Path resolveImage(String filename) {
        Path path = imageDirectory.resolve(filename).normalize();
        if (!path.startsWith(imageDirectory)) {
            throw new IllegalArgumentException("Invalid course image path.");
        }
        return path;
    }
}
