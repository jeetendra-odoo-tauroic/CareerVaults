package career.vault.guidance;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

@Entity
@Table(name = "guidance_articles", indexes = {
        @Index(name = "idx_guidance_status_updated", columnList = "status, updated_at"),
        @Index(name = "idx_guidance_category_status", columnList = "category, status")
})
public class GuidanceArticle {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 180)
    @Column(nullable = false, length = 180)
    private String title;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private GuidanceCategory category;

    @NotBlank
    @Size(max = 1000)
    @Column(nullable = false, length = 1000)
    private String shortDescription;

    @NotBlank
    @Size(max = 50000)
    @Column(nullable = false, columnDefinition = "TEXT")
    private String content;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private GuidanceStatus status = GuidanceStatus.UNPUBLISHED;

    @Size(max = 100)
    private String imageFileName;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected GuidanceArticle() {
    }

    public void initialize(GuidanceArticleInput input) {
        apply(input);
        createdAt = LocalDateTime.now();
    }

    public void apply(GuidanceArticleInput input) {
        title = input.title().trim();
        category = input.category();
        shortDescription = input.shortDescription().trim();
        content = input.content().trim();
        status = input.status();
        updatedAt = LocalDateTime.now();
    }

    public void setStatus(GuidanceStatus status) {
        this.status = status;
        updatedAt = LocalDateTime.now();
    }

    public void setImageFileName(String imageFileName) {
        this.imageFileName = imageFileName;
        updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public GuidanceCategory getCategory() { return category; }
    public String getShortDescription() { return shortDescription; }
    public String getContent() { return content; }
    public GuidanceStatus getStatus() { return status; }
    public String getImageFileName() { return imageFileName; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
