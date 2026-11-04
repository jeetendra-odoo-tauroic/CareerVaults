package career.vault.interview;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record InterviewCategoryInput(
        @NotBlank @Size(max = 100) String name,
        @Size(max = 1000) String description,
        boolean published
) {
}
