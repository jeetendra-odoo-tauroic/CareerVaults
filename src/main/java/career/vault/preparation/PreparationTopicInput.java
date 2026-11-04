package career.vault.preparation;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

public record PreparationTopicInput(
        @NotNull Long categoryId,
        @NotBlank @Size(max = 180) String title,
        @NotBlank @Size(max = 1000) String introduction,
        @NotBlank String explanation,
        String codeExamples,
        String practicalExamples,
        String referenceLinks,
        boolean published,
        List<@Valid PreparationSubtopicInput> subtopics
) {
}
