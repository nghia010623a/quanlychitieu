package quanlychitieu.service;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import lombok.RequiredArgsConstructor;
import quanlychitieu.entity.User;
import quanlychitieu.enums.UserStatus;
import quanlychitieu.repository.UserRepo;

@Service
@RequiredArgsConstructor
public class CurrentUserResolver {

    private final UserRepo userRepo;

    public User resolveUser(Long queryUserId, Long headerUserId) {
        Long targetId = queryUserId != null ? queryUserId : headerUserId;
        if (targetId != null) {
            User user = userRepo.findById(targetId)
                    .orElseThrow(() -> new ResponseStatusException(
                            HttpStatus.NOT_FOUND,
                            "Không tìm thấy người dùng với ID: " + targetId));
            if (user.getStatus() != UserStatus.ACTIVE) {
                throw new ResponseStatusException(
                        HttpStatus.FORBIDDEN,
                        "Tài khoản người dùng hiện không hoạt động");
            }
            return user;
        }

        return userRepo.findFirstByStatusOrderByUserIdAsc(UserStatus.ACTIVE)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.BAD_REQUEST,
                        "Thiếu userId và không có tài khoản ACTIVE mặc định"));
    }
}
