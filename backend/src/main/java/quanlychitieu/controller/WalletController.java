package quanlychitieu.controller;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import lombok.RequiredArgsConstructor;
import quanlychitieu.dto.WalletOptionDto;
import quanlychitieu.entity.User;
import quanlychitieu.enums.WalletStatus;
import quanlychitieu.service.CurrentUserResolver;
import quanlychitieu.service.WalletService;

@RestController
@RequestMapping("/api/wallets")
@RequiredArgsConstructor
public class WalletController {

    private final WalletService walletService;
    private final CurrentUserResolver currentUserResolver;

    @GetMapping
    public ResponseEntity<List<WalletOptionDto>> getWallets(
            @RequestParam(required = false) Long userId,
            @RequestHeader(value = "X-User-Id", required = false) Long headerUserId,
            @RequestParam(required = false) WalletStatus status) {
        User user = currentUserResolver.resolveUser(userId, headerUserId);
        return ResponseEntity.ok(walletService.getWallets(user.getUserId(), status));
    }
}
