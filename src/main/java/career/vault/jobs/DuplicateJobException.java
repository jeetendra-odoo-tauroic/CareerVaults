package career.vault.jobs;

public class DuplicateJobException extends RuntimeException {
    public DuplicateJobException(String message) {
        super(message);
    }
}
