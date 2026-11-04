package career.vault.interview;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class InterviewSeedData implements CommandLineRunner {
    private static final Map<String, List<String>> CATALOGUE = new LinkedHashMap<>();

    static {
        CATALOGUE.put("Java Interviews", List.of(
                "Core Java", "Advanced Java", "Java 8 and newer versions", "OOP and Collections",
                "Multithreading", "JVM and Memory Management"));
        CATALOGUE.put("Spring Interviews", List.of(
                "Spring Framework", "Spring Boot", "Spring MVC", "Spring Security",
                "Spring Data JPA", "Hibernate", "REST APIs", "Microservices", "Spring Cloud"));
        CATALOGUE.put("Python Interviews", List.of(
                "Python Fundamentals", "Python OOP", "Django", "Flask", "FastAPI",
                "Python Backend Development"));
        CATALOGUE.put("Database Interviews", List.of(
                "SQL", "Oracle", "MySQL", "PostgreSQL", "MongoDB", "Database Design"));
        CATALOGUE.put("DevOps and Cloud Interviews", List.of(
                "Docker", "Kubernetes", "Jenkins", "AWS", "Git", "CI/CD"));
        CATALOGUE.put("Frontend Interviews", List.of(
                "JavaScript", "TypeScript", "React", "HTML", "CSS"));
        CATALOGUE.put("Architecture and Design", List.of(
                "System Design", "Microservices Architecture", "Design Patterns",
                "Software Architecture", "Performance and Scalability"));
    }

    private final InterviewCategoryRepository categories;
    private final InterviewTopicRepository topics;

    public InterviewSeedData(InterviewCategoryRepository categories, InterviewTopicRepository topics) {
        this.categories = categories;
        this.topics = topics;
    }

    @Override
    @Transactional
    public void run(String... args) {
        CATALOGUE.forEach((name, topicNames) -> {
            InterviewCategory category = category(name);
            topicNames.forEach(title -> seedTopic(category, title));
        });
    }

    private InterviewCategory category(String name) {
        String slug = InterviewSlugs.from(name);
        return categories.findBySlug(slug).orElseGet(() -> {
            InterviewCategory category = new InterviewCategory();
            category.initialize(name, "Interview preparation topics for " + name + ".", true);
            return categories.save(category);
        });
    }

    private void seedTopic(InterviewCategory category, String title) {
        String slug = InterviewSlugs.from(title);
        if (topics.existsByCategoryIdAndSlug(category.getId(), slug)) return;
        InterviewTopic topic = new InterviewTopic();
        topic.initialize(category, title,
                "Editorial content for " + title + " is not available yet.",
                "This interview preparation article is a draft. Add and review the editorial content before publishing.",
                List.of(), false);
        topics.save(topic);
    }
}
