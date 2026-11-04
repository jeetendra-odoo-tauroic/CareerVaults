package career.vault.jobs;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record JobInput(
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 200) String organisation,
        @Size(max = 100) String advertisementNumber,
        @NotBlank @Size(max = 100) String category,
        @NotBlank @Size(max = 100) String experienceLevel,
        @Size(max = 500) String qualification,
        @Size(max = 200) String salary,
        @Size(max = 200) String location,
        @NotNull LocalDate applicationStartDate,
        @NotNull LocalDate closingDate,
        String description,
        @Size(max = 2048) String applicationUrl
) {
}
