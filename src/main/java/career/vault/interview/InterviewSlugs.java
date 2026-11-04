package career.vault.interview;

import java.text.Normalizer;
import java.util.Locale;

final class InterviewSlugs {
    private InterviewSlugs() {
    }

    static String from(String value) {
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9]+", "-")
                .replaceAll("(^-+|-+$)", "");
        if (normalized.isBlank()) {
            throw new IllegalArgumentException("The title must contain letters or numbers to make a URL slug.");
        }
        return normalized;
    }
}
