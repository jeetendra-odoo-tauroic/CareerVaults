package career.vault.mocktests;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "practice_tests", indexes = {
        @Index(name = "idx_practice_tests_publication", columnList = "status, created_at"),
        @Index(name = "idx_practice_tests_kind", columnList = "kind, status, created_at")
})
public class PracticeTest {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank
    @Size(max = 180)
    @Column(nullable = false, length = 180)
    private String title;

    @NotBlank
    @Size(max = 5000)
    @Column(nullable = false, columnDefinition = "TEXT")
    private String description;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private TestCategory category;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TestKind kind;

    @NotNull
    @DecimalMin("1")
    @DecimalMax("600")
    @Column(nullable = false)
    private Integer durationMinutes;

    @NotNull
    @DecimalMin("0.00")
    @DecimalMax("100.00")
    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal negativeMarking;

    @DecimalMin("0.00")
    @DecimalMax("100.00")
    @Column(precision = 5, scale = 2)
    private BigDecimal passingPercentage;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private TestStatus status = TestStatus.DRAFT;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private LocalDateTime updatedAt;

    @OneToMany(mappedBy = "test", cascade = CascadeType.ALL, orphanRemoval = true,
            fetch = FetchType.LAZY)
    @OrderBy("id ASC")
    private List<TestQuestion> questions = new ArrayList<>();

    protected PracticeTest() {
    }

    public void initialize(PracticeTestInput input) {
        apply(input);
        createdAt = LocalDateTime.now();
    }

    public void apply(PracticeTestInput input) {
        title = input.title().trim();
        description = input.description().trim();
        category = input.category();
        kind = input.kind();
        durationMinutes = input.durationMinutes();
        negativeMarking = input.negativeMarking() == null
                ? BigDecimal.ZERO : input.negativeMarking();
        passingPercentage = input.passingPercentage();
        status = input.status();
        updatedAt = LocalDateTime.now();
    }

    public void addQuestion(TestQuestion question) {
        question.setTest(this);
        questions.add(question);
        updatedAt = LocalDateTime.now();
    }

    public void removeQuestion(TestQuestion question) {
        questions.remove(question);
        question.setTest(null);
        updatedAt = LocalDateTime.now();
    }

    public void setStatus(TestStatus status) {
        this.status = status;
        updatedAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public String getTitle() { return title; }
    public String getDescription() { return description; }
    public TestCategory getCategory() { return category; }
    public TestKind getKind() { return kind; }
    public Integer getDurationMinutes() { return durationMinutes; }
    public BigDecimal getNegativeMarking() { return negativeMarking; }
    public BigDecimal getPassingPercentage() { return passingPercentage; }
    public TestStatus getStatus() { return status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public List<TestQuestion> getQuestions() { return questions; }
}
