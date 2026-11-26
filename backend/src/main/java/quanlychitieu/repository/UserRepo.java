package quanlychitieu.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import quanlychitieu.entity.User;
@Repository
public interface UserRepo extends JpaRepository<User, Long> {
    @Query(value = "SELECT * FROM users WHERE (nickname = :nickname AND password_hash=:password) AND status = 'ACTIVE'", nativeQuery = true)
    public User findByNickname(String nickname,String password);
}
