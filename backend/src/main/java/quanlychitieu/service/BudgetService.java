package quanlychitieu.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Collectors;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import lombok.RequiredArgsConstructor;
import quanlychitieu.dto.BudgetDailyPointDto;
import quanlychitieu.dto.BudgetMilestoneDto;
import quanlychitieu.dto.BudgetPeriodFilterDto;
import quanlychitieu.dto.BudgetProgressResponse;
import quanlychitieu.dto.BudgetRequest;
import quanlychitieu.dto.BudgetResponse;
import quanlychitieu.dto.BudgetTransactionDto;
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
import quanlychitieu.repository.BudgetRepository;
import quanlychitieu.repository.CategoryRepository;
import quanlychitieu.repository.TransactionRepository;
import quanlychitieu.repository.WalletRepository;

@Service
@RequiredArgsConstructor
public class BudgetService {

    private static final BigDecimal DEFAULT_ALERT_PERCENT = new BigDecimal("80.00");
    private static final BigDecimal ONE_HUNDRED = new BigDecimal("100");
    private static final LocalTime END_OF_DAY = LocalTime.of(23, 59, 59);

    private final BudgetRepository budgetRepository;
    private final CategoryRepository categoryRepository;
    private final WalletRepository walletRepository;
    private final TransactionRepository transactionRepository;

    @Transactional(readOnly = true)
    public List<BudgetPeriodFilterDto> getPeriodFilters(Long userId) {
        YearMonth current = YearMonth.now();
        Set<YearMonth> months = new LinkedHashSet<>();
        months.add(current);
        months.add(current.minusMonths(1));
        months.add(current.plusMonths(1));

        List<Budget> activeBudgets = budgetRepository.findActiveByUserId(userId, BudgetStatus.ACTIVE);
        activeBudgets.stream()
                .map(b -> YearMonth.from(b.getStartDate()))
                .sorted(Comparator.reverseOrder())
                .forEach(months::add);

        return months.stream()
                .map(this::toPeriodFilterDto)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<BudgetResponse> getBudgets(
            Long userId,
            String periodFilterId,
            LocalDate startDate,
            LocalDate endDate,
            Long walletId,
            BudgetStatus status) {
        BudgetStatus targetStatus = status != null ? status : BudgetStatus.ACTIVE;
        DateRange filterRange = resolveFilterRange(periodFilterId, startDate, endDate);

        List<Budget> budgets = budgetRepository.findActiveByUserId(userId, targetStatus);
        return budgets.stream()
                .filter(budget -> walletId == null || budget.getWallet().getWalletId().equals(walletId))
                .filter(budget -> matchesDateRange(budget, filterRange))
                .map(budget -> toBudgetResponse(budget, userId, true))
                .toList();
    }

    @Transactional(readOnly = true)
    public BudgetResponse getBudgetById(Long userId, Long budgetId) {
        Budget budget = getOwnedActiveBudget(userId, budgetId);
        return toBudgetResponse(budget, userId, true);
    }

    @Transactional(readOnly = true)
    public BudgetProgressResponse getBudgetProgress(
            Long userId,
            Long budgetId,
            LocalDate referenceDate) {
        Budget budget = getOwnedActiveBudget(userId, budgetId);
        LocalDate start = budget.getStartDate();
        LocalDate end = resolveEffectiveEndDate(budget.getPeriod(), start, budget.getEndDate());
        LocalDate today = referenceDate != null ? referenceDate : LocalDate.now();

        long totalDays = Math.max(1, ChronoUnit.DAYS.between(start, end) + 1);
        long rawElapsed = ChronoUnit.DAYS.between(start, today);
        long elapsedDays = Math.max(1, Math.min(totalDays, rawElapsed));
        long remainingDays = Math.max(0, ChronoUnit.DAYS.between(today, end) + 1);

        Long categoryId = budget.getCategory() != null ? budget.getCategory().getCategoryId() : null;
        List<Transaction> transactions = transactionRepository.findBudgetTransactions(
                userId,
                budget.getWallet().getWalletId(),
                categoryId,
                TransactionType.EXPENSE,
                TransactionStatus.SUCCESS,
                start.atStartOfDay(),
                end.atTime(END_OF_DAY));

        Map<LocalDate, BigDecimal> dailyTotals = transactions.stream()
                .collect(Collectors.groupingBy(
                        t -> t.getTransactionTime().toLocalDate(),
                        Collectors.reducing(BigDecimal.ZERO, Transaction::getAmount, BigDecimal::add)));

        LocalDate seriesEnd = today.isBefore(start) ? start : (today.isAfter(end) ? end : today);
        List<BudgetDailyPointDto> dailySeries = new ArrayList<>();
        BigDecimal cumulative = BigDecimal.ZERO;
        LocalDate cursor = start;
        while (!cursor.isAfter(seriesEnd)) {
            BigDecimal daySpent = dailyTotals.getOrDefault(cursor, BigDecimal.ZERO);
            cumulative = cumulative.add(daySpent);
            dailySeries.add(BudgetDailyPointDto.builder()
                    .date(cursor)
                    .dailyAmount(daySpent)
                    .cumulativeAmount(cumulative)
                    .build());
            cursor = cursor.plusDays(1);
        }

        BigDecimal spentAmount = cumulative;
        BigDecimal limitAmount = budget.getAmount();
        BigDecimal remainingAmount = limitAmount.subtract(spentAmount);
        BigDecimal overLimitAmount = spentAmount.compareTo(limitAmount) > 0
                ? spentAmount.subtract(limitAmount)
                : BigDecimal.ZERO;

        int progressPercent = limitAmount.compareTo(BigDecimal.ZERO) > 0
                ? spentAmount.multiply(ONE_HUNDRED).divide(limitAmount, 0, RoundingMode.HALF_UP).intValue()
                : 0;

        BigDecimal dailyAverage = spentAmount.divide(BigDecimal.valueOf(elapsedDays), 2, RoundingMode.HALF_UP);
        BigDecimal dailySuggested;
        if (remainingAmount.compareTo(BigDecimal.ZERO) <= 0) {
            dailySuggested = BigDecimal.ZERO;
        } else if (remainingDays <= 0) {
            dailySuggested = remainingAmount;
        } else {
            dailySuggested = remainingAmount.divide(BigDecimal.valueOf(remainingDays), 2, RoundingMode.HALF_UP);
        }

        LocalDate projectedExhaustionDate = null;
        if (dailyAverage.compareTo(BigDecimal.ZERO) > 0 && limitAmount.compareTo(BigDecimal.ZERO) > 0) {
            if (spentAmount.compareTo(limitAmount) >= 0) {
                projectedExhaustionDate = today;
            } else {
                long daysAtPace = (long) Math.ceil(
                        limitAmount.subtract(spentAmount).doubleValue() / dailyAverage.doubleValue());
                projectedExhaustionDate = today.plusDays(daysAtPace);
            }
        }

        BigDecimal alertPercent = budget.getAlertPercent() != null
                ? budget.getAlertPercent()
                : DEFAULT_ALERT_PERCENT;
        List<BudgetMilestoneDto> milestones = buildMilestones(
                limitAmount,
                spentAmount,
                alertPercent.intValue(),
                dailyAverage,
                today,
                dailySeries);

        String healthStatus;
        if (progressPercent > 100) {
            healthStatus = "OVER_LIMIT";
        } else if (progressPercent >= alertPercent.intValue()) {
            healthStatus = "NEAR_LIMIT";
        } else {
            healthStatus = "ON_TRACK";
        }

        String categoryName = budget.getCategory() != null
                ? budget.getCategory().getCategoryName()
                : budget.getBudgetName();

        return BudgetProgressResponse.builder()
                .budgetId(budget.getBudgetId())
                .budgetName(budget.getBudgetName())
                .categoryName(categoryName)
                .period(budget.getPeriod())
                .startDate(start)
                .endDate(end)
                .limitAmount(limitAmount)
                .spentAmount(spentAmount)
                .remainingAmount(remainingAmount)
                .overLimitAmount(overLimitAmount)
                .progressPercent(progressPercent)
                .alertPercent(alertPercent)
                .healthStatus(healthStatus)
                .totalDays(totalDays)
                .elapsedDays(elapsedDays)
                .remainingDays(remainingDays)
                .dailyAverage(dailyAverage)
                .dailySuggested(dailySuggested)
                .projectedExhaustionDate(projectedExhaustionDate)
                .dailySeries(dailySeries)
                .milestones(milestones)
                .build();
    }

    @Transactional
    public BudgetResponse createBudget(User user, BudgetRequest request) {
        if (request == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dữ liệu tạo ngân sách không được để trống");
        }

        Wallet primaryWallet = resolvePrimaryWallet(user.getUserId(), request);
        Category category = resolveCategory(user.getUserId(), request.getCategoryId());
        BigDecimal amount = validateAmount(request.getAmount());
        BudgetPeriod period = request.getPeriod() != null ? request.getPeriod() : BudgetPeriod.MONTH;
        LocalDate startDate = request.getStartDate() != null ? request.getStartDate() : LocalDate.now().withDayOfMonth(1);
        LocalDate endDate = resolveEndDateForWrite(period, startDate, request.getEndDate());
        BigDecimal alertPercent = validateAlertPercent(request.getAlertPercent());
        String budgetName = resolveBudgetName(request.getBudgetName(), category);
        boolean repeatMonthly = request.getRepeatMonthly() == null || request.getRepeatMonthly();

        Budget budget = Budget.builder()
                .wallet(primaryWallet)
                .category(category)
                .budgetName(budgetName)
                .amount(amount)
                .period(period)
                .startDate(startDate)
                .endDate(endDate)
                .alertPercent(alertPercent)
                .status(BudgetStatus.ACTIVE)
                .createdBy(user)
                .build();

        Budget saved = budgetRepository.save(budget);
        return toBudgetResponse(saved, user.getUserId(), repeatMonthly);
    }

    @Transactional
    public BudgetResponse updateBudget(Long userId, Long budgetId, BudgetRequest request) {
        if (request == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Dữ liệu cập nhật ngân sách không được để trống");
        }

        Budget budget = budgetRepository.findByIdAndUserId(budgetId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy ngân sách với ID: " + budgetId));
        if (budget.getStatus() != BudgetStatus.ACTIVE && request.getStatus() != BudgetStatus.ACTIVE) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Ngân sách đã bị xóa hoặc không còn hoạt động");
        }

        if (request.getWalletId() != null || (request.getWalletIds() != null && !request.getWalletIds().isEmpty())) {
            budget.setWallet(resolvePrimaryWallet(userId, request));
        }

        if (request.getCategoryId() != null) {
            budget.setCategory(resolveCategory(userId, request.getCategoryId()));
        }

        if (request.getAmount() != null) {
            budget.setAmount(validateAmount(request.getAmount()));
        }

        BudgetPeriod nextPeriod = request.getPeriod() != null ? request.getPeriod() : budget.getPeriod();
        LocalDate nextStart = request.getStartDate() != null ? request.getStartDate() : budget.getStartDate();
        LocalDate nextEnd = request.getEndDate() != null
                ? resolveEndDateForWrite(nextPeriod, nextStart, request.getEndDate())
                : (request.getPeriod() != null || request.getStartDate() != null
                        ? resolveEndDateForWrite(nextPeriod, nextStart, null)
                        : budget.getEndDate());

        budget.setPeriod(nextPeriod);
        budget.setStartDate(nextStart);
        budget.setEndDate(nextEnd);

        if (request.getAlertPercent() != null) {
            budget.setAlertPercent(validateAlertPercent(request.getAlertPercent()));
        }

        if (request.getBudgetName() != null && !request.getBudgetName().trim().isEmpty()) {
            budget.setBudgetName(request.getBudgetName().trim());
        } else if (budget.getBudgetName() == null || budget.getBudgetName().isBlank()) {
            budget.setBudgetName(resolveBudgetName(null, budget.getCategory()));
        }

        if (request.getStatus() != null) {
            budget.setStatus(request.getStatus());
        }

        boolean repeatMonthly = request.getRepeatMonthly() == null || request.getRepeatMonthly();
        Budget saved = budgetRepository.save(budget);
        return toBudgetResponse(saved, userId, repeatMonthly);
    }

    @Transactional
    public void deleteBudget(Long userId, Long budgetId) {
        Budget budget = getOwnedActiveBudget(userId, budgetId);
        budget.setStatus(BudgetStatus.INACTIVE);
        budgetRepository.save(budget);
    }

    private Budget getOwnedActiveBudget(Long userId, Long budgetId) {
        Budget budget = budgetRepository.findByIdAndUserId(budgetId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Không tìm thấy ngân sách với ID: " + budgetId));
        if (budget.getStatus() != BudgetStatus.ACTIVE) {
            throw new ResponseStatusException(
                    HttpStatus.NOT_FOUND,
                    "Ngân sách đã bị xóa hoặc không còn hoạt động");
        }
        return budget;
    }

    private Wallet resolvePrimaryWallet(Long userId, BudgetRequest request) {
        Long targetWalletId = request.getWalletId();
        if (targetWalletId == null && request.getWalletIds() != null && !request.getWalletIds().isEmpty()) {
            targetWalletId = request.getWalletIds().get(0);
        }
        if (targetWalletId == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng chọn ít nhất một ví áp dụng");
        }

        if (request.getWalletIds() != null) {
            for (Long wId : request.getWalletIds()) {
                if (wId != null) {
                    walletRepository.findAccessibleWalletById(wId, userId, WalletStatus.ACTIVE)
                            .orElseThrow(() -> new ResponseStatusException(
                                    HttpStatus.BAD_REQUEST,
                                    "Ví không hợp lệ hoặc không thuộc quyền truy cập: " + wId));
                }
            }
        }

        Long finalWalletId = targetWalletId;
        return walletRepository.findAccessibleWalletById(finalWalletId, userId, WalletStatus.ACTIVE)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Không tìm thấy ví hoạt động với ID: " + finalWalletId));
    }

    private Category resolveCategory(Long userId, Long categoryId) {
        if (categoryId == null) {
            return null;
        }
        Category category = categoryRepository.findAccessibleCategoryById(categoryId, userId)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Không tìm thấy danh mục với ID: " + categoryId));
        if (category.getCategoryType() != CategoryType.EXPENSE) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ngân sách chỉ hỗ trợ danh mục chi tiêu (EXPENSE)");
        }
        return category;
    }

    private BigDecimal validateAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Hạn mức ngân sách phải lớn hơn 0");
        }
        return amount.setScale(2, RoundingMode.HALF_UP);
    }

    private BigDecimal validateAlertPercent(BigDecimal alertPercent) {
        if (alertPercent == null) {
            return DEFAULT_ALERT_PERCENT;
        }
        if (alertPercent.compareTo(BigDecimal.ONE) < 0 || alertPercent.compareTo(ONE_HUNDRED) > 0) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Ngưỡng cảnh báo phải nằm trong khoảng từ 1% đến 100%");
        }
        return alertPercent.setScale(2, RoundingMode.HALF_UP);
    }

    private String resolveBudgetName(String requestedName, Category category) {
        if (requestedName != null && !requestedName.trim().isEmpty()) {
            return requestedName.trim();
        }
        if (category != null) {
            return category.getCategoryName();
        }
        return "Ngân sách chi tiêu";
    }

    private LocalDate resolveEndDateForWrite(BudgetPeriod period, LocalDate startDate, LocalDate requestedEndDate) {
        if (requestedEndDate != null) {
            if (requestedEndDate.isBefore(startDate)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Ngày kết thúc không được nhỏ hơn ngày bắt đầu");
            }
            return requestedEndDate;
        }
        if (period == BudgetPeriod.CUSTOM) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Kỳ tùy chỉnh bắt buộc phải có ngày kết thúc");
        }
        return resolveEffectiveEndDate(period, startDate, null);
    }

    private LocalDate resolveEffectiveEndDate(BudgetPeriod period, LocalDate startDate, LocalDate storedEndDate) {
        if (storedEndDate != null) {
            return storedEndDate;
        }
        return switch (period) {
            case DAY -> startDate;
            case WEEK -> startDate.plusDays(6);
            case MONTH -> startDate.withDayOfMonth(startDate.lengthOfMonth());
            case YEAR -> startDate.withMonth(12).withDayOfMonth(31);
            case CUSTOM -> startDate;
        };
    }

    private DateRange resolveFilterRange(String periodFilterId, LocalDate startDate, LocalDate endDate) {
        if (startDate != null || endDate != null) {
            LocalDate effectiveStart = startDate != null ? startDate : endDate.withDayOfMonth(1);
            LocalDate effectiveEnd = endDate != null
                    ? endDate
                    : effectiveStart.withDayOfMonth(effectiveStart.lengthOfMonth());
            if (effectiveEnd.isBefore(effectiveStart)) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "endDate không được nhỏ hơn startDate");
            }
            return new DateRange(effectiveStart, effectiveEnd);
        }

        if (periodFilterId != null && !periodFilterId.isBlank()
                && !"ALL".equalsIgnoreCase(periodFilterId.trim())) {
            try {
                YearMonth ym = YearMonth.parse(periodFilterId.trim());
                return new DateRange(ym.atDay(1), ym.atEndOfMonth());
            } catch (DateTimeParseException ex) {
                throw new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "periodFilterId không đúng định dạng yyyy-MM: " + periodFilterId);
            }
        }
        return null;
    }

    private boolean matchesDateRange(Budget budget, DateRange range) {
        if (range == null) {
            return true;
        }
        LocalDate budgetEnd = resolveEffectiveEndDate(budget.getPeriod(), budget.getStartDate(), budget.getEndDate());
        return !budgetEnd.isBefore(range.start()) && !budget.getStartDate().isAfter(range.end());
    }

    private BudgetPeriodFilterDto toPeriodFilterDto(YearMonth ym) {
        return BudgetPeriodFilterDto.builder()
                .id(ym.toString())
                .label("Tháng " + ym.getMonthValue() + "/" + ym.getYear())
                .summaryHeading("Tổng chi tháng " + ym.getMonthValue())
                .startDate(ym.atDay(1))
                .endDate(ym.atEndOfMonth())
                .build();
    }

    private BudgetResponse toBudgetResponse(Budget budget, Long userId, boolean repeatMonthly) {
        LocalDate effectiveEnd = resolveEffectiveEndDate(
                budget.getPeriod(),
                budget.getStartDate(),
                budget.getEndDate());
        LocalDateTime startTime = budget.getStartDate().atStartOfDay();
        LocalDateTime endTime = effectiveEnd.atTime(END_OF_DAY);

        Long walletId = budget.getWallet().getWalletId();
        Long categoryId = budget.getCategory() != null ? budget.getCategory().getCategoryId() : null;
        String categoryName = budget.getCategory() != null ? budget.getCategory().getCategoryName() : null;

        BigDecimal spentAmount = transactionRepository.sumBudgetSpent(
                userId,
                walletId,
                categoryId,
                TransactionType.EXPENSE,
                TransactionStatus.SUCCESS,
                startTime,
                endTime);
        if (spentAmount == null) {
            spentAmount = BigDecimal.ZERO;
        }

        List<BudgetTransactionDto> transactionDtos = transactionRepository.findBudgetTransactions(
                userId,
                walletId,
                categoryId,
                TransactionType.EXPENSE,
                TransactionStatus.SUCCESS,
                startTime,
                endTime)
                .stream()
                .map(tx -> toTransactionDto(tx, categoryName, budget.getBudgetName()))
                .toList();

        return BudgetResponse.builder()
                .budgetId(budget.getBudgetId())
                .walletId(walletId)
                .walletIds(List.of(walletId))
                .categoryId(categoryId)
                .categoryName(categoryName)
                .budgetName(budget.getBudgetName())
                .amount(budget.getAmount())
                .spentAmount(spentAmount)
                .period(budget.getPeriod())
                .startDate(budget.getStartDate())
                .endDate(effectiveEnd)
                .alertPercent(budget.getAlertPercent())
                .status(budget.getStatus())
                .repeatMonthly(repeatMonthly)
                .transactions(transactionDtos)
                .build();
    }

    private BudgetTransactionDto toTransactionDto(
            Transaction tx,
            String fallbackCategoryName,
            String fallbackBudgetName) {
        String title = tx.getDescription();
        if (title == null || title.isBlank()) {
            title = fallbackCategoryName != null ? fallbackCategoryName : fallbackBudgetName;
        }
        Long txWalletId = tx.getSourceWallet() != null ? tx.getSourceWallet().getWalletId() : null;
        String txWalletName = tx.getSourceWallet() != null ? tx.getSourceWallet().getWalletName() : "";
        BigDecimal signedAmount = tx.getAmount() != null ? tx.getAmount().negate() : BigDecimal.ZERO;

        return BudgetTransactionDto.builder()
                .transactionId(tx.getTransactionId())
                .title(title)
                .walletId(txWalletId)
                .walletName(txWalletName)
                .transactionTime(tx.getTransactionTime())
                .amount(signedAmount)
                .build();
    }

    private List<BudgetMilestoneDto> buildMilestones(
            BigDecimal limitAmount,
            BigDecimal spentAmount,
            int alertPercent,
            BigDecimal dailyAverage,
            LocalDate today,
            List<BudgetDailyPointDto> series) {
        Set<Integer> percents = new TreeSet<>();
        percents.add(50);
        percents.add(alertPercent);
        percents.add(100);

        List<BudgetMilestoneDto> milestones = new ArrayList<>();
        for (int percent : percents) {
            BigDecimal target = limitAmount
                    .multiply(BigDecimal.valueOf(percent))
                    .divide(ONE_HUNDRED, 2, RoundingMode.HALF_UP);

            LocalDate achievedDate = null;
            for (BudgetDailyPointDto point : series) {
                if (point.getCumulativeAmount().compareTo(target) >= 0) {
                    achievedDate = point.getDate();
                    break;
                }
            }

            LocalDate projectedDate = null;
            if (achievedDate == null && dailyAverage.compareTo(BigDecimal.ZERO) > 0) {
                long daysToReach = (long) Math.ceil(
                        target.subtract(spentAmount).doubleValue() / dailyAverage.doubleValue());
                projectedDate = today.plusDays(Math.max(0, daysToReach));
            }

            milestones.add(BudgetMilestoneDto.builder()
                    .percent(percent)
                    .targetAmount(target)
                    .achievedDate(achievedDate)
                    .projectedDate(projectedDate)
                    .achieved(achievedDate != null)
                    .build());
        }
        return milestones;
    }

    private record DateRange(LocalDate start, LocalDate end) {
    }
}
