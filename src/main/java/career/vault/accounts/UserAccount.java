package career.vault.accounts;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.Table;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "user_accounts", indexes = {
        @Index(name = "idx_user_accounts_registered", columnList = "registered_at")
})
public class UserAccount {
    @Id
    @Column(length = 36)
    private String id;

    @NotBlank
    @Size(max = 160)
    @Column(nullable = false, length = 160)
    private String fullName;

    @Email
    @NotBlank
    @Size(max = 254)
    @Column(nullable = false, unique = true, length = 254)
    private String email;

    @NotBlank
    @Column(nullable = false, length = 100)
    private String passwordHash;

    @Size(max = 30)
    @Column(length = 30)
    private String mobileNumber;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 16)
    private AccountRole role;

    @Column(nullable = false)
    private boolean active = true;

    @Column(nullable = false)
    private Instant registeredAt;

    @Column(nullable = false)
    private int tokenVersion;

    protected UserAccount() {
    }

    public static UserAccount student(String fullName, String email, String passwordHash) {
        return create(fullName, email, passwordHash, AccountRole.STUDENT);
    }

    public static UserAccount administrator(String fullName, String email, String passwordHash) {
        return create(fullName, email, passwordHash, AccountRole.ADMIN);
    }

    private static UserAccount create(String fullName, String email,
                                      String passwordHash, AccountRole role) {
        UserAccount user = new UserAccount();
        user.id = UUID.randomUUID().toString();
        user.fullName = fullName.trim();
        user.email = normalizeEmail(email);
        user.passwordHash = passwordHash;
        user.role = role;
        user.active = true;
        user.registeredAt = Instant.now();
        user.tokenVersion = 0;
        return user;
    }

    public static String normalizeEmail(String email) {
        return email.trim().toLowerCase(java.util.Locale.ROOT);
    }

    public void updateProfile(String fullName, String mobileNumber) {
        this.fullName = fullName.trim();
        this.mobileNumber = mobileNumber == null || mobileNumber.isBlank()
                ? null : mobileNumber.trim();
    }

    public void changePassword(String encodedPassword) {
        passwordHash = encodedPassword;
        tokenVersion++;
    }

    public void invalidateTokens() {
        tokenVersion++;
    }

    public void setActive(boolean active) {
        this.active = active;
        if (!active) tokenVersion++;
    }

    public String getId() { return id; }
    public String getFullName() { return fullName; }
    public String getEmail() { return email; }
    public String getPasswordHash() { return passwordHash; }
    public String getMobileNumber() { return mobileNumber; }
    public AccountRole getRole() { return role; }
    public boolean isActive() { return active; }
    public Instant getRegisteredAt() { return registeredAt; }
    public int getTokenVersion() { return tokenVersion; }
}
