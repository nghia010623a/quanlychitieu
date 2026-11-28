package quanlychitieu.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;
import quanlychitieu.dto.WalletOptionDto;
import quanlychitieu.entity.Wallet;
import quanlychitieu.enums.WalletStatus;
import quanlychitieu.repository.WalletRepository;

@Service
@RequiredArgsConstructor
public class WalletService {

    private final WalletRepository walletRepository;

    @Transactional(readOnly = true)
    public List<WalletOptionDto> getWallets(Long userId, WalletStatus status) {
        WalletStatus targetStatus = status != null ? status : WalletStatus.ACTIVE;
        return walletRepository.findAccessibleWallets(userId, targetStatus)
                .stream()
                .map(this::toDto)
                .toList();
    }

    private WalletOptionDto toDto(Wallet wallet) {
        return WalletOptionDto.builder()
                .walletId(wallet.getWalletId())
                .walletName(wallet.getWalletName())
                .balance(wallet.getBalance())
                .currency(wallet.getCurrency())
                .walletType(wallet.getWalletType())
                .build();
    }
}
