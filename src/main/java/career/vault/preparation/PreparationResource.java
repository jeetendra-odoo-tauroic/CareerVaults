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

import java.time.LocalDateTime;

@Entity
@Table(name = "preparation_resources")
public class PreparationResource {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "topic_id", nullable = false)
    private PreparationTopic topic;

    @NotBlank
    @Size(max = 255)
    @Column(nullable = false)
    private String originalName;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false, length = 100)
    private String storageName;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false, length = 100)
    private String contentType;

    @NotBlank
    @Size(max = 20)
    @Column(nullable = false, length = 20)
    private String kind;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected PreparationResource() {
    }

    public void initialize(String originalName, String storageName, String contentType, String kind) {
        this.originalName = originalName;
        this.storageName = storageName;
        this.contentType = contentType;
        this.kind = kind;
        this.createdAt = LocalDateTime.now();
    }

    void setTopic(PreparationTopic topic) {
        this.topic = topic;
    }

    public Long getId() { return id; }
    public String getOriginalName() { return originalName; }
    public String getStorageName() { return storageName; }
    public String getContentType() { return contentType; }
    public String getKind() { return kind; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public Long getTopicId() { return topic.getId(); }
}
