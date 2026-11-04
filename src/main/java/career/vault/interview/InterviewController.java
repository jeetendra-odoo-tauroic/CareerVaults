package career.vault.interview;

import jakarta.validation.Valid;
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

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class InterviewController {
    private final InterviewService service;

    public InterviewController(InterviewService service) {
        this.service = service;
    }

    @GetMapping("/interviews/categories")
    public List<InterviewViews.CategoryView> publicCategories() {
        return service.publicCategories();
    }

    @GetMapping("/admin/interviews/categories")
    public List<InterviewViews.CategoryView> adminCategories() {
        return service.adminCategories();
    }

    @PostMapping("/admin/interviews/categories")
    public InterviewViews.CategoryView createCategory(
            @Valid @RequestBody InterviewCategoryInput input) {
        return service.createCategory(input);
    }

    @PutMapping("/admin/interviews/categories/{id}")
    public InterviewViews.CategoryView updateCategory(
            @PathVariable long id, @Valid @RequestBody InterviewCategoryInput input) {
        return service.updateCategory(id, input);
    }

    @DeleteMapping("/admin/interviews/categories/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable long id) {
        service.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/interviews/topics")
    public InterviewViews.PageView<InterviewViews.TopicView> publicTopics(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String experienceLevel,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return service.publicTopics(category, search, experienceLevel, page, size);
    }

    @GetMapping("/interviews/categories/{categorySlug}/topics")
    public InterviewViews.PageView<InterviewViews.TopicView> publicCategoryTopics(
            @PathVariable String categorySlug,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String experienceLevel,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {
        return service.publicTopics(categorySlug, search, experienceLevel, page, size);
    }

    @GetMapping("/interviews/categories/{categorySlug}/topics/{topicSlug}")
    public InterviewViews.TopicView publicTopic(
            @PathVariable String categorySlug, @PathVariable String topicSlug) {
        return service.publicTopic(categorySlug, topicSlug);
    }

    @GetMapping("/admin/interviews/topics")
    public InterviewViews.PageView<InterviewViews.TopicView> adminTopics(
            @RequestParam(required = false) Long categoryId,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String experienceLevel,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.adminTopics(categoryId, search, experienceLevel, page, size);
    }

    @GetMapping("/admin/interviews/topics/{id}")
    public InterviewViews.TopicView adminTopic(@PathVariable long id) {
        return service.adminTopic(id);
    }

    @PostMapping("/admin/interviews/topics")
    public InterviewViews.TopicView createTopic(@Valid @RequestBody InterviewTopicInput input) {
        return service.createTopic(input);
    }

    @PutMapping("/admin/interviews/topics/{id}")
    public InterviewViews.TopicView updateTopic(
            @PathVariable long id, @Valid @RequestBody InterviewTopicInput input) {
        return service.updateTopic(id, input);
    }

    @DeleteMapping("/admin/interviews/topics/{id}")
    public ResponseEntity<Void> deleteTopic(@PathVariable long id) {
        service.deleteTopic(id);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/admin/interviews/topics/{id}/publication")
    public InterviewViews.TopicView setTopicPublication(
            @PathVariable long id, @RequestBody Map<String, Boolean> request) {
        Boolean published = request.get("published");
        if (published == null) {
            throw new IllegalArgumentException("The published field is required.");
        }
        return service.setTopicPublished(id, published);
    }
}
