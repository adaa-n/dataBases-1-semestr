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


-- 5. Нормализация (HW3)

/*
Так как исходный проект был нормализован, добавляем ошибку - в приютах есть координаторы (управляющие), волонтёры у них работают, и у каждого приюта ровно один координатор. Это проблема, так как
    * один и тот же координатор может случайно оказаться записан в двух разных приютах, хотя так быть не должно
    * если уйдёт последний волонтёр координатора, пропадёт информация о том, в каком приюте тот работает
    * чтобы сменить приют координатора, надо править много строк
Таким образом, решение - разбиваем одну таблицу на 2:
    * coordinators - какой координатор в каком приюте
    * volunteer_coordinators - какой волонтер и какой у него координатор
*/

drop table if exists volunteer_coordinators;
drop table if exists coordinators;

create table coordinators (
    coordinator_id serial primary key,
    name varchar(100) not null,
    shelter_id int not null references shelters(shelter_id) on delete cascade
);

create table volunteer_coordinators (
    volunteer_id int references volunteers(volunteer_id) on delete cascade,
    coordinator_id int references coordinators(coordinator_id) on delete cascade,
    primary key (volunteer_id, coordinator_id)
);

-- Чтоб у каждого координатора был ровно один приют
insert into coordinators (name, shelter_id) values ('Белова Анна Сергеевна', 1),
                                                   ('Громов Игорь Павлович', 2),
                                                   ('Лебедева Нина Олеговна', 3);

-- Волонтёр 1 помогает в двух приютах - 1, 2
insert into volunteer_coordinators (volunteer_id, coordinator_id) values (1, 1),
                                                                         (2, 1),
                                                                         (1, 2),
                                                                         (3, 2),
                                                                         (4, 3);

-- Проверка
select v.name as volunteer, c.name as coordinator, s.name as shelter
from volunteer_coordinators vc join volunteers v on v.volunteer_id = vc.volunteer_id
    join coordinators c on c.coordinator_id = vc.coordinator_id
    join shelters s on s.shelter_id = c.shelter_id
order by v.volunteer_id;