package career.vault.accounts;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api")
public class AccountController {
    private final AccountService accounts;

    public AccountController(AccountService accounts) {
        this.accounts = accounts;
    }

    @PostMapping("/auth/register")
    public ResponseEntity<AccountViews.UserView> register(
            @Valid @RequestBody RegistrationInput input) {
        return ResponseEntity.status(HttpStatus.CREATED).body(accounts.register(input));
    }

    @PostMapping("/auth/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginInput input) {
        try {
            return ResponseEntity.ok(accounts.login(input));
        } catch (AccountService.InvalidCredentialsException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(Map.of("error", exception.getMessage()));
        }
    }

    @GetMapping("/auth/me")
    public AccountViews.UserView currentUser() {
        return accounts.profile(CurrentAccount.require());
    }

    @PostMapping("/auth/logout")
    public ResponseEntity<Void> logout() {
        accounts.logout(CurrentAccount.require());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/account/profile")
    public AccountViews.UserView profile() {
        return accounts.profile(CurrentAccount.require());
    }

    @PutMapping("/account/profile")
    public AccountViews.UserView updateProfile(@Valid @RequestBody ProfileInput input) {
        return accounts.updateProfile(CurrentAccount.require(), input);
    }

    @PostMapping("/account/password")
    public ResponseEntity<Void> changePassword(@Valid @RequestBody PasswordChangeInput input) {
        accounts.changePassword(CurrentAccount.require(), input);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/admin/users")
    public List<AccountViews.UserView> users(@RequestParam(required = false) String search) {
        return accounts.users(search);
    }

    @PutMapping("/admin/users/{id}/activation")
    public AccountViews.UserView setActivation(
            @org.springframework.web.bind.annotation.PathVariable String id,
            @RequestBody Map<String, Boolean> request) {
        Boolean active = request.get("active");
        if (active == null) throw new IllegalArgumentException("The active field is required.");
        return accounts.setActive(id, active, CurrentAccount.require());
    }
}
