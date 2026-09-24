-- 1. Создаем таблицы по ER-диаграмме

create table shelters (
    shelter_id serial primary key,
    name varchar(100) not null,
    address varchar(200)
);

create table animals (
    animal_id serial primary key,
    name varchar(100) not null,
    species varchar(50),
    age int,
    status varchar(30),
    shelter_id int references shelters(shelter_id) on delete cascade
);

create table volunteers (
    volunteer_id serial primary key,
    name varchar(100) not null,
    phone varchar(20)
);

create table shifts (
    shifts_id serial primary key,
    volunteer_id int references volunteers(volunteer_id) on delete cascade,
    date date,
    start_time time,
    end_time time
);

create table visitors (
    visitor_id serial primary key,
    name varchar(100) not null,
    phone varchar(20),
    email varchar(100) unique
);

create table adoption_applications (
    application_id serial primary key,
    animal_id int references animals(animal_id) on delete cascade,
    visitor_id int references visitors(visitor_id) on delete cascade,
    application_date date default current_date,
    status varchar(30)
);

-- 2. ALTER запросы (дорабатываем структуру)

alter table visitors add column registration_year int;

alter table animals add column arrival_date date default current_date;

alter table visitors alter column email set not null;

alter table adoption_applications add column comment varchar(200);

alter table shifts add column role varchar(50);


-- 3. Заполняем таблицы данными

insert into shelters (name, address) values
('Добрые руки', 'г. Москва, ул. Ленина, 10'),
('Верный друг', 'г. Казань, ул. Баумана, 5'),
('Новый дом', 'г. Санкт-Петербург, ул. Невская, 22');

insert into volunteers (name, phone) values
('Смирнова Ольга Викторовна', '+79991112233'),
('Кузнецов Дмитрий Андреевич', '+79992223344'),
('Морозова Екатерина Игоревна', '+79993334455'),
('Волков Артём Сергеевич', '+79994445566');

insert into animals (name, species, age, status, shelter_id, arrival_date) values
('Барсик', 'кот', 3, 'available', 1, '2023-05-10'),
('Рекс', 'собака', 2, 'available', 1, '2024-01-15'),
('Мурка', 'кошка', 5, 'adopted', 2, '2022-11-20'),
('Дружок', 'собака', 1, 'available', 3, '2024-06-01');

insert into visitors (name, phone, email, registration_year) values
('Иванова Мария Петровна', '+79995556677', 'ivanova@mail.ru', 2023),
('Петров Сергей Николаевич', '+79996667788', 'petrov@gmail.com', 2024),
('Сидоров Павел Андреевич', '+79997778899', 'sidorov@yandex.ru', 2024);

insert into shifts (volunteer_id, date, start_time, end_time, role) values
(1, '2024-03-01', '09:00', '13:00', 'уход за животными'),
(2, '2024-03-02', '13:00', '17:00', 'выгул'),
(3, '2024-03-03', '09:00', '13:00', 'уборка'),
(4, '2024-03-04', '17:00', '21:00', 'кормление');

insert into adoption_applications (animal_id, visitor_id, application_date, status) values
(1, 1, '2024-04-01', 'pending'),
(2, 2, '2024-04-05', 'approved'),
(3, 3, '2024-04-10', 'rejected'),
(4, 1, '2024-04-15', 'pending');

-- 4. UPDATE запросы

-- меняем почту посетителя
update visitors
set email = 'new_ivanova@mail.ru'
where visitor_id = 1;

-- отмечаем животное как усыновленное после одобрения заявки
update animals
set status = 'adopted'
where animal_id = 2;

-- обновляем статус заявки
update adoption_applications
set status = 'approved'
where application_id = 1;

-- меняем телефон волонтера
update volunteers
set phone = '+79000000000'
where volunteer_id = 3;

-- продлеваем смену волонтера
update shifts
set end_time = '18:00'
where shifts_id = 2;
