package career.vault.accounts;

import career.vault.access.AccessMode;
import career.vault.access.AccessSettingsService;
import tools.jackson.databind.ObjectMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Map;

public class ApiAuthenticationFilter extends OncePerRequestFilter {
    private final AuthTokenService tokens;
    private final UserAccountRepository users;
    private final AccessSettingsService access;
    private final ObjectMapper objectMapper;

    public ApiAuthenticationFilter(AuthTokenService tokens, UserAccountRepository users,
                                   AccessSettingsService access, ObjectMapper objectMapper) {
        this.tokens = tokens;
        this.users = users;
        this.access = access;
        this.objectMapper = objectMapper;
    }

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        return "OPTIONS".equalsIgnoreCase(request.getMethod())
                || !request.getRequestURI().startsWith("/api/");
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response,
                                    FilterChain chain) throws ServletException, IOException {
        SecurityContextHolder.clearContext();
        String path = request.getServletPath();
        if (isPublicAuth(path) || path.equals("/api/access-settings")) {
            chain.doFilter(request, response);
            return;
        }
        String header = request.getHeader("Authorization");
        AuthenticatedUser user = null;
        if (header != null) {
            if (header.startsWith("Bearer ") && header.length() > 7) {
                user = tokens.authenticate(header.substring(7), users);
            }
            if (user != null) {
                SecurityContextHolder.getContext().setAuthentication(
                        new UsernamePasswordAuthenticationToken(user, null,
                                List.of(new SimpleGrantedAuthority("ROLE_" + user.role().name()))));
            }
        }
        if (isAdminPath(path)) {
            if (user == null) {
                reject(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "Please log in to access this feature.");
                return;
            }
            if (user.role() != AccountRole.ADMIN) {
                reject(response, HttpServletResponse.SC_FORBIDDEN,
                        "Administrator access is required.");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        if (path.equals("/api/auth/me") || path.startsWith("/api/account/")
                || path.startsWith("/api/test-attempts/")) {
            if (user == null) {
                reject(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "Please log in to access this feature.");
                return;
            }
            chain.doFilter(request, response);
            return;
        }

        String setting = access.settingForRequest(request.getMethod(), path,
                request.getParameter("category"), request.getParameter("section"));
        if (setting == null || setting.equals("AUTHENTICATED")) {
            if (user == null) {
                reject(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "Please log in to access this feature.");
                return;
            }
        } else if (setting.equals("GOVERNMENT_AND_IT_LISTINGS") && user == null) {
            if (access.mode("GOVERNMENT_JOB_LISTINGS") == AccessMode.LOGIN_REQUIRED
                    && access.mode("IT_JOB_LISTINGS") == AccessMode.LOGIN_REQUIRED) {
                reject(response, HttpServletResponse.SC_UNAUTHORIZED,
                        "Please log in to access this feature.");
                return;
            }
        } else if (!setting.equals("ADMIN")
                && access.mode(setting) == AccessMode.LOGIN_REQUIRED && user == null) {
            reject(response, HttpServletResponse.SC_UNAUTHORIZED,
                    "Please log in to access this feature.");
            return;
        }
        chain.doFilter(request, response);
    }

    private boolean isPublicAuth(String path) {
        return path.equals("/api/auth/register") || path.equals("/api/auth/login");
    }

    private boolean isAdminPath(String path) {
        return path.equals("/api/admin") || path.startsWith("/api/admin/");
    }

    private void reject(HttpServletResponse response, int status, String message)
            throws IOException {
        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getWriter(), Map.of("error", message));
    }
}
