package career.vault.mocktests;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;

import java.util.Map;

public record AnswerInput(Map<Long, @Min(0) @Max(3) Integer> answers) {
}
