package career.vault.preparation;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

@Entity
@Table(name = "preparation_subtopics")
public class PreparationSubtopic {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "topic_id", nullable = false)
    private PreparationTopic topic;

    @NotBlank
    @Size(max = 180)
    @Column(nullable = false, length = 180)
    private String title;

    @Size(max = 200)
    @Column(nullable = false, length = 200)
    private String slug;

    @Column(columnDefinition = "TEXT")
    private String content;

    @Column(nullable = false)
    private int sortOrder;

    protected PreparationSubtopic() {
    }

    public void initialize(String title, String content, int sortOrder) {
        this.title = title.trim();
        this.slug = PreparationSlugs.from(title);
        this.content = content == null || content.isBlank() ? null : content.trim();
        this.sortOrder = sortOrder;
    }

    public void update(String title, String content, int sortOrder) {
        initialize(title, content, sortOrder);
    }

    void setTopic(PreparationTopic topic) {
        this.topic = topic;
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getSlug() { return slug; }
    public String getContent() { return content; }
    public int getSortOrder() { return sortOrder; }
}
