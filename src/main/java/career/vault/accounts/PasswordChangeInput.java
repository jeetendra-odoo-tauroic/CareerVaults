package career.vault.accounts;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PasswordChangeInput(
        @NotBlank String currentPassword,
        @NotBlank @Size(min = 8, max = 72) String newPassword,
        @NotBlank String confirmNewPassword
) {
}
