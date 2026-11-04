package career.vault.jobs;

public class JobNotFoundException extends RuntimeException {
    public JobNotFoundException(long id) {
        super("Job " + id + " was not found.");
    }
}
