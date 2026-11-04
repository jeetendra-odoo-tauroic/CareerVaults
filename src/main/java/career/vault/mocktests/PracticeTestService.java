package career.vault.mocktests;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Service
public class PracticeTestService {
    private static final int SUBMISSION_GRACE_SECONDS = 2;
    private final PracticeTestRepository tests;
    private final TestAttemptRepository attempts;

    public PracticeTestService(PracticeTestRepository tests, TestAttemptRepository attempts) {
        this.tests = tests;
        this.attempts = attempts;
    }

    @Transactional(readOnly = true)
    public List<PracticeTestViews.CategoryView> categories() {
        return java.util.Arrays.stream(TestCategory.values())
                .map(PracticeTestViews.CategoryView::from).toList();
    }

    @Transactional(readOnly = true)
    public List<PracticeTestViews.TestSummary> publicTests() {
        return tests.findByStatusOrderByCreatedAtDesc(TestStatus.PUBLISHED).stream()
                .filter(test -> !test.getQuestions().isEmpty())
                .map(PracticeTestViews.TestSummary::from).toList();
    }

    @Transactional(readOnly = true)
    public PracticeTestViews.TestSummary latestDailyQuiz() {
        return tests.findByKindAndStatusOrderByCreatedAtDesc(
                        TestKind.DAILY_QUIZ, TestStatus.PUBLISHED).stream()
                .filter(test -> !test.getQuestions().isEmpty())
                .findFirst().map(PracticeTestViews.TestSummary::from).orElse(null);
    }

    @Transactional(readOnly = true)
    public PracticeTestViews.TestSummary publicTest(long id) {
        PracticeTest test = tests.findById(id)
                .filter(item -> item.getStatus() == TestStatus.PUBLISHED)
                .orElseThrow(() -> new PracticeTestNotFoundException(id));
        return PracticeTestViews.TestSummary.from(test);
    }

    @Transactional(readOnly = true)
    public List<PracticeTestViews.TestSummary> adminTests() {
        return tests.findAllByOrderByCreatedAtDesc().stream()
                .map(PracticeTestViews.TestSummary::from).toList();
    }

    @Transactional(readOnly = true)
    public PracticeTestViews.AdminTest adminTest(long id) {
        return PracticeTestViews.AdminTest.from(getTestWithQuestions(id));
    }

    @Transactional
    public PracticeTestViews.AdminTest create(PracticeTestInput input) {
        requireQuestionsForPublished(input.status(), List.of());
        PracticeTest test = new PracticeTest();
        test.initialize(input);
        return PracticeTestViews.AdminTest.from(tests.save(test));
    }

    @Transactional
    public PracticeTestViews.AdminTest update(long id, PracticeTestInput input) {
        PracticeTest test = getTestWithQuestions(id);
        requireQuestionsForPublished(input.status(), test.getQuestions());
        test.apply(input);
        return PracticeTestViews.AdminTest.from(tests.save(test));
    }

    @Transactional
    public PracticeTestViews.AdminTest setStatus(long id, TestStatus status) {
        PracticeTest test = getTestWithQuestions(id);
        requireQuestionsForPublished(status, test.getQuestions());
        test.setStatus(status);
        return PracticeTestViews.AdminTest.from(tests.save(test));
    }

    @Transactional
    public void delete(long id) {
        tests.delete(getTestWithQuestions(id));
    }

    @Transactional
    public PracticeTestViews.AdminQuestion addQuestion(long testId, QuestionInput input) {
        PracticeTest test = getTestWithQuestions(testId);
        TestQuestion question = TestQuestion.create(input);
        test.addQuestion(question);
        tests.save(test);
        return PracticeTestViews.AdminQuestion.from(question);
    }

    @Transactional
    public PracticeTestViews.AdminQuestion updateQuestion(
            long testId, long questionId, QuestionInput input) {
        TestQuestion question = findQuestion(getTestWithQuestions(testId), questionId);
        question.apply(input);
        return PracticeTestViews.AdminQuestion.from(question);
    }

    @Transactional
    public void deleteQuestion(long testId, long questionId) {
        PracticeTest test = getTestWithQuestions(testId);
        test.removeQuestion(findQuestion(test, questionId));
        if (test.getQuestions().isEmpty() && test.getStatus() == TestStatus.PUBLISHED) {
            test.setStatus(TestStatus.DRAFT);
        }
        tests.save(test);
    }

    @Transactional
    public PracticeTestViews.AttemptStart start(long testId, String ownerId) {
        PracticeTest test = tests.findWithQuestionsById(testId)
                .filter(item -> item.getStatus() == TestStatus.PUBLISHED)
                .orElseThrow(() -> new PracticeTestNotFoundException(testId));
        if (test.getQuestions().isEmpty()) {
            throw new IllegalArgumentException("This test does not have any questions yet.");
        }
        TestAttempt attempt = new TestAttempt(UUID.randomUUID().toString(), ownerId, test);
        return PracticeTestViews.AttemptStart.from(attempts.save(attempt));
    }

    @Transactional
    public PracticeTestViews.AttemptResult submit(
            String attemptId, String ownerId, Map<Long, Integer> answers) {
        TestAttempt attempt = attempts.findForSubmission(attemptId)
                .filter(value -> ownerId.equals(value.getOwnerId()))
                .orElseThrow(() -> new TestAttemptNotFoundException(attemptId));
        if (attempt.getStatus() == AttemptStatus.SUBMITTED) {
            return PracticeTestViews.AttemptResult.from(
                    attempts.findWithQuestionsById(attemptId).orElseThrow());
        }

        Map<Long, Integer> submitted = answers == null ? Map.of() : answers;
        for (Long questionId : submitted.keySet()) {
            if (attempt.getQuestions().stream().noneMatch(q -> q.getId().equals(questionId))) {
                throw new IllegalArgumentException("An answer refers to a question outside this test attempt.");
            }
        }

        Instant now = Instant.now();
        long elapsed = Math.max(0, Duration.between(attempt.getStartedAt(), now).getSeconds());
        long durationSeconds = attempt.getDurationMinutes() * 60L;
        boolean timedOut = elapsed > durationSeconds + SUBMISSION_GRACE_SECONDS;
        BigDecimal totalMarks = BigDecimal.ZERO;
        BigDecimal marksObtained = BigDecimal.ZERO;
        int attempted = 0;
        int correct = 0;
        int incorrect = 0;

        for (TestAttemptQuestion question : attempt.getQuestions()) {
            Integer selected = timedOut ? null : submitted.get(question.getId());
            question.evaluate(selected, attempt.getNegativeMarking());
            totalMarks = totalMarks.add(question.getMarks());
            marksObtained = marksObtained.add(question.getMarksAwarded());
            if (selected != null) {
                attempted++;
                if (Boolean.TRUE.equals(question.getCorrect())) correct++;
                else incorrect++;
            }
        }

        int unanswered = attempt.getQuestions().size() - attempted;
        BigDecimal percentage = totalMarks.signum() == 0 ? BigDecimal.ZERO
                : marksObtained.multiply(BigDecimal.valueOf(100))
                .divide(totalMarks, 2, RoundingMode.HALF_UP);
        attempt.submit(now, (int) Math.min(elapsed, durationSeconds), attempted, correct,
                incorrect, unanswered, totalMarks, marksObtained, percentage);
        return PracticeTestViews.AttemptResult.from(attempt);
    }

    @Transactional(readOnly = true)
    public List<PracticeTestViews.AttemptResult> history(String ownerId) {
        return attempts.findByOwnerIdAndStatusOrderBySubmittedAtDesc(
                        ownerId, AttemptStatus.SUBMITTED).stream()
                .map(PracticeTestViews.AttemptResult::from).toList();
    }

    @Transactional(readOnly = true)
    public PracticeTestViews.AttemptResult result(String attemptId, String ownerId) {
        TestAttempt attempt = attempts.findWithQuestionsById(attemptId)
                .filter(value -> ownerId.equals(value.getOwnerId())
                        && value.getStatus() == AttemptStatus.SUBMITTED)
                .orElseThrow(() -> new TestAttemptNotFoundException(attemptId));
        return PracticeTestViews.AttemptResult.from(attempt);
    }

    private PracticeTest getTestWithQuestions(long id) {
        return tests.findWithQuestionsById(id)
                .orElseThrow(() -> new PracticeTestNotFoundException(id));
    }

    private TestQuestion findQuestion(PracticeTest test, long questionId) {
        return test.getQuestions().stream()
                .filter(question -> question.getId().equals(questionId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Question " + questionId + " does not belong to test " + test.getId() + "."));
    }

    private void requireQuestionsForPublished(
            TestStatus status, List<TestQuestion> questions) {
        if (status == TestStatus.PUBLISHED && questions.isEmpty()) {
            throw new IllegalArgumentException("Add at least one question before publishing a test.");
        }
    }
}
