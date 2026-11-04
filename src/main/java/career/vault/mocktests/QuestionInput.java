package career.vault.mocktests;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.util.List;

public record QuestionInput(
        @NotBlank @Size(max = 4000) String question,
        @NotNull @Size(min = 4, max = 4) List<@NotBlank @Size(max = 1000) String> options,
        @NotNull Integer correctOption,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 6, fraction = 2) BigDecimal marks,
        @Size(max = 5000) String explanation
) {
}
