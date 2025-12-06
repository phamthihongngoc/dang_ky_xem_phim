-- Tạo database
CREATE DATABASE IF NOT EXISTS cinema
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE cinema;

-- Bảng người dùng (thêm role)
CREATE TABLE IF NOT EXISTS Users (
    email VARCHAR(100) PRIMARY KEY,
    password VARCHAR(100) NOT NULL,
    fullname VARCHAR(100) NOT NULL,
    role ENUM('user', 'admin') DEFAULT 'user',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng phòng chiếu
CREATE TABLE IF NOT EXISTS Rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    total_rows INT NOT NULL,
    total_cols INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng suất chiếu (thêm thông tin phim và phòng)
CREATE TABLE IF NOT EXISTS Shows (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    director VARCHAR(100),
    genre VARCHAR(100),
    showtime DATETIME NOT NULL,
    room_id INT NOT NULL,
    poster VARCHAR(255),
    trailer VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id) REFERENCES Rooms(id) ON DELETE CASCADE,
    INDEX idx_showtime (showtime),
    INDEX idx_room (room_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng loại ghế
CREATE TABLE IF NOT EXISTS SeatTypes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    price INT NOT NULL,
    color VARCHAR(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng cấu hình ghế cho mỗi phòng
CREATE TABLE IF NOT EXISTS RoomSeats (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room_id INT NOT NULL,
    seat_row INT NOT NULL,
    seat_col INT NOT NULL,
    seat_type_id INT NOT NULL,
    FOREIGN KEY (room_id) REFERENCES Rooms(id) ON DELETE CASCADE,
    FOREIGN KEY (seat_type_id) REFERENCES SeatTypes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_seat (room_id, seat_row, seat_col)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng đặt ghế (thêm loại ghế và giá)
CREATE TABLE IF NOT EXISTS Bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    show_id INT NOT NULL,
    email VARCHAR(100) NOT NULL,
    seat_row INT NOT NULL,
    seat_col INT NOT NULL,
    seat_type_id INT NOT NULL,
    price INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (show_id) REFERENCES Shows(id) ON DELETE CASCADE,
    FOREIGN KEY (email) REFERENCES Users(email) ON DELETE CASCADE,
    FOREIGN KEY (seat_type_id) REFERENCES SeatTypes(id) ON DELETE CASCADE,
    UNIQUE KEY unique_booking (show_id, seat_row, seat_col)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng combo bắp nước
CREATE TABLE IF NOT EXISTS Combos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price INT NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng order combo
CREATE TABLE IF NOT EXISTS OrderCombos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    show_id INT NOT NULL,
    email VARCHAR(100) NOT NULL,
    combo_id INT NOT NULL,
    quantity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (show_id) REFERENCES Shows(id) ON DELETE CASCADE,
    FOREIGN KEY (email) REFERENCES Users(email) ON DELETE CASCADE,
    FOREIGN KEY (combo_id) REFERENCES Combos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng khuyến mãi
CREATE TABLE IF NOT EXISTS Promotions (
    code VARCHAR(50) PRIMARY KEY,
    discount INT NOT NULL,
    expiry DATE NOT NULL,
    CHECK (discount BETWEEN 0 AND 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bảng liên kết booking với mã khuyến mãi
CREATE TABLE IF NOT EXISTS BookingPromos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    show_id INT NOT NULL,
    email VARCHAR(100) NOT NULL,
    promo_code VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (show_id) REFERENCES Shows(id) ON DELETE CASCADE,
    FOREIGN KEY (email) REFERENCES Users(email) ON DELETE CASCADE,
    FOREIGN KEY (promo_code) REFERENCES Promotions(code) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -----------------------------------------------------
-- Dữ liệu mẫu
-- -----------------------------------------------------

-- Admin và user mẫubookings
INSERT INTO Users(email, password, fullname, role) VALUES
('admin@cinema.com', 'admin123', 'Administrator', 'admin'),
('ngoc@gmail.com', '123456', 'NgocDay', 'user')
ON DUPLICATE KEY UPDATE role=role;

-- Loại ghế
INSERT INTO SeatTypes(name, price, color) VALUES
('Thường', 70000, '#BBF7D0'),
('VIP', 120000, '#FDE68A'),
('Đôi', 200000, '#FCA5A5')
ON DUPLICATE KEY UPDATE price=price;

-- Phòng chiếu mẫu
INSERT INTO Rooms(name, total_rows, total_cols) VALUES
('Phòng 1', 8, 10),
('Phòng 2', 6, 9),
('Phòng VIP', 5, 8)
ON DUPLICATE KEY UPDATE total_rows=total_rows;

-- Cấu hình ghế cho Phòng 1 (8x10)
INSERT IGNORE INTO RoomSeats(room_id, seat_row, seat_col, seat_type_id)
SELECT 1, r, c,
  CASE
    WHEN r IN (0,1,7) THEN 1
    WHEN r IN (2,3,4,5) THEN 2
    WHEN r = 6 AND c MOD 2 = 0 THEN 3
    ELSE 1
  END AS seat_type
FROM
  (SELECT 0 AS r UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
   UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7) AS row_nums
CROSS JOIN
  (SELECT 0 AS c UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
   UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
   UNION ALL SELECT 8 UNION ALL SELECT 9) AS col_nums
WHERE NOT (r = 6 AND c MOD 2 = 1);

-- Cấu hình ghế cho Phòng 2 (6x9)
INSERT IGNORE INTO RoomSeats(room_id, seat_row, seat_col, seat_type_id)
SELECT 2, r, c,
  CASE
    WHEN r IN (0,1) THEN 1
    WHEN r IN (2,3,4) THEN 2
    WHEN r = 5 THEN 1
    ELSE 1
  END AS seat_type
FROM
  (SELECT 0 AS r UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
   UNION ALL SELECT 4 UNION ALL SELECT 5) AS row_nums
CROSS JOIN
  (SELECT 0 AS c UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 
   UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 
   UNION ALL SELECT 8) AS col_nums;

-- Suất chiếu mẫu
INSERT INTO Shows(title, director, genre, showtime, room_id, poster, trailer) VALUES
('Khế Ước Bán Dâu', 'Nguyễn Văn A', 'Tâm lý, Tình cảm', '2025-10-15 19:00:00', 1,
 'https://files.betacorp.vn/media%2fimages%2f2025%2f08%2f01%2f400x633-094149-010825-91.jpg',
 'https://www.youtube.com/embed/eFV2eSaDsp4'),
('Mưa Đỏ', 'Trần Thị B', 'Kinh dị, Bí ẩn', '2025-10-16 20:00:00', 2,
 'https://files.betacorp.vn/media%2fimages%2f2025%2f08%2f22%2f400x633-8-181310-220825-58.jpg',
 'https://www.youtube.com/embed/RZRb5K2aK4E'),
('Thám Tử Lừng Danh Conan', 'Gosho Aoyama', 'Hoạt hình, Trinh thám', '2025-11-10 14:00:00', 1,
 'https://files.betacorp.vn/media%2fimages%2f2025%2f08%2f01%2f400x633-094149-010825-91.jpg',
 'https://www.youtube.com/embed/eFV2eSaDsp4'),
('Godzilla x Kong', 'Adam Wingard', 'Hành động, Phiêu lưu', '2025-11-10 16:30:00', 2,
 'https://files.betacorp.vn/media%2fimages%2f2025%2f08%2f01%2f400x633-094149-010825-91.jpg',
 'https://www.youtube.com/embed/RZRb5K2aK4E'),
 ('Ma Da', 'Nguyễn Hữu Hoàng', 'Kinh dị, Tâm lý', '2025-11-10 21:00:00', 3,
 'https://files.betacorp.vn/media%2fimages%2f2025%2f08%2f22%2f400x633-8-181310-220825-58.jpg',
 'https://www.youtube.com/embed/eFV2eSaDsp4')
ON DUPLICATE KEY UPDATE title=title;
-- Combo mẫu
INSERT INTO Combos(name, price) VALUES
('Combo 1 Bắp + 1 Nước', 60000),
('Combo 2 Bắp + 2 Nước', 110000),
('Combo Family (3 Bắp + 3 Nước)', 150000)
ON DUPLICATE KEY UPDATE price=price;

-- Khuyến mãi mẫu
INSERT INTO Promotions(code, discount, expiry) VALUES
('KM10', 10, '2025-12-31'),
('KM20', 20, '2025-12-31')
ON DUPLICATE KEY UPDATE discount=discount;