package career.vault.mocktests;

import career.vault.accounts.CurrentAccount;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class PracticeTestController {
    private final PracticeTestService service;

    public PracticeTestController(PracticeTestService service) {
        this.service = service;
    }

    @GetMapping("/test-categories")
    public List<PracticeTestViews.CategoryView> categories() {
        return service.categories();
    }

    @GetMapping("/tests")
    public List<PracticeTestViews.TestSummary> publicTests() {
        return service.publicTests();
    }

    @GetMapping("/tests/{id}")
    public PracticeTestViews.TestSummary publicTest(@PathVariable long id) {
        return service.publicTest(id);
    }

    @GetMapping("/daily-quiz")
    public ResponseEntity<PracticeTestViews.TestSummary> latestDailyQuiz() {
        PracticeTestViews.TestSummary quiz = service.latestDailyQuiz();
        return quiz == null ? ResponseEntity.noContent().build() : ResponseEntity.ok(quiz);
    }

    @PostMapping("/tests/{id}/attempts")
    public PracticeTestViews.AttemptStart start(
            @PathVariable long id) {
        return service.start(id, CurrentAccount.require().id());
    }

    @PostMapping("/test-attempts/{attemptId}/submit")
    public PracticeTestViews.AttemptResult submit(
            @PathVariable String attemptId,
            @Valid @RequestBody AnswerInput input) {
        return service.submit(attemptId, CurrentAccount.require().id(),
                input == null ? Map.of() : input.answers());
    }

    @GetMapping("/test-attempts/history")
    public List<PracticeTestViews.AttemptResult> history() {
        return service.history(CurrentAccount.require().id());
    }

    @GetMapping("/test-attempts/{attemptId}")
    public PracticeTestViews.AttemptResult result(
            @PathVariable String attemptId) {
        return service.result(attemptId, CurrentAccount.require().id());
    }

    @GetMapping("/admin/tests")
    public List<PracticeTestViews.TestSummary> adminTests() {
        return service.adminTests();
    }

    @GetMapping("/admin/tests/{id}")
    public PracticeTestViews.AdminTest adminTest(@PathVariable long id) {
        return service.adminTest(id);
    }

    @PostMapping("/admin/tests")
    public PracticeTestViews.AdminTest create(@Valid @RequestBody PracticeTestInput input) {
        return service.create(input);
    }

    @PutMapping("/admin/tests/{id}")
    public PracticeTestViews.AdminTest update(
            @PathVariable long id, @Valid @RequestBody PracticeTestInput input) {
        return service.update(id, input);
    }

    @PutMapping("/admin/tests/{id}/status")
    public PracticeTestViews.AdminTest setStatus(
            @PathVariable long id, @RequestBody Map<String, TestStatus> request) {
        TestStatus status = request.get("status");
        if (status == null) {
            throw new IllegalArgumentException("Status must be DRAFT or PUBLISHED.");
        }
        return service.setStatus(id, status);
    }

    @DeleteMapping("/admin/tests/{id}")
    public ResponseEntity<Void> delete(@PathVariable long id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/admin/tests/{id}/questions")
    public PracticeTestViews.AdminQuestion addQuestion(
            @PathVariable long id, @Valid @RequestBody QuestionInput input) {
        return service.addQuestion(id, input);
    }

    @PutMapping("/admin/tests/{id}/questions/{questionId}")
    public PracticeTestViews.AdminQuestion updateQuestion(
            @PathVariable long id, @PathVariable long questionId,
            @Valid @RequestBody QuestionInput input) {
        return service.updateQuestion(id, questionId, input);
    }

    @DeleteMapping("/admin/tests/{id}/questions/{questionId}")
    public ResponseEntity<Void> deleteQuestion(
            @PathVariable long id, @PathVariable long questionId) {
        service.deleteQuestion(id, questionId);
        return ResponseEntity.noContent().build();
    }

}
