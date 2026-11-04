package career.vault.guidance;

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
import java.util.Map;

@RestController
@RequestMapping("/api")
public class GuidanceController {
    private final GuidanceService service;

    public GuidanceController(GuidanceService service) {
        this.service = service;
    }

    @GetMapping("/guidance/categories")
    public List<GuidanceViews.CategoryView> categories() {
        return service.categories();
    }

    @GetMapping("/guidance")
    public GuidanceViews.ArticleList publicArticles(
            @RequestParam(required = false) GuidanceCategory category,
            @RequestParam(required = false) String search) {
        return service.publicArticles(category, search);
    }

    @GetMapping("/guidance/{id}")
    public GuidanceViews.ArticleView publicArticle(@PathVariable long id) {
        return service.publicArticle(id);
    }

    @GetMapping("/guidance/{id}/image")
    public ResponseEntity<Resource> publicImage(@PathVariable long id) throws IOException {
        return imageResponse(service.publicImage(id));
    }

    @GetMapping("/admin/guidance")
    public List<GuidanceViews.ArticleView> adminArticles() {
        return service.adminArticles();
    }

    @GetMapping("/admin/guidance/{id}")
    public GuidanceViews.ArticleView adminArticle(@PathVariable long id) {
        return GuidanceViews.ArticleView.from(service.adminArticle(id), true);
    }

    @PostMapping("/admin/guidance")
    public GuidanceViews.ArticleView create(@Valid @RequestBody GuidanceArticleInput input) {
        return service.create(input);
    }

    @PutMapping("/admin/guidance/{id}")
    public GuidanceViews.ArticleView update(
            @PathVariable long id, @Valid @RequestBody GuidanceArticleInput input) {
        return service.update(id, input);
    }

    @PutMapping("/admin/guidance/{id}/status")
    public GuidanceViews.ArticleView setStatus(
            @PathVariable long id, @RequestBody Map<String, GuidanceStatus> request) {
        GuidanceStatus status = request.get("status");
        if (status == null) {
            throw new IllegalArgumentException("Status must be PUBLISHED or UNPUBLISHED.");
        }
        return service.setStatus(id, status);
    }

    @DeleteMapping("/admin/guidance/{id}")
    public ResponseEntity<Void> delete(@PathVariable long id) throws IOException {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping(value = "/admin/guidance/{id}/image",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public GuidanceViews.ArticleView uploadImage(
            @PathVariable long id, @RequestParam("file") MultipartFile file) throws IOException {
        return service.uploadImage(id, file);
    }

    @GetMapping("/admin/guidance/{id}/image")
    public ResponseEntity<Resource> adminImage(@PathVariable long id) throws IOException {
        return imageResponse(service.adminImage(id));
    }

    private ResponseEntity<Resource> imageResponse(GuidanceService.ImageFile image) {
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(image.contentType()))
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        ContentDisposition.inline().filename(image.filename()).build().toString())
                .header("X-Content-Type-Options", "nosniff")
                .body(new ByteArrayResource(image.content()));
    }
}
