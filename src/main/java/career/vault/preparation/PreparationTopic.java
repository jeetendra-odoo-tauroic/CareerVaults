package career.vault.preparation;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "preparation_topics", indexes = {
        @Index(name = "idx_preparation_topic_category_published_created",
                columnList = "category_id, published, created_at")
})
public class PreparationTopic {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "category_id", nullable = false)
    private PreparationCategory category;

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
    @Column(nullable = false, columnDefinition = "TEXT")
    private String explanation;

    @Column(columnDefinition = "TEXT")
    private String codeExamples;

    @Column(columnDefinition = "TEXT")
    private String practicalExamples;

    @Column(columnDefinition = "TEXT")
    private String referenceLinks;

    @Column(nullable = false)
    private boolean published;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "topic", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("sortOrder ASC, id ASC")
    private List<PreparationSubtopic> subtopics = new ArrayList<>();

    @OneToMany(mappedBy = "topic", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("createdAt ASC")
    private List<PreparationResource> resources = new ArrayList<>();

    protected PreparationTopic() {
    }

    public void initialize(PreparationCategory category, String title, String introduction,
                           String explanation, String codeExamples, String practicalExamples,
                           String referenceLinks, boolean published) {
        this.category = category;
        update(title, introduction, explanation, codeExamples, practicalExamples, referenceLinks, published);
        createdAt = updatedAt;
    }

    public void update(String title, String introduction, String explanation, String codeExamples,
                       String practicalExamples, String referenceLinks, boolean published) {
        this.title = title.trim();
        this.slug = PreparationSlugs.from(title);
        this.introduction = introduction.trim();
        this.explanation = explanation.trim();
        this.codeExamples = clean(codeExamples);
        this.practicalExamples = clean(practicalExamples);
        this.referenceLinks = clean(referenceLinks);
        this.published = published;
        this.updatedAt = LocalDateTime.now();
    }

    public void setCategory(PreparationCategory category) {
        this.category = category;
    }

    public void setPublished(boolean published) {
        this.published = published;
        this.updatedAt = LocalDateTime.now();
    }

    public void addSubtopic(PreparationSubtopic subtopic) {
        subtopic.setTopic(this);
        subtopics.add(subtopic);
    }

    public void removeSubtopic(PreparationSubtopic subtopic) {
        subtopics.remove(subtopic);
    }

    public void addResource(PreparationResource resource) {
        resource.setTopic(this);
        resources.add(resource);
    }

    public void removeResource(PreparationResource resource) {
        resources.remove(resource);
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    public Long getId() { return id; }
    public PreparationCategory getCategory() { return category; }
    public String getTitle() { return title; }
    public String getSlug() { return slug; }
    public String getIntroduction() { return introduction; }
    public String getExplanation() { return explanation; }
    public String getCodeExamples() { return codeExamples; }
    public String getPracticalExamples() { return practicalExamples; }
    public String getReferenceLinks() { return referenceLinks; }
    public boolean isPublished() { return published; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public List<PreparationSubtopic> getSubtopics() { return subtopics; }
    public List<PreparationResource> getResources() { return resources; }
}
