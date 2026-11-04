package career.vault.guidance;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record GuidanceArticleInput(
        @NotBlank @Size(max = 180) String title,
        @NotNull GuidanceCategory category,
        @NotBlank @Size(max = 1000) String shortDescription,
        @NotBlank @Size(max = 50000) String content,
        @NotNull GuidanceStatus status
) {
}
