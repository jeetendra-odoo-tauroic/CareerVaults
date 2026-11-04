package career.vault.guidance;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
public class GuidanceService {
    private static final long MAX_IMAGE_SIZE = 5 * 1024 * 1024;
    private final GuidanceArticleRepository repository;
    private final Path imageDirectory;

    public GuidanceService(
            GuidanceArticleRepository repository,
            @Value("${careervault.guidance.image-dir}") String imageDirectory) {
        this.repository = repository;
        this.imageDirectory = Path.of(imageDirectory).toAbsolutePath().normalize();
    }

    @Transactional(readOnly = true)
    public List<GuidanceViews.CategoryView> categories() {
        return Arrays.stream(GuidanceCategory.values())
                .map(GuidanceViews.CategoryView::from).toList();
    }

    @Transactional(readOnly = true)
    public GuidanceViews.ArticleList publicArticles(GuidanceCategory category, String search) {
        String title = search == null || search.isBlank() ? null : search.trim();
        List<GuidanceArticle> articles;
        if (category != null && title != null) {
            articles = repository.findByStatusAndCategoryAndTitleContainingIgnoreCaseOrderByUpdatedAtDesc(
                    GuidanceStatus.PUBLISHED, category, title);
        } else if (category != null) {
            articles = repository.findByStatusAndCategoryOrderByUpdatedAtDesc(
                    GuidanceStatus.PUBLISHED, category);
        } else if (title != null) {
            articles = repository.findByStatusAndTitleContainingIgnoreCaseOrderByUpdatedAtDesc(
                    GuidanceStatus.PUBLISHED, title);
        } else {
            articles = repository.findByStatusOrderByUpdatedAtDesc(GuidanceStatus.PUBLISHED);
        }
        return new GuidanceViews.ArticleList(articles.stream()
                .map(GuidanceViews.ArticleSummary::from).toList(), categories());
    }

    @Transactional(readOnly = true)
    public GuidanceViews.ArticleView publicArticle(long id) {
        return GuidanceViews.ArticleView.from(repository.findByIdAndStatus(id, GuidanceStatus.PUBLISHED)
                .orElseThrow(() -> new GuidanceArticleNotFoundException(id)));
    }

    @Transactional(readOnly = true)
    public List<GuidanceViews.ArticleView> adminArticles() {
        return repository.findAllByOrderByUpdatedAtDesc().stream()
                .map(article -> GuidanceViews.ArticleView.from(article, true)).toList();
    }

    @Transactional(readOnly = true)
    public GuidanceArticle adminArticle(long id) {
        return getArticle(id);
    }

    @Transactional
    public GuidanceViews.ArticleView create(GuidanceArticleInput input) {
        GuidanceArticle article = new GuidanceArticle();
        article.initialize(input);
        return GuidanceViews.ArticleView.from(repository.save(article), true);
    }

    @Transactional
    public GuidanceViews.ArticleView update(long id, GuidanceArticleInput input) {
        GuidanceArticle article = getArticle(id);
        article.apply(input);
        return GuidanceViews.ArticleView.from(repository.save(article), true);
    }

    @Transactional
    public GuidanceViews.ArticleView setStatus(long id, GuidanceStatus status) {
        GuidanceArticle article = getArticle(id);
        article.setStatus(status);
        return GuidanceViews.ArticleView.from(repository.save(article), true);
    }

    @Transactional
    public void delete(long id) throws IOException {
        GuidanceArticle article = getArticle(id);
        repository.delete(article);
        if (article.getImageFileName() != null) {
            Files.deleteIfExists(resolveImage(article.getImageFileName()));
        }
    }

    @Transactional
    public GuidanceViews.ArticleView uploadImage(long id, MultipartFile file) throws IOException {
        if (file.isEmpty() || file.getSize() > MAX_IMAGE_SIZE) {
            throw new IllegalArgumentException("Choose a non-empty PNG, JPEG or WebP image smaller than 5 MB.");
        }
        byte[] bytes = file.getBytes();
        String extension = validatedExtension(file.getOriginalFilename(), file.getContentType(), bytes);
        GuidanceArticle article = getArticle(id);
        Files.createDirectories(imageDirectory);
        String stored = UUID.randomUUID() + extension;
        Files.write(resolveImage(stored), bytes);
        String previous = article.getImageFileName();
        article.setImageFileName(stored);
        GuidanceArticle saved = repository.save(article);
        if (previous != null) Files.deleteIfExists(resolveImage(previous));
        return GuidanceViews.ArticleView.from(saved, true);
    }

    @Transactional(readOnly = true)
    public ImageFile publicImage(long id) throws IOException {
        GuidanceArticle article = repository.findByIdAndStatus(id, GuidanceStatus.PUBLISHED)
                .orElseThrow(() -> new GuidanceArticleNotFoundException(id));
        return imageFile(article);
    }

    @Transactional(readOnly = true)
    public ImageFile adminImage(long id) throws IOException {
        return imageFile(getArticle(id));
    }

    private ImageFile imageFile(GuidanceArticle article) throws IOException {
        if (article.getImageFileName() == null) {
            throw new GuidanceArticleNotFoundException(article.getId());
        }
        Path path = resolveImage(article.getImageFileName());
        if (!Files.isRegularFile(path)) throw new GuidanceArticleNotFoundException(article.getId());
        String extension = extension(article.getImageFileName());
        String contentType = switch (extension) {
            case ".png" -> "image/png";
            case ".jpg", ".jpeg" -> "image/jpeg";
            case ".webp" -> "image/webp";
            default -> throw new IllegalArgumentException("Unsupported guidance image format.");
        };
        return new ImageFile("career-guidance-" + article.getId() + extension,
                contentType, Files.readAllBytes(path));
    }

    private GuidanceArticle getArticle(long id) {
        return repository.findById(id).orElseThrow(() -> new GuidanceArticleNotFoundException(id));
    }

    private String validatedExtension(String filename, String contentType, byte[] bytes) {
        if (filename == null || contentType == null) {
            throw new IllegalArgumentException("The selected career guidance image is invalid.");
        }
        String extension = extension(filename);
        boolean png = ".png".equals(extension) && "image/png".equalsIgnoreCase(contentType)
                && startsWith(bytes, new byte[]{(byte) 0x89, 'P', 'N', 'G', 13, 10, 26, 10});
        boolean jpeg = (".jpg".equals(extension) || ".jpeg".equals(extension))
                && "image/jpeg".equalsIgnoreCase(contentType) && bytes.length > 3
                && (bytes[0] & 0xff) == 0xff && (bytes[1] & 0xff) == 0xd8
                && (bytes[2] & 0xff) == 0xff;
        boolean webp = ".webp".equals(extension) && "image/webp".equalsIgnoreCase(contentType)
                && bytes.length > 12 && ascii(bytes, 0, "RIFF") && ascii(bytes, 8, "WEBP");
        if (!(png || jpeg || webp)) {
            throw new IllegalArgumentException("Only valid PNG, JPEG or WebP images are supported.");
        }
        return extension;
    }

    private boolean startsWith(byte[] bytes, byte[] prefix) {
        if (bytes.length < prefix.length) return false;
        for (int i = 0; i < prefix.length; i++) if (bytes[i] != prefix[i]) return false;
        return true;
    }

    private boolean ascii(byte[] bytes, int offset, String marker) {
        for (int i = 0; i < marker.length(); i++) {
            if (bytes[offset + i] != marker.charAt(i)) return false;
        }
        return true;
    }

    private String extension(String filename) {
        int dot = filename.lastIndexOf('.');
        return dot < 0 ? "" : filename.substring(dot).toLowerCase(Locale.ROOT);
    }

    private Path resolveImage(String filename) {
        Path path = imageDirectory.resolve(filename).normalize();
        if (!path.startsWith(imageDirectory)) {
            throw new IllegalArgumentException("Invalid career guidance image path.");
        }
        return path;
    }

    public record ImageFile(String filename, String contentType, byte[] content) {
    }
}
