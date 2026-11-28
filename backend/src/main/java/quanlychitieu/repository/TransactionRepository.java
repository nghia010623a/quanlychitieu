package quanlychitieu.repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import quanlychitieu.entity.Transaction;
import quanlychitieu.enums.TransactionStatus;
import quanlychitieu.enums.TransactionType;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {

    @Query("""
            SELECT COALESCE(SUM(t.amount), 0)
            FROM Transaction t
            WHERE t.createdBy.userId = :userId
              AND t.sourceWallet.walletId = :walletId
              AND (:categoryId IS NULL OR t.category.categoryId = :categoryId)
              AND t.transactionType = :transactionType
              AND t.status = :status
              AND t.transactionTime >= :startTime
              AND t.transactionTime <= :endTime
            """)
    BigDecimal sumBudgetSpent(
            @Param("userId") Long userId,
            @Param("walletId") Long walletId,
            @Param("categoryId") Long categoryId,
            @Param("transactionType") TransactionType transactionType,
            @Param("status") TransactionStatus status,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);

    @Query("""
            SELECT t
            FROM Transaction t
            LEFT JOIN FETCH t.sourceWallet w
            WHERE t.createdBy.userId = :userId
              AND t.sourceWallet.walletId = :walletId
              AND (:categoryId IS NULL OR t.category.categoryId = :categoryId)
              AND t.transactionType = :transactionType
              AND t.status = :status
              AND t.transactionTime >= :startTime
              AND t.transactionTime <= :endTime
            ORDER BY t.transactionTime DESC
            """)
    List<Transaction> findBudgetTransactions(
            @Param("userId") Long userId,
            @Param("walletId") Long walletId,
            @Param("categoryId") Long categoryId,
            @Param("transactionType") TransactionType transactionType,
            @Param("status") TransactionStatus status,
            @Param("startTime") LocalDateTime startTime,
            @Param("endTime") LocalDateTime endTime);
}
