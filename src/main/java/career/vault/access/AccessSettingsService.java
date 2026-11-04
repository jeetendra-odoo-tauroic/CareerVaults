package career.vault.access;

import career.vault.mocktests.PracticeTest;
import career.vault.mocktests.PracticeTestRepository;
import career.vault.mocktests.TestKind;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Collections;
import career.vault.jobs.Job;
import career.vault.jobs.JobRepository;

@Service
public class AccessSettingsService {
    private static final Map<String, Rule> RULES = rules();
    private final AccessSettingRepository settings;
    private final PracticeTestRepository tests;
    private final JobRepository jobs;

    public AccessSettingsService(AccessSettingRepository settings,
                                 PracticeTestRepository tests, JobRepository jobs) {
        this.settings = settings;
        this.tests = tests;
        this.jobs = jobs;
    }

    @Transactional
    public void initializeDefaults() {
        for (Rule rule : RULES.values()) {
            if (rule.sectionKey.equals(rule.key) && settings.findById(rule.key).isEmpty()) {
                settings.save(new AccessSetting(rule.key, AccessMode.PUBLIC));
            }
        }
        for (String key : List.of("MOCK_TEST_ATTEMPTS", "DAILY_QUIZ_ATTEMPTS")) {
            if (settings.findById(key).isEmpty()) {
                settings.save(new AccessSetting(key, AccessMode.LOGIN_REQUIRED));
            }
        }
    }

    @Transactional(readOnly = true)
    public List<AccessSettingView> list() {
        List<AccessSettingView> views = new ArrayList<>();
        for (Rule rule : RULES.values()) {
            if (rule.key.equals("PERSONAL_PROFILE") || rule.key.equals("PERSONAL_RESULTS")) {
                views.add(new AccessSettingView(rule.key, rule.section, rule.feature,
                        AccessMode.LOGIN_REQUIRED, AccessMode.LOGIN_REQUIRED, false, true, null));
                continue;
            }
            Optional<AccessSetting> setting = settings.findById(rule.key);
            AccessMode effective = setting.map(AccessSetting::getMode)
                    .orElseGet(() -> getMode(rule.sectionKey));
            views.add(new AccessSettingView(rule.key, rule.section, rule.feature,
                    setting.map(AccessSetting::getMode).orElse(effective), effective,
                    setting.isPresent() && !rule.key.equals(rule.sectionKey), false,
                    setting.map(AccessSetting::getUpdatedAt).orElse(null)));
        }
        return views;
    }

    @Transactional
    public AccessSettingView update(AccessSettingInput input) {
        Rule rule = RULES.get(input.key());
        if (rule == null || rule.locked) {
            throw new IllegalArgumentException("This access setting cannot be changed.");
        }
        AccessSetting setting = settings.findById(rule.key)
                .orElseGet(() -> new AccessSetting(rule.key, input.mode()));
        setting.setMode(input.mode());
        settings.save(setting);
        AccessMode effective = setting.getMode();
        return new AccessSettingView(rule.key, rule.section, rule.feature,
                setting.getMode(), effective, !rule.key.equals(rule.sectionKey),
                false, setting.getUpdatedAt());
    }

    @Transactional(readOnly = true)
    public AccessMode mode(String key) {
        Rule rule = RULES.get(key);
        if (rule == null) return AccessMode.LOGIN_REQUIRED;
        return settings.findById(rule.key).map(AccessSetting::getMode)
                .orElseGet(() -> getMode(rule.sectionKey));
    }

    @Transactional(readOnly = true)
    public String settingForRequest(String method, String path, String category, String section) {
        if (path.equals("/api/jobs")) {
            if ("GOVERNMENT".equalsIgnoreCase(section)) return "GOVERNMENT_JOB_LISTINGS";
            if ("IT".equalsIgnoreCase(section)) return "IT_JOB_LISTINGS";
            if (category != null && isGovernmentCategory(category)) {
                return "GOVERNMENT_JOB_LISTINGS";
            }
            if (category != null) return "IT_JOB_LISTINGS";
            return "GOVERNMENT_AND_IT_LISTINGS";
        }
        if (path.matches("^/api/jobs/[^/]+(/notification)?$")) {
            String[] parts = path.split("/");
            try {
                Job job = jobs.findById(Long.parseLong(parts[3])).orElse(null);
                return job != null && isGovernmentCategory(job.getCategory())
                        ? "GOVERNMENT_JOB_DETAILS" : "IT_JOB_DETAILS";
            } catch (NumberFormatException exception) {
                return "GOVERNMENT_JOB_DETAILS";
            }
        }
        if (path.startsWith("/api/preparation/")) {
            boolean detail = path.matches("^/api/preparation/categories/[^/]+/topics/[^/]+$")
                    || path.matches("^/api/preparation/resources/\\d+$");
            return detail ? "PREPARATION_TOPIC_DETAILS" : "PREPARATION_TOPIC_LISTINGS";
        }
        if (path.startsWith("/api/interviews/")) {
            boolean detail = path.matches("^/api/interviews/categories/[^/]+/topics/[^/]+$");
            return detail ? "PREPARATION_TOPIC_DETAILS" : "PREPARATION_TOPIC_LISTINGS";
        }
        if (path.equals("/api/courses")) return "COURSE_LISTINGS";
        if (path.matches("^/api/courses/\\d+(/image)?$")) return "COURSE_DETAILS";
        if (path.equals("/api/tests") || path.equals("/api/test-categories")) {
            return "MOCK_TEST_LISTINGS";
        }
        if (path.equals("/api/daily-quiz")) return "DAILY_QUIZ_LISTINGS";
        if (path.matches("^/api/tests/\\d+/attempts$")) {
            long testId = Long.parseLong(path.split("/")[3]);
            PracticeTest test = tests.findById(testId).orElse(null);
            return test != null && test.getKind() == TestKind.DAILY_QUIZ
                    ? "DAILY_QUIZ_ATTEMPTS" : "MOCK_TEST_ATTEMPTS";
        }
        if (path.matches("^/api/tests/\\d+$")) {
            long testId = Long.parseLong(path.substring(path.lastIndexOf('/') + 1));
            PracticeTest test = tests.findById(testId).orElse(null);
            return test != null && test.getKind() == TestKind.DAILY_QUIZ
                    ? "DAILY_QUIZ_DETAILS" : "MOCK_TEST_DETAILS";
        }
        if (path.startsWith("/api/test-attempts/")) return "PERSONAL_RESULTS";
        if (path.equals("/api/guidance/categories") || path.equals("/api/guidance")) {
            return "GUIDANCE_ARTICLE_LISTINGS";
        }
        if (path.matches("^/api/guidance/\\d+(/image)?$")) return "GUIDANCE_ARTICLE_DETAILS";
        if (path.startsWith("/api/admin/")) return "ADMIN";
        if (path.startsWith("/api/")) return "AUTHENTICATED";
        return null;
    }

    private AccessMode getMode(String key) {
        return settings.findById(key).map(AccessSetting::getMode).orElse(AccessMode.LOGIN_REQUIRED);
    }

    private static Map<String, Rule> rules() {
        Map<String, Rule> rules = new java.util.LinkedHashMap<>();
        addSection(rules, "GOVERNMENT_JOBS", "Government Jobs");
        addFeature(rules, "GOVERNMENT_JOB_LISTINGS", "GOVERNMENT_JOBS", "Government Jobs", "View job listings");
        addFeature(rules, "GOVERNMENT_JOB_DETAILS", "GOVERNMENT_JOBS", "Government Jobs", "View job details");
        addSection(rules, "IT_JOBS", "IT Jobs");
        addFeature(rules, "IT_JOB_LISTINGS", "IT_JOBS", "IT Jobs", "View job listings");
        addFeature(rules, "IT_JOB_DETAILS", "IT_JOBS", "IT Jobs", "View job details");
        addSection(rules, "IT_PREPARATION", "IT Preparation");
        addFeature(rules, "PREPARATION_TOPIC_LISTINGS", "IT_PREPARATION", "IT Preparation", "View topic listings");
        addFeature(rules, "PREPARATION_TOPIC_DETAILS", "IT_PREPARATION", "IT Preparation", "View topic details and articles");
        addSection(rules, "ONLINE_CLASSES", "Online Classes");
        addFeature(rules, "COURSE_LISTINGS", "ONLINE_CLASSES", "Online Classes", "View course listings");
        addFeature(rules, "COURSE_DETAILS", "ONLINE_CLASSES", "Online Classes", "View course details");
        addSection(rules, "MOCK_TESTS", "Mock Tests");
        addFeature(rules, "MOCK_TEST_LISTINGS", "MOCK_TESTS", "Mock Tests", "View test listings");
        addFeature(rules, "MOCK_TEST_DETAILS", "MOCK_TESTS", "Mock Tests", "View test details");
        addFeature(rules, "MOCK_TEST_ATTEMPTS", "MOCK_TESTS", "Mock Tests", "Attempt tests");
        addSection(rules, "DAILY_QUIZZES", "Daily Quizzes");
        addFeature(rules, "DAILY_QUIZ_LISTINGS", "DAILY_QUIZZES", "Daily Quizzes", "View quiz listings");
        addFeature(rules, "DAILY_QUIZ_DETAILS", "DAILY_QUIZZES", "Daily Quizzes", "View quiz details");
        addFeature(rules, "DAILY_QUIZ_ATTEMPTS", "DAILY_QUIZZES", "Daily Quizzes", "Attempt quizzes");
        addSection(rules, "CAREER_GUIDANCE", "Career Guidance");
        addFeature(rules, "GUIDANCE_ARTICLE_LISTINGS", "CAREER_GUIDANCE", "Career Guidance", "View article listings");
        addFeature(rules, "GUIDANCE_ARTICLE_DETAILS", "CAREER_GUIDANCE", "Career Guidance", "View article details");
        rules.put("PERSONAL_PROFILE", new Rule("PERSONAL_PROFILE", "My Account", "Personal profile",
                "PERSONAL_PROFILE", true));
        rules.put("PERSONAL_RESULTS", new Rule("PERSONAL_RESULTS", "Mock Tests and Daily Quizzes",
                "Personal results and history", "PERSONAL_RESULTS", true));
        return Collections.unmodifiableMap(rules);
    }

    private boolean isGovernmentCategory(String value) {
        String normalized = value.toLowerCase(java.util.Locale.ROOT);
        return normalized.contains("government") || normalized.contains("govt")
                || normalized.contains("bank") || normalized.contains("upsc")
                || normalized.contains("ssc") || normalized.contains("railway")
                || normalized.contains("psu");
    }

    private static void addSection(Map<String, Rule> rules, String key, String name) {
        rules.put(key, new Rule(key, name, null, key, false));
    }

    private static void addFeature(Map<String, Rule> rules, String key, String sectionKey,
                                   String section, String feature) {
        rules.put(key, new Rule(key, section, feature, sectionKey, false));
    }

    private record Rule(String key, String section, String feature,
                        String sectionKey, boolean locked) {
    }
}
