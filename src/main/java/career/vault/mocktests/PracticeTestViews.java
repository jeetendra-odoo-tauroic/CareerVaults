package career.vault.mocktests;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.List;

public final class PracticeTestViews {
    private PracticeTestViews() {
    }

    public record CategoryView(String code, String label, String group) {
        static CategoryView from(TestCategory category) {
            return new CategoryView(category.name(), category.label(), category.group());
        }
    }

    public record TestSummary(Long id, String title, String description,
                              TestCategory category, String categoryLabel, TestKind kind,
                              Integer durationMinutes, BigDecimal negativeMarking,
                              BigDecimal passingPercentage, TestStatus status,
                              int questionCount, BigDecimal totalMarks,
                              LocalDateTime createdAt) {
        static TestSummary from(PracticeTest test) {
            return new TestSummary(test.getId(), test.getTitle(), test.getDescription(),
                    test.getCategory(), test.getCategory().label(), test.getKind(),
                    test.getDurationMinutes(), test.getNegativeMarking(),
                    test.getPassingPercentage(), test.getStatus(), test.getQuestions().size(),
                    aggregateMarks(test.getQuestions()), test.getCreatedAt());
        }
    }

    public record AdminQuestion(Long id, String question, List<String> options,
                                Integer correctOption, BigDecimal marks,
                                String explanation) {
        static AdminQuestion from(TestQuestion question) {
            return new AdminQuestion(question.getId(), question.getQuestion(),
                    question.options(), question.getCorrectOption(), question.getMarks(),
                    question.getExplanation());
        }
    }

    public record AdminTest(TestSummary test, List<AdminQuestion> questions) {
        static AdminTest from(PracticeTest test) {
            return new AdminTest(TestSummary.from(test),
                    test.getQuestions().stream().map(AdminQuestion::from).toList());
        }
    }

    public record AttemptQuestion(Long id, String question, List<String> options) {
        static AttemptQuestion from(TestAttemptQuestion question) {
            return new AttemptQuestion(question.getId(), question.getQuestion(), question.options());
        }
    }

    public record AttemptStart(String attemptId, String testTitle, int durationMinutes,
                               Instant startedAt, List<AttemptQuestion> questions) {
        static AttemptStart from(TestAttempt attempt) {
            return new AttemptStart(attempt.getId(), attempt.getTestTitle(),
                    attempt.getDurationMinutes(), attempt.getStartedAt(),
                    attempt.getQuestions().stream().map(AttemptQuestion::from).toList());
        }
    }

    public record ResultQuestion(Long id, String question, List<String> options,
                                 Integer selectedOption, int correctOption,
                                 Boolean correct, BigDecimal marksAwarded,
                                 String explanation) {
        static ResultQuestion from(TestAttemptQuestion question) {
            return new ResultQuestion(question.getId(), question.getQuestion(),
                    question.options(), question.getSelectedOption(), question.getCorrectOption(),
                    question.getCorrect(), question.getMarksAwarded(),
                    question.getExplanation());
        }
    }

    public record AttemptResult(String attemptId, Long testId, String testTitle,
                                int totalQuestions, int attemptedQuestions, int correctAnswers,
                                int incorrectAnswers, int unansweredQuestions,
                                BigDecimal totalMarks, BigDecimal marksObtained,
                                BigDecimal percentage, Integer timeTakenSeconds,
                                BigDecimal passingPercentage, Boolean passed,
                                Instant submittedAt, List<ResultQuestion> questions) {
        static AttemptResult from(TestAttempt attempt) {
            return new AttemptResult(attempt.getId(), attempt.getTestId(), attempt.getTestTitle(),
                    attempt.getQuestions().size(), attempt.getAttemptedCount(),
                    attempt.getCorrectCount(), attempt.getIncorrectCount(),
                    attempt.getUnansweredCount(), attempt.getTotalMarks(),
                    attempt.getMarksObtained(), attempt.getPercentage(),
                    attempt.getTimeTakenSeconds(), attempt.getPassingPercentage(),
                    attempt.getPassed(), attempt.getSubmittedAt(),
                    attempt.getQuestions().stream().map(ResultQuestion::from).toList());
        }
    }

    private static BigDecimal aggregateMarks(List<TestQuestion> questions) {
        return questions.stream().map(TestQuestion::getMarks)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
    }
}
