package career.vault.mocktests;

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
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

@Entity
@Table(name = "test_questions", indexes = {
        @Index(name = "idx_test_questions_test", columnList = "test_id")
})
public class TestQuestion {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "test_id", nullable = false)
    private PracticeTest test;

    @NotBlank
    @Size(max = 4000)
    @Column(nullable = false, columnDefinition = "TEXT")
    private String question;

    @NotBlank @Size(max = 1000) @Column(nullable = false, length = 1000)
    private String optionA;
    @NotBlank @Size(max = 1000) @Column(nullable = false, length = 1000)
    private String optionB;
    @NotBlank @Size(max = 1000) @Column(nullable = false, length = 1000)
    private String optionC;
    @NotBlank @Size(max = 1000) @Column(nullable = false, length = 1000)
    private String optionD;

    @NotNull
    @Column(nullable = false)
    private Integer correctOption;

    @NotNull @DecimalMin("0.01")
    @Column(nullable = false, precision = 8, scale = 2)
    private BigDecimal marks;

    @Size(max = 5000)
    @Column(columnDefinition = "TEXT")
    private String explanation;

    protected TestQuestion() {
    }

    public static TestQuestion create(QuestionInput input) {
        TestQuestion question = new TestQuestion();
        question.apply(input);
        return question;
    }

    public void apply(QuestionInput input) {
        if (input.correctOption() < 0 || input.correctOption() > 3) {
            throw new IllegalArgumentException("The correct answer must be one of the four options.");
        }
        question = input.question().trim();
        optionA = input.options().get(0).trim();
        optionB = input.options().get(1).trim();
        optionC = input.options().get(2).trim();
        optionD = input.options().get(3).trim();
        correctOption = input.correctOption();
        marks = input.marks();
        explanation = input.explanation() == null ? null : input.explanation().trim();
    }

    public void setTest(PracticeTest test) { this.test = test; }
    public Long getId() { return id; }
    public String getQuestion() { return question; }
    public List<String> options() { return List.of(optionA, optionB, optionC, optionD); }
    public Integer getCorrectOption() { return correctOption; }
    public BigDecimal getMarks() { return marks; }
    public String getExplanation() { return explanation; }
}
