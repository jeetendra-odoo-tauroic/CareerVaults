package career.vault.mocktests;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record PracticeTestInput(
        @NotBlank @Size(max = 180) String title,
        @NotBlank @Size(max = 5000) String description,
        @NotNull TestCategory category,
        @NotNull TestKind kind,
        @NotNull @DecimalMin("1") @DecimalMax("600") Integer durationMinutes,
        @DecimalMin("0.00") @DecimalMax("100.00")
        @Digits(integer = 3, fraction = 2) BigDecimal negativeMarking,
        @DecimalMin("0.00") @DecimalMax("100.00")
        @Digits(integer = 3, fraction = 2) BigDecimal passingPercentage,
        @NotNull TestStatus status
) {
}
