package quanlychitieu.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

import lombok.Getter;
import lombok.Setter;
import quanlychitieu.enums.BudgetPeriod;
import quanlychitieu.enums.BudgetStatus;

@Getter
@Setter
@JsonIgnoreProperties(ignoreUnknown = true)
public class BudgetRequest {

    private Long walletId;
    private List<Long> walletIds;
    private Long categoryId;
    private String budgetName;
    private BigDecimal amount;
    private BudgetPeriod period;
    private LocalDate startDate;
    private LocalDate endDate;
    private BigDecimal alertPercent;
    private Boolean repeatMonthly;
    private BudgetStatus status;
}
