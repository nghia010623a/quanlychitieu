package quanlychitieu.entity;

// File 1: FriendshipId.java
import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.*;

import java.io.Serializable;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class FriendshipId implements Serializable {

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "friend_user_id")
    private Long friendUserId;
}