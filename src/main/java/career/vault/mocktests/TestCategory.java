package career.vault.mocktests;

public enum TestCategory {
    BANKING("Banking", "Government"),
    SSC("SSC", "Government"),
    UPSC("UPSC", "Government"),
    RAILWAY("Railway", "Government"),
    GENERAL_KNOWLEDGE("General Knowledge", "Government"),
    REASONING("Reasoning", "Government"),
    QUANTITATIVE_APTITUDE("Quantitative Aptitude", "Government"),
    CORE_JAVA("Core Java", "IT"),
    SPRING_BOOT("Spring Boot", "IT"),
    PYTHON("Python", "IT"),
    SQL("SQL", "IT"),
    MICROSERVICES("Microservices", "IT"),
    REACT("React", "IT"),
    SOFTWARE_ENGINEERING("Software Engineering", "IT");

    private final String label;
    private final String group;

    TestCategory(String label, String group) {
        this.label = label;
        this.group = group;
    }

    public String label() { return label; }
    public String group() { return group; }
}
