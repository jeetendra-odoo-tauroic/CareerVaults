package career.vault.accounts;

import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AccountService {
    private final UserAccountRepository users;
    private final PasswordEncoder passwordEncoder;
    private final AuthTokenService tokens;

    public AccountService(UserAccountRepository users, PasswordEncoder passwordEncoder,
                         AuthTokenService tokens) {
        this.users = users;
        this.passwordEncoder = passwordEncoder;
        this.tokens = tokens;
    }

    @Transactional
    public AccountViews.UserView register(RegistrationInput input) {
        if (!input.password().equals(input.confirmPassword())) {
            throw new IllegalArgumentException("Password and confirmation do not match.");
        }
        String email = UserAccount.normalizeEmail(input.email());
        if (users.findByEmail(email).isPresent()) {
            throw new IllegalArgumentException("An account with this email already exists.");
        }
        UserAccount user = UserAccount.student(input.fullName(), email,
                passwordEncoder.encode(input.password()));
        return AccountViews.UserView.from(users.save(user));
    }

    @Transactional(readOnly = true)
    public AccountViews.AuthView login(LoginInput input) {
        UserAccount user = users.findByEmail(UserAccount.normalizeEmail(input.email()))
                .orElseThrow(() -> new InvalidCredentialsException());
        if (!user.isActive()) throw new InvalidCredentialsException();
        if (!passwordEncoder.matches(input.password(), user.getPasswordHash())) {
            throw new InvalidCredentialsException();
        }
        return AccountViews.AuthView.from(tokens.issue(user), user);
    }

    @Transactional(readOnly = true)
    public AccountViews.UserView profile(AuthenticatedUser principal) {
        return AccountViews.UserView.from(findUser(principal.id()));
    }

    @Transactional
    public AccountViews.UserView updateProfile(AuthenticatedUser principal, ProfileInput input) {
        UserAccount user = findUser(principal.id());
        user.updateProfile(input.fullName(), input.mobileNumber());
        return AccountViews.UserView.from(user);
    }

    @Transactional
    public void changePassword(AuthenticatedUser principal, PasswordChangeInput input) {
        UserAccount user = findUser(principal.id());
        if (!passwordEncoder.matches(input.currentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect.");
        }
        if (!input.newPassword().equals(input.confirmNewPassword())) {
            throw new IllegalArgumentException("New password and confirmation do not match.");
        }
        if (passwordEncoder.matches(input.newPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Choose a password different from your current password.");
        }
        user.changePassword(passwordEncoder.encode(input.newPassword()));
    }

    @Transactional
    public void logout(AuthenticatedUser principal) {
        findUser(principal.id()).invalidateTokens();
    }

    @Transactional(readOnly = true)
    public List<AccountViews.UserView> users(String search) {
        String query = search == null ? "" : search.trim();
        List<UserAccount> results = query.isEmpty()
                ? users.findAllByOrderByRegisteredAtDesc()
                : users.findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByRegisteredAtDesc(
                        query, query);
        return results.stream().map(AccountViews.UserView::from).toList();
    }

    @Transactional
    public AccountViews.UserView setActive(String id, boolean active, AuthenticatedUser actor) {
        UserAccount user = findUser(id);
        if (!active && user.getId().equals(actor.id())) {
            throw new IllegalArgumentException("You cannot deactivate your own administrator account.");
        }
        if (!active && user.getRole() == AccountRole.ADMIN && user.isActive()
                && users.countByRoleAndActiveTrue(AccountRole.ADMIN) <= 1) {
            throw new IllegalArgumentException("The last active administrator cannot be deactivated.");
        }
        user.setActive(active);
        return AccountViews.UserView.from(user);
    }

    private UserAccount findUser(String id) {
        return users.findById(id).orElseThrow(() -> new IllegalArgumentException("Account not found."));
    }

    public static final class InvalidCredentialsException extends RuntimeException {
        public InvalidCredentialsException() {
            super("Email or password is incorrect, or the account is inactive.");
        }
    }
}
