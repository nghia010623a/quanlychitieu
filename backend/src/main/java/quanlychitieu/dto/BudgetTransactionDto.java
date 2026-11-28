package quanlychitieu.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class BudgetTransactionDto {

    private Long transactionId;
    private String title;
    private Long walletId;
    private String walletName;
    private LocalDateTime transactionTime;
    private BigDecimal amount;
}
