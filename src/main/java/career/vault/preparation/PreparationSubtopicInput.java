package career.vault.preparation;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PreparationSubtopicInput(
        @NotBlank @Size(max = 180) String title,
        String content,
        int sortOrder
) {
}
