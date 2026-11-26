package quanlychitieu.controller;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import quanlychitieu.entity.User;
import quanlychitieu.service.AuthService;
@RestController
@RequestMapping("/api/auth")
public class AuthController
{
    @Autowired
    private AuthService authService;
    @PostMapping("/login")
    public ResponseEntity auth(@RequestBody User user)
    {
        if(user==null)
        {
            return ResponseEntity.badRequest().build();
        }
        else
        {
           return authService.login(user.getNickname(), user.getPasswordHash());
        }
    }
}
