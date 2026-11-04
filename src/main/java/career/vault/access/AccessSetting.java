package career.vault.access;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.validation.constraints.NotNull;

import java.time.Instant;

@Entity
@Table(name = "website_access_settings")
public class AccessSetting {
    @Id
    @Column(length = 50)
    private String settingKey;

    @NotNull
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AccessMode mode;

    @Column(nullable = false)
    private Instant updatedAt;

    protected AccessSetting() {
    }

    public AccessSetting(String settingKey, AccessMode mode) {
        this.settingKey = settingKey;
        this.mode = mode;
        updatedAt = Instant.now();
    }

    public void setMode(AccessMode mode) {
        this.mode = mode;
        updatedAt = Instant.now();
    }

    public String getSettingKey() { return settingKey; }
    public AccessMode getMode() { return mode; }
    public Instant getUpdatedAt() { return updatedAt; }
}
