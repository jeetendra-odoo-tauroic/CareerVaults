package career.vault.accounts;

import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface UserAccountRepository extends JpaRepository<UserAccount, String> {
    Optional<UserAccount> findByEmail(String email);

    List<UserAccount> findAllByOrderByRegisteredAtDesc();

    List<UserAccount> findByFullNameContainingIgnoreCaseOrEmailContainingIgnoreCaseOrderByRegisteredAtDesc(
            String name, String email);

    long countByRoleAndActiveTrue(AccountRole role);
}
