package career.vault.access;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;

public record AccessSettingInput(
        @NotNull
        @Pattern(regexp = "^[A-Z_]{1,50}$")
        String key,
        @NotNull AccessMode mode
) {
}
