package quanlychitieu.dto;

import java.math.BigDecimal;

import lombok.Builder;
import lombok.Getter;
import quanlychitieu.enums.WalletType;

@Getter
@Builder
public class WalletOptionDto {

    private Long walletId;
    private String walletName;
    private BigDecimal balance;
    private String currency;
    private WalletType walletType;
}
