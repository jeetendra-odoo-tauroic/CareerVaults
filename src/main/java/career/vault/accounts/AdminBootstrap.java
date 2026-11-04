package career.vault.accounts;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import career.vault.access.AccessSettingsService;

@Component
public class AdminBootstrap implements ApplicationRunner {
    private static final Logger logger = LoggerFactory.getLogger(AdminBootstrap.class);
    private final UserAccountRepository users;
    private final AccessSettingsService accessSettings;
    private final PasswordEncoder passwordEncoder;
    private final String email;
    private final String password;

    public AdminBootstrap(UserAccountRepository users, AccessSettingsService accessSettings,
                         PasswordEncoder passwordEncoder,
                         @Value("${careervault.auth.bootstrap-admin-email:}") String email,
                         @Value("${careervault.auth.bootstrap-admin-password:}") String password) {
        this.users = users;
        this.accessSettings = accessSettings;
        this.passwordEncoder = passwordEncoder;
        this.email = email.trim();
        this.password = password;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        accessSettings.initializeDefaults();
        if (email.isBlank() && password.isBlank()) return;
        if (email.isBlank() || password.length() < 12) {
            throw new IllegalStateException(
                    "Configure both bootstrap admin email and a password of at least 12 characters.");
        }
        if (users.findByEmail(UserAccount.normalizeEmail(email)).isPresent()) {
            logger.warn("Bootstrap admin email already exists; no account was changed.");
            return;
        }
        users.save(UserAccount.administrator("CareerVault Administrator",
                email, passwordEncoder.encode(password)));
        logger.info("Created the environment-configured CareerVault administrator account.");
    }
}
