package career.vault.mocktests;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;

import java.math.BigDecimal;
import java.util.List;

@Entity
@Table(name = "test_attempt_questions")
public class TestAttemptQuestion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "attempt_id", nullable = false)
    private TestAttempt attempt;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String question;

    @Column(nullable = false, length = 1000)
    private String optionA;
    @Column(nullable = false, length = 1000)
    private String optionB;
    @Column(nullable = false, length = 1000)
    private String optionC;
    @Column(nullable = false, length = 1000)
    private String optionD;

    @Column(nullable = false)
    private Integer correctOption;

    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal marks;

    @Column(precision = 8, scale = 2)
    private BigDecimal marksAwarded;

    @Column(columnDefinition = "TEXT")
    private String explanation;

    private Integer selectedOption;
    private Boolean correct;

    protected TestAttemptQuestion() {
    }

    public TestAttemptQuestion(TestQuestion source) {
        question = source.getQuestion();
        List<String> options = source.options();
        optionA = options.get(0);
        optionB = options.get(1);
        optionC = options.get(2);
        optionD = options.get(3);
        correctOption = source.getCorrectOption();
        marks = source.getMarks();
        explanation = source.getExplanation();
    }

    public void setAttempt(TestAttempt attempt) { this.attempt = attempt; }

    public void evaluate(Integer selectedOption, BigDecimal negativeMarking) {
        this.selectedOption = selectedOption;
        if (selectedOption == null) {
            correct = null;
            marksAwarded = BigDecimal.ZERO.setScale(2);
        } else if (selectedOption.equals(correctOption)) {
            correct = true;
            marksAwarded = marks;
        } else {
            correct = false;
            marksAwarded = negativeMarking.negate();
        }
    }

    public Long getId() { return id; }
    public String getQuestion() { return question; }
    public List<String> options() { return List.of(optionA, optionB, optionC, optionD); }
    public Integer getCorrectOption() { return correctOption; }
    public BigDecimal getMarks() { return marks; }
    public BigDecimal getMarksAwarded() { return marksAwarded; }
    public String getExplanation() { return explanation; }
    public Integer getSelectedOption() { return selectedOption; }
    public Boolean getCorrect() { return correct; }
}
