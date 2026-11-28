package quanlychitieu.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import quanlychitieu.dto.BudgetPeriodFilterDto;
import quanlychitieu.dto.BudgetProgressResponse;
import quanlychitieu.dto.BudgetRequest;
import quanlychitieu.dto.BudgetResponse;
import quanlychitieu.entity.Budget;
import quanlychitieu.entity.Category;
import quanlychitieu.entity.Transaction;
import quanlychitieu.entity.User;
import quanlychitieu.entity.Wallet;
import quanlychitieu.enums.BudgetPeriod;
import quanlychitieu.enums.BudgetStatus;
import quanlychitieu.enums.CategoryType;
import quanlychitieu.enums.TransactionStatus;
import quanlychitieu.enums.TransactionType;
import quanlychitieu.enums.WalletStatus;
import quanlychitieu.enums.WalletType;
import quanlychitieu.repository.BudgetRepository;
import quanlychitieu.repository.CategoryRepository;
import quanlychitieu.repository.TransactionRepository;
import quanlychitieu.repository.WalletRepository;

@ExtendWith(MockitoExtension.class)
class BudgetServiceTest {

    @Mock
    private BudgetRepository budgetRepository;

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private WalletRepository walletRepository;

    @Mock
    private TransactionRepository transactionRepository;

    @InjectMocks
    private BudgetService budgetService;

    private User user() {
        return User.builder().userId(1L).nickname("demo").fullName("Demo User").build();
    }

    private Wallet wallet(Long id, String name) {
        return Wallet.builder()
                .walletId(id)
                .walletName(name)
                .walletType(WalletType.PERSONAL)
                .status(WalletStatus.ACTIVE)
                .balance(new BigDecimal("5000000.00"))
                .build();
    }

    private Category expenseCategory(Long id, String name) {
        return Category.builder()
                .categoryId(id)
                .categoryName(name)
                .categoryType(CategoryType.EXPENSE)
                .isDefault(true)
                .build();
    }

    @Test
    void getPeriodFiltersIncludesDefaultWindowAndBudgetMonths() {
        User u = user();
        Wallet w = wallet(2L, "Ví tiền mặt");
        Budget oldBudget = Budget.builder()
                .budgetId(1L)
                .wallet(w)
                .budgetName("Ăn uống")
                .amount(new BigDecimal("1000000"))
                .period(BudgetPeriod.MONTH)
                .startDate(LocalDate.of(2025, 8, 1))
                .endDate(LocalDate.of(2025, 8, 31))
                .createdBy(u)
                .build();

        when(budgetRepository.findActiveByUserId(1L, BudgetStatus.ACTIVE)).thenReturn(List.of(oldBudget));

        List<BudgetPeriodFilterDto> filters = budgetService.getPeriodFilters(1L);

        YearMonth now = YearMonth.now();
        assertTrue(filters.stream().anyMatch(f -> f.getId().equals(now.toString())));
        assertTrue(filters.stream().anyMatch(f -> f.getId().equals(now.minusMonths(1).toString())));
        assertTrue(filters.stream().anyMatch(f -> f.getId().equals(now.plusMonths(1).toString())));
        assertTrue(filters.stream().anyMatch(f -> f.getId().equals("2025-08")));
    }

    @Test
    void getBudgetsFiltersByPeriodAndWalletAndSupportsAllKeyword() {
        User u = user();
        Wallet wCash = wallet(2L, "Ví tiền mặt");
        Wallet wBank = wallet(3L, "Ví Vietcombank");
        Category food = expenseCategory(5L, "Ăn uống");

        Budget bNov = Budget.builder()
                .budgetId(10L)
                .wallet(wCash)
                .category(food)
                .budgetName("Ăn uống")
                .amount(new BigDecimal("3000000.00"))
                .period(BudgetPeriod.MONTH)
                .startDate(LocalDate.of(2026, 11, 1))
                .endDate(LocalDate.of(2026, 11, 30))
                .alertPercent(new BigDecimal("80.00"))
                .status(BudgetStatus.ACTIVE)
                .createdBy(u)
                .build();
        Budget bOctBank = Budget.builder()
                .budgetId(11L)
                .wallet(wBank)
                .category(food)
                .budgetName("Ăn uống T10")
                .amount(new BigDecimal("2000000.00"))
                .period(BudgetPeriod.MONTH)
                .startDate(LocalDate.of(2026, 10, 1))
                .endDate(LocalDate.of(2026, 10, 31))
                .alertPercent(new BigDecimal("80.00"))
                .status(BudgetStatus.ACTIVE)
                .createdBy(u)
                .build();

        when(budgetRepository.findActiveByUserId(1L, BudgetStatus.ACTIVE)).thenReturn(List.of(bNov, bOctBank));
        when(transactionRepository.sumBudgetSpent(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(new BigDecimal("1800000.00"));
        when(transactionRepository.findBudgetTransactions(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of(Transaction.builder()
                        .transactionId(101L)
                        .sourceWallet(wCash)
                        .amount(new BigDecimal("85000.00"))
                        .description("Bún chả")
                        .transactionTime(LocalDateTime.of(2026, 11, 15, 12, 0))
                        .build()));

        List<BudgetResponse> novCash = budgetService.getBudgets(1L, "2026-11", null, null, 2L, null);
        assertEquals(1, novCash.size());
        assertEquals(10L, novCash.get(0).getBudgetId());
        assertEquals(new BigDecimal("-85000.00"), novCash.get(0).getTransactions().get(0).getAmount());

        List<BudgetResponse> all = budgetService.getBudgets(1L, "ALL", null, null, null, null);
        assertEquals(2, all.size());
    }

    @Test
    void createBudgetValidatesInputsAndSaves() {
        User u = user();
        Wallet w1 = wallet(2L, "Ví tiền mặt");
        Wallet w2 = wallet(3L, "Ví Vietcombank");
        Category food = expenseCategory(5L, "Ăn uống");

        when(walletRepository.findAccessibleWalletById(2L, 1L, WalletStatus.ACTIVE)).thenReturn(Optional.of(w1));
        when(walletRepository.findAccessibleWalletById(3L, 1L, WalletStatus.ACTIVE)).thenReturn(Optional.of(w2));
        when(categoryRepository.findAccessibleCategoryById(5L, 1L)).thenReturn(Optional.of(food));
        when(budgetRepository.save(any(Budget.class))).thenAnswer(inv -> {
            Budget b = inv.getArgument(0);
            b.setBudgetId(10L);
            return b;
        });
        when(transactionRepository.sumBudgetSpent(eq(1L), eq(2L), eq(5L),
                eq(TransactionType.EXPENSE), eq(TransactionStatus.SUCCESS), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findBudgetTransactions(eq(1L), eq(2L), eq(5L),
                eq(TransactionType.EXPENSE), eq(TransactionStatus.SUCCESS), any(), any()))
                .thenReturn(List.of());

        BudgetRequest req = new BudgetRequest();
        req.setWalletIds(List.of(2L, 3L));
        req.setCategoryId(5L);
        req.setAmount(new BigDecimal("3000000"));
        req.setPeriod(BudgetPeriod.MONTH);
        req.setStartDate(LocalDate.of(2026, 11, 1));
        req.setAlertPercent(new BigDecimal("80"));
        req.setRepeatMonthly(true);

        BudgetResponse res = budgetService.createBudget(u, req);
        assertEquals(10L, res.getBudgetId());
        assertEquals("Ăn uống", res.getBudgetName());
        assertEquals(LocalDate.of(2026, 11, 30), res.getEndDate());
        assertEquals(new BigDecimal("3000000.00"), res.getAmount());
    }

    @Test
    void createBudgetRejectsInvalidAmountIncomeCategoryAndMissingCustomEndDate() {
        User u = user();
        Wallet w1 = wallet(2L, "Ví tiền mặt");
        Category incomeCat = Category.builder()
                .categoryId(9L)
                .categoryName("Lương")
                .categoryType(CategoryType.INCOME)
                .isDefault(true)
                .build();

        when(walletRepository.findAccessibleWalletById(2L, 1L, WalletStatus.ACTIVE)).thenReturn(Optional.of(w1));
        when(categoryRepository.findAccessibleCategoryById(9L, 1L)).thenReturn(Optional.of(incomeCat));

        BudgetRequest incomeReq = new BudgetRequest();
        incomeReq.setWalletId(2L);
        incomeReq.setCategoryId(9L);
        incomeReq.setAmount(new BigDecimal("1000000"));
        assertEquals(HttpStatus.BAD_REQUEST, assertThrows(
                ResponseStatusException.class,
                () -> budgetService.createBudget(u, incomeReq)).getStatusCode());

        BudgetRequest zeroAmountReq = new BudgetRequest();
        zeroAmountReq.setWalletId(2L);
        zeroAmountReq.setAmount(BigDecimal.ZERO);
        assertEquals(HttpStatus.BAD_REQUEST, assertThrows(
                ResponseStatusException.class,
                () -> budgetService.createBudget(u, zeroAmountReq)).getStatusCode());

        BudgetRequest customNoEndReq = new BudgetRequest();
        customNoEndReq.setWalletId(2L);
        customNoEndReq.setAmount(new BigDecimal("1000000"));
        customNoEndReq.setPeriod(BudgetPeriod.CUSTOM);
        customNoEndReq.setStartDate(LocalDate.of(2026, 11, 1));
        assertEquals(HttpStatus.BAD_REQUEST, assertThrows(
                ResponseStatusException.class,
                () -> budgetService.createBudget(u, customNoEndReq)).getStatusCode());
    }

    @Test
    void getBudgetProgressCalculatesSeriesMilestonesAndOverLimit() {
        User u = user();
        Wallet w = wallet(2L, "Ví tiền mặt");
        Category food = expenseCategory(5L, "Ăn uống");
        Budget budget = Budget.builder()
                .budgetId(10L)
                .wallet(w)
                .category(food)
                .budgetName("Ăn uống")
                .amount(new BigDecimal("1000000.00"))
                .period(BudgetPeriod.MONTH)
                .startDate(LocalDate.of(2026, 11, 1))
                .endDate(LocalDate.of(2026, 11, 30))
                .alertPercent(new BigDecimal("80.00"))
                .status(BudgetStatus.ACTIVE)
                .createdBy(u)
                .build();

        Transaction tx1 = Transaction.builder()
                .transactionId(1L)
                .sourceWallet(w)
                .category(food)
                .amount(new BigDecimal("550000.00"))
                .transactionTime(LocalDateTime.of(2026, 11, 5, 12, 0))
                .build();
        Transaction tx2 = Transaction.builder()
                .transactionId(2L)
                .sourceWallet(w)
                .category(food)
                .amount(new BigDecimal("300000.00"))
                .transactionTime(LocalDateTime.of(2026, 11, 12, 18, 0))
                .build();

        when(budgetRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(budget));
        when(transactionRepository.findBudgetTransactions(eq(1L), eq(2L), eq(5L),
                eq(TransactionType.EXPENSE), eq(TransactionStatus.SUCCESS), any(), any()))
                .thenReturn(List.of(tx1, tx2));

        BudgetProgressResponse nearLimit = budgetService.getBudgetProgress(1L, 10L, LocalDate.of(2026, 11, 15));
        assertEquals(new BigDecimal("850000.00"), nearLimit.getSpentAmount());
        assertEquals(new BigDecimal("150000.00"), nearLimit.getRemainingAmount());
        assertEquals(85, nearLimit.getProgressPercent());
        assertEquals("NEAR_LIMIT", nearLimit.getHealthStatus());
        assertEquals(15, nearLimit.getDailySeries().size());
        assertEquals(3, nearLimit.getMilestones().size());
        assertTrue(nearLimit.getMilestones().get(0).isAchieved());
        assertTrue(nearLimit.getMilestones().get(1).isAchieved());
        assertFalse(nearLimit.getMilestones().get(2).isAchieved());
        assertNotNull(nearLimit.getProjectedExhaustionDate());

        Transaction tx3 = Transaction.builder()
                .transactionId(3L)
                .sourceWallet(w)
                .category(food)
                .amount(new BigDecimal("350000.00"))
                .transactionTime(LocalDateTime.of(2026, 11, 14, 19, 0))
                .build();
        when(transactionRepository.findBudgetTransactions(eq(1L), eq(2L), eq(5L),
                eq(TransactionType.EXPENSE), eq(TransactionStatus.SUCCESS), any(), any()))
                .thenReturn(List.of(tx1, tx2, tx3));

        BudgetProgressResponse overLimit = budgetService.getBudgetProgress(1L, 10L, LocalDate.of(2026, 11, 15));
        assertEquals("OVER_LIMIT", overLimit.getHealthStatus());
        assertEquals(new BigDecimal("200000.00"), overLimit.getOverLimitAmount());
        assertEquals(BigDecimal.ZERO, overLimit.getDailySuggested());
        assertTrue(overLimit.getMilestones().get(2).isAchieved());
    }

    @Test
    void updateAndDeleteBudgetRespectLifecycleStatus() {
        User u = user();
        Wallet w = wallet(2L, "Ví tiền mặt");
        Budget budget = Budget.builder()
                .budgetId(10L)
                .wallet(w)
                .budgetName("Ăn uống")
                .amount(new BigDecimal("1000000.00"))
                .period(BudgetPeriod.MONTH)
                .startDate(LocalDate.of(2026, 11, 1))
                .endDate(LocalDate.of(2026, 11, 30))
                .alertPercent(new BigDecimal("80.00"))
                .status(BudgetStatus.ACTIVE)
                .createdBy(u)
                .build();

        when(budgetRepository.findByIdAndUserId(10L, 1L)).thenReturn(Optional.of(budget));
        when(budgetRepository.save(any(Budget.class))).thenAnswer(inv -> inv.getArgument(0));
        when(transactionRepository.sumBudgetSpent(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(BigDecimal.ZERO);
        when(transactionRepository.findBudgetTransactions(any(), any(), any(), any(), any(), any(), any()))
                .thenReturn(List.of());

        BudgetRequest updateReq = new BudgetRequest();
        updateReq.setAmount(new BigDecimal("2500000"));
        updateReq.setAlertPercent(new BigDecimal("90"));
        BudgetResponse updated = budgetService.updateBudget(1L, 10L, updateReq);
        assertEquals(new BigDecimal("2500000.00"), updated.getAmount());
        assertEquals(new BigDecimal("90.00"), updated.getAlertPercent());

        budgetService.deleteBudget(1L, 10L);
        assertEquals(BudgetStatus.INACTIVE, budget.getStatus());
        verify(budgetRepository, times(2)).save(budget);

        BudgetRequest editAfterDelete = new BudgetRequest();
        editAfterDelete.setAmount(new BigDecimal("2000000"));
        assertEquals(HttpStatus.NOT_FOUND, assertThrows(
                ResponseStatusException.class,
                () -> budgetService.updateBudget(1L, 10L, editAfterDelete)).getStatusCode());
        assertEquals(HttpStatus.NOT_FOUND, assertThrows(
                ResponseStatusException.class,
                () -> budgetService.getBudgetById(1L, 10L)).getStatusCode());
    }
}
