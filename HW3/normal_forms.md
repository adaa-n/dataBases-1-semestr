# HW3. Нормальные формы (3НФ и НФБК)

## Коротко о том, что такое НФ

- **3НФ**: у таблицы не должно быть так, что одно неключевое поле зависит от другого неключевого поля (а не напрямую от ключа). Например, сотрудник → отдел → руководитель отдела
- **НФБК** (Бойса-Кодда): если одно поле (или набор полей) однозначно определяет другое, то оно должно быть ключом таблицы
- **ФЗ** (функциональная зависимость) A → B значит - если знаем A, то однозначно знаем B

## 1. Проверка таблиц

В каждой таблице я посмотрела зависимости

| Таблица | Ключ | Что от чего зависит | 3НФ | НФБК |
|---|---|---|---|---|
| shelters | shelter_id | shelter_id → name, address | да | да |
| animals | animal_id | animal_id → name, species, age, status, shelter_id, arrival_date | да | да |
| volunteers | volunteer_id | volunteer_id → name, phone | да | да |
| shifts | shifts_id | shifts_id → volunteer_id, date, start_time, end_time, role | да | да |
| visitors | visitor_id и email | всё определяется по visitor_id, а также по email (он unique) | да | да |
| adoption_applications | application_id | application_id → animal_id, visitor_id, application_date, status, comment | да | да |

**Вывод:** в каждой таблице всё зависит только от ключа, а не от других обычных полей. Поэтому мои таблицы уже в 3НФ и НФБК, исправлять нечего

В visitors два ключа (visitor_id и email), но это не проблема: оба однозначно определяют остальные поля

Так как ошибок нет, по заданию я придумала три плохих примера на своих же таблицах. Два нарушают 3НФ, один нарушает НФБК

---

## 2. Пример 1 (нарушение 3НФ): животные и данные приюта в одной таблице

Допустим, изначально это было так:

```sql
create table animals_wide (
    animal_id       serial primary key,
    name            varchar(100),
    species         varchar(50),
    age             int,
    status          varchar(30),
    shelter_id      int,
    shelter_name    varchar(100),
    shelter_address varchar(200)
);
```

| animal_id | name | shelter_id | shelter_name | shelter_address |
|---|---|---|---|---|
| 1 | Барсик | 1 | Добрые руки | г. Москва, ул. Ленина, 10 |
| 2 | Рекс | 1 | Добрые руки | г. Москва, ул. Ленина, 10 |
| 3 | Мурка | 2 | Верный друг | г. Казань, ул. Баумана, 5 |

**Что от чего зависит:**
- animal_id → name, species, age, status, shelter_id
- shelter_id → shelter_name, shelter_address

Получается цепочка: animal_id → shelter_id → shelter_name, shelter_address. Название и адрес приюта зависят от животного не напрямую, а через shelter_id - это и есть нарушение 3НФ

**Какие проблемы (аномалии):**
- **Вставка:** нельзя добавить новый приют, пока в нём нет ни одного животного
- **Удаление:** если удалить Мурку, пропадёт и информация о приюте «Верный друг» (тк он был один с этим животным)
- **Изменение:** если у приюта «Добрые руки» поменялся адрес, надо менять его во всех строках (если одну забыть, у приюта будет два адреса)

**Как исправлено:** выносим приюты в отдельную таблицу

```
shelters(shelter_id, name, address)
animals(animal_id, name, species, age, status, shelter_id)  -- shelter_id ссылается на shelters
```

Теперь адрес хранится один раз и проблем нет

---

## 3. Пример 2 (нарушение 3НФ): смены и данные волонтёра в одной таблице

```sql
create table shifts_wide (
    shifts_id       serial primary key,
    volunteer_id    int,
    volunteer_name  varchar(100),
    volunteer_phone varchar(20),
    date            date,
    start_time      time,
    end_time        time,
    role            varchar(50)
);
```

**Что от чего зависит:**
- shifts_id → volunteer_id, date, start_time, end_time, role
- volunteer_id → volunteer_name, volunteer_phone

Цепочка: shifts_id → volunteer_id → volunteer_phone - телефон зависит от смены через волонтёра, значит, это нарушение 3НФ

**Какие проблемы:**
- **Вставка:** нельзя добавить волонтёра, пока у него нет смен
- **Удаление:** удалили единственную смену волонтёра, и вместе с ней пропали его имя и телефон
- **Изменение:** волонтёр сменил телефон, и надо править все его смены. Если пропустить одну, у него будет два телефона

**Как исправлено:** вынесем волонтёров в отдельную таблицу.

```
volunteers(volunteer_id, name, phone)
shifts(shifts_id, volunteer_id, date, start_time, end_time, role)  -- volunteer_id ссылается на volunteers
```

---

## 4. Пример 3 (нарушение НФБК): координаторы приютов

Мои исходные таблицы уже в НФБК, поэтому для этого примера я добавила новую сущность: **координаторов** (управляющих приютов). Условия:
- волонтёр может помогать в нескольких приютах
- у каждого координатора ровно один приют (в приюте координаторов может быть несколько)

Если хранить это в одной таблице:

```sql
create table volunteer_duty (
    volunteer_id   int,
    shelter_id     int,
    coordinator_id int,
    primary key (volunteer_id, shelter_id)
);
```

| volunteer_id | shelter_id | coordinator_id |
|---|---|---|
| 1 | 1 | 10 |
| 1 | 2 | 20 |
| 2 | 1 | 10 |
| 3 | 2 | 20 |

**Что от чего зависит:**
- (volunteer_id, shelter_id) → coordinator_id
- coordinator_id → shelter_id (координатор работает в одном приюте)

**Ключи таблицы:** (volunteer_id, shelter_id) и (volunteer_id, coordinator_id). Они пересекаются по volunteer_id

**3НФ тут есть:** все поля входят в какой-нибудь ключ, поэтому неключевых полей, которые зависят друг от друга, нет

**НФБК нарушена:** есть зависимость coordinator_id → shelter_id, но coordinator_id один не является ключом таблицы. А по правилу НФБК слева должен быть ключ

**Какие проблемы:**
- **Ошибка в данных:** можно добавить строку `(2, 2, 10)`, и получится, что координатор 10 работает сразу в двух приютах. А так быть не должно, и база это не запретит
- **Вставка:** нельзя записать, что новый координатор работает в приюте 3, пока у него нет ни одного волонтёра
- **Удаление:** если ушёл последний волонтёр координатора, мы теряем информацию, в каком приюте он работает
- **Изменение:** если координатор перешёл в другой приют, надо править много строк

**Как исправила:** разбила на две таблицы по зависимости coordinator_id → shelter_id

```sql
create table coordinators ( 
    coordinator_id serial primary key,
    name           varchar(100) not null,
    shelter_id     int not null references shelters(shelter_id) on delete cascade
);

create table volunteer_coordinators (
    volunteer_id   int references volunteers(volunteer_id) on delete cascade,
    coordinator_id int references coordinators(coordinator_id) on delete cascade,
    primary key (volunteer_id, coordinator_id)
);
```

Теперь приют координатора записан один раз, и в каждой зависимости слева стоит ключ. Таблицы в НФБК

**Минус такого решения:** правило «у волонтёра в одном приюте один координатор» теперь таблицей не проверяется. При желании его можно проверять триггером

Эти таблицы я добавила в базу и в файл text.sql (блок 5)

---

## 5. Итоговая схема (8 таблиц)

| Таблица | Ключ | Ссылки на другие таблицы |
|---|---|---|
| shelters | shelter_id | нет |
| animals | animal_id | shelter_id → shelters |
| volunteers | volunteer_id | нет |
| shifts | shifts_id | volunteer_id → volunteers |
| visitors | visitor_id (email unique) | нет |
| adoption_applications | application_id | animal_id → animals, visitor_id → visitors |
| coordinators | coordinator_id | shelter_id → shelters |
| volunteer_coordinators | (volunteer_id, coordinator_id) | volunteer_id → volunteers, coordinator_id → coordinators |

## 6. Итог: какие были аномалии и как их решили

| Проблема | Где была | Что сделала |
|---|---|---|
| Нельзя добавить данные без «лишних» | приют без животного, волонтёр без смены, координатор без волонтёра | вынесла в отдельные таблицы |
| Пропадают данные при удалении | удалили последнее животное, смену или волонтёра | то же |
| Одно и то же надо менять в куче строк | адрес приюта, телефон волонтёра, приют координатора | теперь каждый факт хранится один раз |
| Противоречие в данных | координатор сразу в двух приютах | вынесла `coordinator_id → shelter_id` в отдельную таблицу (НФБК) |

