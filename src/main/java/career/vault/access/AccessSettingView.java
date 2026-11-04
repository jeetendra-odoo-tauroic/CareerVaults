package career.vault.access;

import java.time.Instant;

public record AccessSettingView(
        String key,
        String section,
        String feature,
        AccessMode mode,
        AccessMode effectiveMode,
        boolean overridden,
        boolean locked,
        Instant updatedAt
) {
}
