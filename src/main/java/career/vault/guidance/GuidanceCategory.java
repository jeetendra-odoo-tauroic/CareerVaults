package career.vault.guidance;

public enum GuidanceCategory {
    STUDENTS("Career Guidance for Students"),
    FRESHERS("Career Guidance for Freshers"),
    EXPERIENCED("Career Guidance for Experienced Professionals"),
    JAVA_ROADMAP("Java Career Roadmap"),
    PYTHON_ROADMAP("Python Career Roadmap"),
    RESUME_INTERVIEW("Resume and Interview Preparation"),
    JOB_SWITCHING("Job Switching and Career Growth"),
    SALARY_ROLE_COMPARISON("Salary and Role Comparison"),
    GOVERNMENT_PRIVATE("Government vs Private Sector Careers");

    private final String label;

    GuidanceCategory(String label) {
        this.label = label;
    }

    public String label() {
        return label;
    }
}
