package quanlychitieu.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import quanlychitieu.entity.Wallet;
import quanlychitieu.enums.WalletStatus;

@Repository
public interface WalletRepository extends JpaRepository<Wallet, Long> {

    List<Wallet> findByUserUserIdAndStatusOrderByWalletIdAsc(Long userId, WalletStatus status);

    @Query("""
            SELECT w FROM Wallet w
            WHERE w.status = :status
              AND (
                w.user.userId = :userId
                OR w.groupId IN (
                    SELECT gm.group.groupId FROM GroupMember gm
                    WHERE gm.user.userId = :userId
                      AND gm.status = quanlychitieu.enums.GroupMemberStatus.ACTIVE
                )
              )
            ORDER BY w.walletId ASC
            """)
    List<Wallet> findAccessibleWallets(
            @Param("userId") Long userId,
            @Param("status") WalletStatus status);

    @Query("""
            SELECT w FROM Wallet w
            WHERE w.walletId = :walletId
              AND w.status = :status
              AND (
                w.user.userId = :userId
                OR w.groupId IN (
                    SELECT gm.group.groupId FROM GroupMember gm
                    WHERE gm.user.userId = :userId
                      AND gm.status = quanlychitieu.enums.GroupMemberStatus.ACTIVE
                )
              )
            """)
    Optional<Wallet> findAccessibleWalletById(
            @Param("walletId") Long walletId,
            @Param("userId") Long userId,
            @Param("status") WalletStatus status);
}
