package quanlychitieu.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import quanlychitieu.dto.CategoryDto;
import quanlychitieu.dto.WalletOptionDto;
import quanlychitieu.entity.Category;
import quanlychitieu.entity.User;
import quanlychitieu.entity.Wallet;
import quanlychitieu.enums.CategoryType;
import quanlychitieu.enums.UserStatus;
import quanlychitieu.enums.WalletStatus;
import quanlychitieu.enums.WalletType;
import quanlychitieu.repository.CategoryRepository;
import quanlychitieu.repository.UserRepo;
import quanlychitieu.repository.WalletRepository;

@ExtendWith(MockitoExtension.class)
class SupportServicesTest {

    @Mock
    private CategoryRepository categoryRepository;

    @Mock
    private WalletRepository walletRepository;

    @Mock
    private UserRepo userRepo;

    @InjectMocks
    private CategoryService categoryService;

    @InjectMocks
    private WalletService walletService;

    @InjectMocks
    private CurrentUserResolver currentUserResolver;

    @Test
    void categoryServiceDefaultsToExpenseAndMapsFields() {
        when(categoryRepository.findAvailableCategories(1L, CategoryType.EXPENSE)).thenReturn(List.of(
                Category.builder()
                        .categoryId(5L)
                        .categoryName("Ăn uống")
                        .categoryType(CategoryType.EXPENSE)
                        .isDefault(true)
                        .build()));

        List<CategoryDto> result = categoryService.getAvailableCategories(1L, null);

        assertEquals(1, result.size());
        assertEquals(5L, result.get(0).getCategoryId());
        assertEquals("Ăn uống", result.get(0).getCategoryName());
        assertEquals(CategoryType.EXPENSE, result.get(0).getCategoryType());
        assertEquals(true, result.get(0).getIsDefault());
    }

    @Test
    void walletServiceDefaultsToActiveAndIncludesPersonalAndGroupWallets() {
        when(walletRepository.findAccessibleWallets(1L, WalletStatus.ACTIVE)).thenReturn(List.of(
                Wallet.builder()
                        .walletId(2L)
                        .walletName("Ví tiền mặt")
                        .balance(new BigDecimal("1200000.00"))
                        .currency("VND")
                        .walletType(WalletType.PERSONAL)
                        .status(WalletStatus.ACTIVE)
                        .build(),
                Wallet.builder()
                        .walletId(9L)
                        .walletName("Quỹ nhóm du lịch")
                        .balance(new BigDecimal("5000000.00"))
                        .currency("VND")
                        .walletType(WalletType.GROUP)
                        .status(WalletStatus.ACTIVE)
                        .build()));

        List<WalletOptionDto> result = walletService.getWallets(1L, null);

        assertEquals(2, result.size());
        assertEquals(WalletType.PERSONAL, result.get(0).getWalletType());
        assertEquals(WalletType.GROUP, result.get(1).getWalletType());
    }

    @Test
    void currentUserResolverRespectsPriorityAndRejectsInactiveUsers() {
        User activeQueryUser = User.builder().userId(10L).status(UserStatus.ACTIVE).build();
        User activeHeaderUser = User.builder().userId(20L).status(UserStatus.ACTIVE).build();
        User defaultUser = User.builder().userId(1L).status(UserStatus.ACTIVE).build();
        User lockedUser = User.builder().userId(30L).status(UserStatus.LOCKED).build();

        when(userRepo.findById(10L)).thenReturn(Optional.of(activeQueryUser));
        when(userRepo.findById(20L)).thenReturn(Optional.of(activeHeaderUser));
        when(userRepo.findById(30L)).thenReturn(Optional.of(lockedUser));
        when(userRepo.findById(99L)).thenReturn(Optional.empty());
        when(userRepo.findFirstByStatusOrderByUserIdAsc(UserStatus.ACTIVE)).thenReturn(Optional.of(defaultUser));

        assertEquals(10L, currentUserResolver.resolveUser(10L, 20L).getUserId());
        assertEquals(20L, currentUserResolver.resolveUser(null, 20L).getUserId());
        assertEquals(1L, currentUserResolver.resolveUser(null, null).getUserId());

        ResponseStatusException forbidden = assertThrows(
                ResponseStatusException.class,
                () -> currentUserResolver.resolveUser(30L, null));
        assertEquals(HttpStatus.FORBIDDEN, forbidden.getStatusCode());

        ResponseStatusException notFound = assertThrows(
                ResponseStatusException.class,
                () -> currentUserResolver.resolveUser(99L, null));
        assertEquals(HttpStatus.NOT_FOUND, notFound.getStatusCode());
    }
}
