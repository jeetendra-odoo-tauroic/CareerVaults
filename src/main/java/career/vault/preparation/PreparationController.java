package career.vault.preparation;

import jakarta.validation.Valid;
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
import java.util.List;
import java.util.Locale;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class PreparationController {
    private final PreparationService service;

    public PreparationController(PreparationService service) {
        this.service = service;
    }

    @GetMapping("/preparation/categories")
    public List<PreparationViews.CategoryView> publicCategories() {
        return service.publicCategories();
    }

    @GetMapping("/admin/preparation/categories")
    public List<PreparationViews.CategoryView> adminCategories() {
        return service.adminCategories();
    }

    @PostMapping("/admin/preparation/categories")
    public PreparationViews.CategoryView createCategory(
            @Valid @RequestBody PreparationCategoryInput input) {
        return service.createCategory(input);
    }

    @PutMapping("/admin/preparation/categories/{id}")
    public PreparationViews.CategoryView updateCategory(
            @PathVariable long id, @Valid @RequestBody PreparationCategoryInput input) {
        return service.updateCategory(id, input);
    }

    @DeleteMapping("/admin/preparation/categories/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable long id) {
        service.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/preparation/topics")
    public PreparationViews.PageView<PreparationViews.TopicView> publicTopics(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return service.publicTopics(category, search, page, size);
    }

    @GetMapping("/preparation/categories/{categorySlug}/topics")
    public PreparationViews.PageView<PreparationViews.TopicView> publicCategoryTopics(
            @PathVariable String categorySlug,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return service.publicTopics(categorySlug, search, page, size);
    }

    @GetMapping("/preparation/categories/{categorySlug}/topics/{topicSlug}")
    public PreparationViews.TopicView publicTopic(
            @PathVariable String categorySlug, @PathVariable String topicSlug) {
        return service.publicTopic(categorySlug, topicSlug);
    }

    @GetMapping("/admin/preparation/topics")
    public PreparationViews.PageView<PreparationViews.TopicView> adminTopics(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.adminTopics(categoryId, search, page, size);
    }

    @GetMapping("/admin/preparation/topics/{id}")
    public PreparationViews.TopicView adminTopic(@PathVariable long id) {
        return service.adminTopic(id);
    }

    @PostMapping("/admin/preparation/topics")
    public PreparationViews.TopicView createTopic(@Valid @RequestBody PreparationTopicInput input) {
        return service.createTopic(input);
    }

    @PutMapping("/admin/preparation/topics/{id}")
    public PreparationViews.TopicView updateTopic(
            @PathVariable long id, @Valid @RequestBody PreparationTopicInput input) {
        return service.updateTopic(id, input);
    }

    @DeleteMapping("/admin/preparation/topics/{id}")
    public ResponseEntity<Void> deleteTopic(@PathVariable long id) throws IOException {
        service.deleteTopic(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/admin/preparation/topics/{id}/publication")
    public PreparationViews.TopicView publishTopic(
            @PathVariable long id, @RequestBody Map<String, Boolean> request) {
        Boolean published = request.get("published");
        if (published == null) {
            throw new IllegalArgumentException("The published field is required.");
        }
        return service.setTopicPublished(id, published);
    }

    @PostMapping("/admin/preparation/topics/{id}/subtopics")
    public PreparationViews.SubtopicView createSubtopic(
            @PathVariable long id, @Valid @RequestBody PreparationSubtopicInput input) {
        return service.createSubtopic(id, input);
    }

    @PutMapping("/admin/preparation/topics/{id}/subtopics/{subtopicId}")
    public PreparationViews.SubtopicView updateSubtopic(
            @PathVariable long id, @PathVariable long subtopicId,
            @Valid @RequestBody PreparationSubtopicInput input) {
        return service.updateSubtopic(id, subtopicId, input);
    }

    @DeleteMapping("/admin/preparation/topics/{id}/subtopics/{subtopicId}")
    public ResponseEntity<Void> deleteSubtopic(
            @PathVariable long id, @PathVariable long subtopicId) {
        service.deleteSubtopic(id, subtopicId);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/admin/preparation/topics/{id}/resources",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public PreparationViews.ResourceView uploadResource(
            @PathVariable long id,
            @RequestParam("file") MultipartFile file,
            @RequestParam(defaultValue = "RESOURCE") String kind) throws IOException {
        String normalizedKind = kind.trim().toUpperCase(Locale.ROOT);
        if (!List.of("IMAGE", "RESOURCE").contains(normalizedKind)) {
            throw new IllegalArgumentException("Resource kind must be IMAGE or RESOURCE.");
        }
        return service.uploadResource(id, file, normalizedKind);
    }

    @DeleteMapping("/admin/preparation/topics/{id}/resources/{resourceId}")
    public ResponseEntity<Void> deleteResource(
            @PathVariable long id, @PathVariable long resourceId) throws IOException {
        service.deleteResource(id, resourceId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/preparation/resources/{id}")
    public ResponseEntity<Resource> publicResource(@PathVariable long id) throws IOException {
        PreparationService.ResourceFile file = service.publicResource(id);
        MediaType contentType = MediaType.parseMediaType(file.contentType());
        return ResponseEntity.ok()
                .contentType(contentType)
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.inline().filename(file.filename()).build().toString())
                .header("X-Content-Type-Options", "nosniff")
                .body(new ByteArrayResource(file.content()));
    }
}
