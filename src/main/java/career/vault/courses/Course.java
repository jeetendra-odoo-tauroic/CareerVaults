package career.vault.courses;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "courses", indexes = {
        @Index(name = "idx_courses_status_created", columnList = "status, created_at")
})
public class Course {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 180)
    @Column(nullable = false, length = 180)
    private String name;

    @NotBlank
    @Size(max = 100)
    @Column(nullable = false, length = 100)
    private String category;

    @NotBlank
    @Size(max = 10000)
    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @NotNull
    @DecimalMin("0.00")
    @Digits(integer = 10, fraction = 2)
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private CourseStatus status = CourseStatus.UNPUBLISHED;

    @Size(max = 100)
    private String imageFileName;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    protected Course() {
    }

    public void initialize(CourseInput input) {
        apply(input);
        createdAt = LocalDateTime.now();
        updatedAt = createdAt;
    }

    public void apply(CourseInput input) {
        name = input.name().trim();
        category = input.category().trim();
        description = input.description().trim();
        price = input.price().setScale(2);
        status = input.status();
        updatedAt = LocalDateTime.now();
    }

    public void setStatus(CourseStatus status) {
        this.status = status;
        updatedAt = LocalDateTime.now();
    }

    public void setImageFileName(String imageFileName) {
        this.imageFileName = imageFileName;
        updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public String getName() { return name; }
    public String getCategory() { return category; }
    public String getDescription() { return description; }
    public BigDecimal getPrice() { return price; }
    public CourseStatus getStatus() { return status; }
    public String getImageFileName() { return imageFileName; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
}
