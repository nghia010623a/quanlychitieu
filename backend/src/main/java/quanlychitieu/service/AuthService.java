package quanlychitieu.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import quanlychitieu.entity.User;
import quanlychitieu.repository.UserRepo;
@Service
public class AuthService {
    @Autowired UserRepo userRepo;
    public ResponseEntity login(String nickname, String password) {
        if(userRepo.findByNickname(nickname,password)!=null) {
            User user = userRepo.findByNickname(nickname,password);
            return ResponseEntity.ok(user);
        }
        else  {
            return ResponseEntity.badRequest().build();
        }
    }
}
