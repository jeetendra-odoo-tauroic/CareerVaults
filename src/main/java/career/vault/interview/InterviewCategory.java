package career.vault.interview;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;

@Entity
@Table(name = "interview_categories", indexes = {
        @Index(name = "idx_interview_category_published_name", columnList = "published, name")
})
public class InterviewCategory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false, unique = true, length = 100)
    private String name;

    @NotBlank
    @Size(max = 120)
    @Column(nullable = false, unique = true, length = 120)
    private String slug;

    @Size(max = 1000)
    private String description;

    @Column(nullable = false)
    private boolean published;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected InterviewCategory() {
    }

    public void initialize(String name, String description, boolean published) {
        update(name, description, published);
        createdAt = updatedAt;
    }

    public void update(String name, String description, boolean published) {
        this.name = name.trim();
        slug = InterviewSlugs.from(name);
        this.description = description == null || description.isBlank() ? null : description.trim();
        this.published = published;
        updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getSlug() { return slug; }
    public String getDescription() { return description; }
    public boolean isPublished() { return published; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
