package career.vault.mocktests;

public class TestAttemptNotFoundException extends RuntimeException {
    public TestAttemptNotFoundException(String id) {
        super("Test attempt " + id + " was not found.");
    }
}
