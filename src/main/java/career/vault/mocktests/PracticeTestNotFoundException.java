package career.vault.mocktests;

public class PracticeTestNotFoundException extends RuntimeException {
    public PracticeTestNotFoundException(long id) {
        super("Test " + id + " was not found.");
    }
}
