create database GroupProjectManagement;
use GroupProjectManagement;

-- Người dùng
create table User
(
	user_id int primary key,
    userName varchar(255) not null,
    password varchar(255) not null,
    role enum('student', 'mentor', 'admin') not null, -- vai trò của người dùng
    personal_info text -- Thông tin cá nhân
);

-- Sinh viên
create table Student
(
	student_id int primary key,
    user_id int,
    foreign key(user_id) references User(user_id)
);

-- Điểm ví
create table WalletPoint
(
	wallet_id int primary key,
    student_id int,
    points int default 0, -- Điểm ví hiện tại, điếm ví mắc định bằng 0
    foreign key(student_id) references Student(student_id)
);

-- Mentor
create table Mentor
(
	mentor_id int primary key,
    user_id int,
    expertise varchar(255), -- Lĩnh vực chuyên môn của mentor
    available_slots int, -- Số buổi có thể hỗ trợ
    foreign key(user_id) references User(user_id)
);

-- Kĩ năng của mentor
create table Skill
(
	skill_id int primary key,
    mentor_id int,
    skill_name varchar(255) not null,
    expertise_level varchar(50), -- Trình độ chuyên môn
    foreign key(mentor_id) references Mentor(mentor_id)
);

-- Nhóm dự án
create table ProjectGroup
(
	group_id int primary key,
    group_name varchar(255) not null,
    project_topic varchar(255), -- Chủ đề dự án
    progress_status varchar(255), -- Tình trạng tiến độ dự án
    creator_user_id int, -- Người dùng tạo ra nhóm hay nhóm trưởng
    foreign key(creator_user_id) references User(user_id)
);

-- Thành viên trong nhóm
create table GroupMember
(
	group_id int,
    user_id int,
    primary key(group_id, user_id),
    foreign key(group_id) references ProjectGroup(group_id),
    foreign key(user_id) references User(user_id)
);

-- Lên lịch gặp mentor
create table Appointment
(
	appointment_id int primary key,
    student_id int,
    mentor_id int,
    skill_id int,
    appointment_date datetime, -- Ngày hẹn gặp 
    status varchar(50) default 'pending', -- Trạng thái: chưa có lịch hẹn hay đã có lịch hẹn
    foreign key(student_id) references Student(student_id),
    foreign key(mentor_id) references Mentor(mentor_id),
    foreign key(skill_id) references Skill(skill_id)
);

-- Thay đổi dấu phân cách tạm thời
delimiter $$
-- Cập nhật điểm ví sau mỗi lần đặt lịch
create trigger DeductWalletPoints -- Trừ điểm ví
after insert on Appointment
for each row
begin
	update WalletPoint
    set points = points - 10
    where student_id = new.student_id
    and points >= 10;
end $$

-- Nhận xét, đánh giá
create table Feedback
(
	feedback_id int primary key,
    appointment_id int,
    user_id int,
    feedback_text text,
    rating int check (rating >=1 and rating <=5), -- Đánh giá từ 1 đến 5 sao
    foreign key(appointment_id) references Appointment(appointment_id),
    foreign key(user_id) references User(user_id)
);

-- Thông báo
create table Notification
(
	notification_id int primary key,
    user_id int,
    message text not null,
    notification_type enum('email', 'sms', 'system') default 'system', -- Chọn loại thông báo: email, sms, system(hệ thống)
    foreign key(user_id) references User(user_id)
);

-- Báo cáo hệ thống
create view SystemReport as
select
	count(distinct Appointment.appointment_id) as total_appointments, -- Đếm số lượng các cuộc hẹn
    sum(WalletPoint.points) as total_wallet_points_used, -- Tính tổng số điểm ví đã được sử dụng
    avg(Feedback.rating) as average_feedback_rating -- Tính trung bình các giá trị xếp hạng (rating)
from Appointment
join Feedback on Appointment.appointment_id = Feedback.appointment_id
join WalletPoint on WalletPoint.student_id = Appointment.student_id;
