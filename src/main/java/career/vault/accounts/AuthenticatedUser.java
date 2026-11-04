package career.vault.accounts;

public record AuthenticatedUser(String id, String email, AccountRole role) {
}
