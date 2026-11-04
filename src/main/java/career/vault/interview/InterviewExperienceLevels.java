package career.vault.interview;

import java.util.List;

final class InterviewExperienceLevels {
    static final List<String> ALL = List.of(
            "Fresher", "0–2 years", "2–5 years", "5–8 years", "8–12 years", "12+ years");

    private InterviewExperienceLevels() {
    }

    static List<String> validate(List<String> levels) {
        if (levels == null) return List.of();
        List<String> normalized = levels.stream().distinct().toList();
        if (!ALL.containsAll(normalized)) {
            throw new IllegalArgumentException("Select only supported interview experience levels.");
        }
        return normalized;
    }
}
