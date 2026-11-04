package career.vault.jobs;

import career.vault.preparation.PreparationNotFoundException;
import career.vault.interview.InterviewNotFoundException;
import career.vault.courses.CourseNotFoundException;
import career.vault.mocktests.PracticeTestNotFoundException;
import career.vault.mocktests.TestAttemptNotFoundException;
import career.vault.guidance.GuidanceArticleNotFoundException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

@RestControllerAdvice
public class JobExceptionHandler {
    @ExceptionHandler(JobNotFoundException.class)
    public ResponseEntity<Map<String, String>> notFound(JobNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler(PreparationNotFoundException.class)
    public ResponseEntity<Map<String, String>> preparationNotFound(PreparationNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler(InterviewNotFoundException.class)
    public ResponseEntity<Map<String, String>> interviewNotFound(InterviewNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler(CourseNotFoundException.class)
    public ResponseEntity<Map<String, String>> courseNotFound(CourseNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler({PracticeTestNotFoundException.class, TestAttemptNotFoundException.class})
    public ResponseEntity<Map<String, String>> testNotFound(RuntimeException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler(GuidanceArticleNotFoundException.class)
    public ResponseEntity<Map<String, String>> guidanceNotFound(
            GuidanceArticleNotFoundException exception) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler({DuplicateJobException.class, IllegalArgumentException.class})
    public ResponseEntity<Map<String, String>> badRequest(RuntimeException exception) {
        return ResponseEntity.badRequest().body(Map.of("error", exception.getMessage()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, String>> invalidInput(MethodArgumentNotValidException exception) {
        String message = exception.getBindingResult().getFieldErrors().stream()
                .map(error -> error.getField() + ": " + error.getDefaultMessage())
                .findFirst().orElse("Invalid request details.");
        return ResponseEntity.badRequest().body(Map.of("error", message));
    }
}
