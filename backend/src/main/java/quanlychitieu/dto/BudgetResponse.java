package quanlychitieu.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import lombok.Builder;
import lombok.Getter;
import quanlychitieu.enums.BudgetPeriod;
import quanlychitieu.enums.BudgetStatus;

@Getter
@Builder
public class BudgetResponse {

    private Long budgetId;
    private Long walletId;
    private List<Long> walletIds;
    private Long categoryId;
    private String categoryName;
    private String budgetName;
    private BigDecimal amount;
    private BigDecimal spentAmount;
    private BudgetPeriod period;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal alertPercent;
    private BudgetStatus status;
    private boolean repeatMonthly;
    private List<BudgetTransactionDto> transactions;
}
