package career.vault.interview;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "interview_topics", indexes = {
        @Index(name = "idx_interview_topic_category_published_created",
                columnList = "category_id, published, created_at")
})
public class InterviewTopic {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private InterviewCategory category;

    @NotBlank
    @Size(max = 180)
    @Column(nullable = false, length = 180)
    private String title;

    @NotBlank
    @Size(max = 200)
    @Column(nullable = false, length = 200)
    private String slug;

    @NotBlank
    @Size(max = 1000)
    @Column(nullable = false, length = 1000)
    private String introduction;

    @NotBlank
    @Size(max = 100000)
    @Column(nullable = false, columnDefinition = "TEXT")
    private String article;

    @Column(length = 200)
    private String experienceLevels;

    @Column(nullable = false)
    private boolean published;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected InterviewTopic() {
    }

    public void initialize(InterviewCategory category, String title, String introduction,
                           String article, List<String> experienceLevels, boolean published) {
        this.category = category;
        update(title, introduction, article, experienceLevels, published);
        createdAt = updatedAt;
    }

    public void update(String title, String introduction, String article,
                       List<String> experienceLevels, boolean published) {
        this.title = title.trim();
        slug = InterviewSlugs.from(title);
        this.introduction = introduction.trim();
        this.article = article.trim();
        this.experienceLevels = String.join("\n", InterviewExperienceLevels.validate(experienceLevels));
        this.published = published;
        updatedAt = LocalDateTime.now();
    }

    public void setCategory(InterviewCategory category) {
        this.category = category;
    }

    public void setPublished(boolean published) {
        this.published = published;
        updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public InterviewCategory getCategory() { return category; }
    public String getTitle() { return title; }
    public String getSlug() { return slug; }
    public String getIntroduction() { return introduction; }
    public String getArticle() { return article; }
    public List<String> getExperienceLevels() {
        return experienceLevels == null || experienceLevels.isBlank()
                ? List.of() : experienceLevels.lines().toList();
    }
    public boolean isPublished() { return published; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
