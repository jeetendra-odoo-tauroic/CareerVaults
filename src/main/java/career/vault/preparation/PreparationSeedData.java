package career.vault.preparation;

import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Component
public class PreparationSeedData implements CommandLineRunner {
    private static final List<String> JAVA_TOPICS = List.of(
            "Java Introduction", "OOP Concepts", "Strings", "Collections Framework",
            "Exception Handling", "Multithreading", "Java 8 Features", "Java 11, 17 and 21",
            "JVM and Memory Management", "Spring Framework", "Spring Boot", "Spring MVC",
            "Spring Security", "Spring Data JPA", "Hibernate", "REST APIs", "Microservices",
            "Spring Cloud", "Kafka", "SQL", "Oracle", "MySQL", "Redis", "Docker",
            "Kubernetes", "AWS", "Git", "Maven", "System Design");

    private static final List<String> PYTHON_TOPICS = List.of(
            "Python Fundamentals", "Data Types", "Functions", "OOP", "Collections",
            "Exception Handling", "File Handling", "Modules and Packages", "Django",
            "Flask", "FastAPI", "SQL Integration", "Data Science Fundamentals",
            "AI and Machine Learning", "Automation");

    private final PreparationCategoryRepository categories;
    private final PreparationTopicRepository topics;

    public PreparationSeedData(PreparationCategoryRepository categories,
                               PreparationTopicRepository topics) {
        this.categories = categories;
        this.topics = topics;
    }

    @Override
    @Transactional
    public void run(String... args) {
        PreparationCategory java = category("Java Development",
                "Core Java, the Spring ecosystem and additional engineering technologies.");
        PreparationCategory python = category("Python Development",
                "Python fundamentals, popular frameworks, data science and automation.");
        seedTopics(java, JAVA_TOPICS);
        seedTopics(python, PYTHON_TOPICS);
    }

    private PreparationCategory category(String name, String description) {
        String slug = PreparationSlugs.from(name);
        return categories.findBySlug(slug).orElseGet(() -> {
            PreparationCategory category = new PreparationCategory();
            category.initialize(name, description, true);
            return categories.save(category);
        });
    }

    private void seedTopics(PreparationCategory category, List<String> titles) {
        for (String title : titles) {
            String slug = PreparationSlugs.from(title);
            if (topics.existsByCategoryIdAndSlug(category.getId(), slug)) continue;
            PreparationTopic topic = new PreparationTopic();
            topic.initialize(category, title,
                    "Learning notes for " + title + " in " + category.getName() + ".",
                    "This lesson is being prepared. Add and review the learning material before publishing.",
                    null, null, null, false);
            topics.save(topic);
        }
    }
}
