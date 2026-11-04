package career.vault.interview;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record InterviewTopicInput(
        @NotNull Long categoryId,
        @NotBlank @Size(max = 180) String title,
        @NotBlank @Size(max = 1000) String introduction,
        @NotBlank @Size(max = 100000) String article,
        @Size(max = 6) List<@NotBlank @Size(max = 32) String> experienceLevels,
        boolean published
) {
}
