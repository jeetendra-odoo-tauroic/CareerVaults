package career.vault.mocktests;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "test_attempts", indexes = {
        @Index(name = "idx_attempts_guest_submitted", columnList = "guest_id, submitted_at"),
        @Index(name = "idx_attempts_owner_submitted", columnList = "owner_id, submitted_at"),
        @Index(name = "idx_attempts_test", columnList = "test_id")
})
public class TestAttempt {
    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false, length = 36)
    private String guestId;

    @Column(length = 36)
    private String ownerId;

    @Column(nullable = false)
    private Long testId;

    @Column(nullable = false, length = 180)
    private String testTitle;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AttemptStatus status;

    @Column(nullable = false)
    private Integer durationMinutes;

    @Column(nullable = false, precision = 5, scale = 2)
    private BigDecimal negativeMarking;

    @Column(precision = 5, scale = 2)
    private BigDecimal passingPercentage;

    @Column(nullable = false)
    private Instant startedAt;

    private Instant submittedAt;
    private Integer timeTakenSeconds;
    private Integer attemptedCount;
    private Integer correctCount;
    private Integer incorrectCount;
    private Integer unansweredCount;

    @Column(precision = 10, scale = 2)
    private BigDecimal totalMarks;

    @Column(precision = 10, scale = 2)
    private BigDecimal marksObtained;

    @Column(precision = 7, scale = 2)
    private BigDecimal percentage;

    private Boolean passed;

    @OneToMany(mappedBy = "attempt", cascade = CascadeType.ALL,
            orphanRemoval = true, fetch = FetchType.LAZY)
    @OrderBy("id ASC")
    private List<TestAttemptQuestion> questions = new ArrayList<>();

    protected TestAttempt() {
    }

    public TestAttempt(String id, String guestId, PracticeTest test) {
        this.id = id;
        this.guestId = guestId;
        this.ownerId = guestId;
        testId = test.getId();
        testTitle = test.getTitle();
        status = AttemptStatus.IN_PROGRESS;
        durationMinutes = test.getDurationMinutes();
        negativeMarking = test.getNegativeMarking();
        passingPercentage = test.getPassingPercentage();
        startedAt = Instant.now();
        for (TestQuestion question : test.getQuestions()) {
            addQuestion(new TestAttemptQuestion(question));
        }
    }

    public void addQuestion(TestAttemptQuestion question) {
        question.setAttempt(this);
        questions.add(question);
    }

    public void submit(Instant now, int timeTakenSeconds, int attemptedCount,
                       int correctCount, int incorrectCount, int unansweredCount,
                       BigDecimal totalMarks, BigDecimal marksObtained,
                       BigDecimal percentage) {
        if (status == AttemptStatus.SUBMITTED) return;
        status = AttemptStatus.SUBMITTED;
        submittedAt = now;
        this.timeTakenSeconds = timeTakenSeconds;
        this.attemptedCount = attemptedCount;
        this.correctCount = correctCount;
        this.incorrectCount = incorrectCount;
        this.unansweredCount = unansweredCount;
        this.totalMarks = totalMarks;
        this.marksObtained = marksObtained;
        this.percentage = percentage;
        passed = passingPercentage == null ? null : percentage.compareTo(passingPercentage) >= 0;
    }

    public String getId() { return id; }
    public String getGuestId() { return guestId; }
    public String getOwnerId() { return ownerId; }
    public Long getTestId() { return testId; }
    public String getTestTitle() { return testTitle; }
    public AttemptStatus getStatus() { return status; }
    public Integer getDurationMinutes() { return durationMinutes; }
    public BigDecimal getNegativeMarking() { return negativeMarking; }
    public BigDecimal getPassingPercentage() { return passingPercentage; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getSubmittedAt() { return submittedAt; }
    public Integer getTimeTakenSeconds() { return timeTakenSeconds; }
    public Integer getAttemptedCount() { return attemptedCount; }
    public Integer getCorrectCount() { return correctCount; }
    public Integer getIncorrectCount() { return incorrectCount; }
    public Integer getUnansweredCount() { return unansweredCount; }
    public BigDecimal getTotalMarks() { return totalMarks; }
    public BigDecimal getMarksObtained() { return marksObtained; }
    public BigDecimal getPercentage() { return percentage; }
    public Boolean getPassed() { return passed; }
    public List<TestAttemptQuestion> getQuestions() { return questions; }
}
