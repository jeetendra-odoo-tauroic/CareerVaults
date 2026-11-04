package career.vault.preparation;

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
@Table(name = "preparation_categories", indexes = {
        @Index(name = "idx_preparation_category_published", columnList = "published, name")
})
public class PreparationCategory {
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

    protected PreparationCategory() {
    }

    public void update(String name, String description, boolean published) {
        this.name = name.trim();
        this.slug = PreparationSlugs.from(name);
        this.description = description == null || description.isBlank() ? null : description.trim();
        this.published = published;
        this.updatedAt = LocalDateTime.now();
    }

    public void initialize(String name, String description, boolean published) {
        update(name, description, published);
        createdAt = updatedAt;
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getSlug() { return slug; }
    public String getDescription() { return description; }
    public boolean isPublished() { return published; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
