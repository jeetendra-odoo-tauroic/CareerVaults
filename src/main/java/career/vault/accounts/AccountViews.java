package career.vault.accounts;

import java.time.Instant;

public final class AccountViews {
    private AccountViews() {
    }

    public record UserView(String id, String fullName, String email, String mobileNumber,
                           AccountRole role, boolean active, Instant registeredAt) {
        static UserView from(UserAccount user) {
            return new UserView(user.getId(), user.getFullName(), user.getEmail(),
                    user.getMobileNumber(), user.getRole(), user.isActive(),
                    user.getRegisteredAt());
        }
    }

    public record AuthView(String token, UserView user) {
        static AuthView from(String token, UserAccount user) {
            return new AuthView(token, UserView.from(user));
        }
    }
}
