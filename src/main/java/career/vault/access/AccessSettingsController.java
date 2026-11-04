package career.vault.access;

import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api")
public class AccessSettingsController {
    private final AccessSettingsService accessSettings;

    public AccessSettingsController(AccessSettingsService accessSettings) {
        this.accessSettings = accessSettings;
    }

    @GetMapping("/access-settings")
    public List<AccessSettingView> publicSettings() {
        return accessSettings.list();
    }

    @GetMapping("/admin/access-settings")
    public List<AccessSettingView> adminSettings() {
        return accessSettings.list();
    }

    @PutMapping("/admin/access-settings")
    public AccessSettingView update(@Valid @RequestBody AccessSettingInput input) {
        return accessSettings.update(input);
    }
}
