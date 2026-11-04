package career.vault.accounts;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ProfileInput(
        @NotBlank @Size(max = 160) String fullName,
        @Size(max = 30)
        @Pattern(regexp = "^$|^[+0-9() .-]{7,30}$", message = "Enter a valid mobile number.")
        String mobileNumber
) {
}
