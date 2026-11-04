package career.vault.guidance;

public class GuidanceArticleNotFoundException extends RuntimeException {
    public GuidanceArticleNotFoundException(long id) {
        super("Career guidance article " + id + " was not found.");
    }
}
