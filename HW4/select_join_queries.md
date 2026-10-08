# HW4. SELECT + CASE и JOIN

## Подготовка данных

```sql
-- приют без животных и без координатора
insert into shelters (name, address) values ('Пушистый хвост', 'г. Екатеринбург, ул. Мира, 7');

-- животное, которое пока не привязано ни к какому приюту
insert into animals (name, species, age, status, shelter_id) values ('Бусинка', 'кошка', 2, 'available', null);

-- волонтёр без смен
insert into volunteers (name, phone) values ('Орлова Алина Максимовна', '+79995556600');

-- смена, на которую ещё не назначен волонтёр
insert into shifts (volunteer_id, date, start_time, end_time, role) values (null, '2024-03-05', '09:00', '13:00', 'выгул');

-- посетитель, который ещё не подавал заявок
insert into visitors (name, phone, email, registration_year) values ('Козлова Анна Ильинична', '+79998889900', 'kozlova@mail.ru', 2024);
```

---

# Блок 1. SELECT + CASE

## 1.1. Категория животного по возрасту

Что хотим получить: список животных (кличка и возраст) и вычисляемый столбец с категорией: если возраст < 3 — «молодой», иначе — «взрослый».

```sql
select
    name,
    age,
    case
        when age < 3 then 'молодой'
        else 'взрослый'
    end as age_category
from animals
order by animal_id;
```

**Результат:**

| name | age | age_category |
|---|---|---|
| Барсик | 3 | взрослый |
| Рекс | 2 | молодой |
| Мурка | 5 | взрослый |
| Дружок | 1 | молодой |
| Бусинка | 2 | молодой |


## 1.2. Статус заявки на русском языке

Что хотим получить: id заявки, id животного и понятный статус на русском вместо английских `pending`, `approved`, `rejected`.

```sql
select
    application_id,
    animal_id,
    status as original_status,
    case
        when status = 'pending'  then 'В обработке'
        when status = 'approved' then 'Одобрено'
        when status = 'rejected' then 'Отклонено'
        else 'Неизвестно'
    end as russian_status
from adoption_applications
order by application_id;
```

**Результат:**

| application_id | animal_id | original_status | russian_status |
|---|---|---|---|
| 1 | 1 | approved | Одобрено |
| 2 | 2 | approved | Одобрено |
| 3 | 3 | rejected | Отклонено |
| 4 | 4 | pending | В обработке |



---

# Блок 2. JOIN

## 2.1. INNER JOIN

`INNER JOIN` возвращает только те строки, для которых нашлась пара в обеих таблицах.

### Запрос 2.1.1

Что хотим получить: кличку животного и название приюта, в котором оно находится.

```sql
select
    a.name as animal_name,
    s.name as shelter_name
from animals a
inner join shelters s on a.shelter_id = s.shelter_id
order by a.animal_id;
```

**Результат:**

| animal_name | shelter_name |
|---|---|
| Барсик | Добрые руки |
| Рекс | Добрые руки |
| Мурка | Верный друг |
| Дружок | Новый дом |

Бусинка в результат не попала, так как у неё `shelter_id = null`.



### Запрос 2.1.2

Что хотим получить: имя посетителя, подавшего заявку, кличку животного, на которое он претендует, и статус заявки (соединяем три таблицы).

```sql
select
    v.name as visitor_name,
    a.name as animal_name,
    ap.status
from adoption_applications ap
inner join visitors v on ap.visitor_id = v.visitor_id
inner join animals a  on ap.animal_id = a.animal_id
order by ap.application_id;
```

**Результат:**

| visitor_name | animal_name | status |
|---|---|---|
| Иванова Мария Петровна | Барсик | approved |
| Петров Сергей Николаевич | Рекс | approved |
| Сидоров Павел Андреевич | Мурка | rejected |
| Иванова Мария Петровна | Дружок | pending |



---

## 2.2. LEFT OUTER JOIN

`LEFT JOIN` возвращает все строки левой таблицы. Если пары в правой нет, на её месте будет `NULL`.

### Запрос 2.2.1

Что хотим получить: все приюты и привязанных к ним животных. Если в приюте нет животных, вместо клички будет `NULL`.

```sql
select
    s.name as shelter_name,
    a.name as animal_name
from shelters s
left join animals a on s.shelter_id = a.shelter_id
order by s.shelter_id, a.animal_id;
```

**Результат:**

| shelter_name | animal_name |
|---|---|
| Добрые руки | Барсик |
| Добрые руки | Рекс |
| Верный друг | Мурка |
| Новый дом | Дружок |
| Пушистый хвост | NULL |



### Запрос 2.2.2

Что хотим получить: всех посетителей и их заявки, включая тех, кто заявок ещё не подавал.

```sql
select
    v.name as visitor_name,
    ap.application_id,
    ap.status
from visitors v
left join adoption_applications ap on v.visitor_id = ap.visitor_id
order by v.visitor_id, ap.application_id;
```

**Результат:**

| visitor_name | application_id | status |
|---|---|---|
| Иванова Мария Петровна | 1 | approved |
| Иванова Мария Петровна | 4 | pending |
| Петров Сергей Николаевич | 2 | approved |
| Сидоров Павел Андреевич | 3 | rejected |
| Козлова Анна Ильинична | NULL | NULL |



---

## 2.3. RIGHT OUTER JOIN

`RIGHT JOIN` возвращает все строки правой таблицы. Если пары в левой нет, на её месте будет `NULL`.

### Запрос 2.3.1

Что хотим получить: всех волонтёров и даты их смен. Волонтёр без смен тоже должен попасть в результат.

```sql
select
    v.name as volunteer_name,
    sh.date as shift_date,
    sh.start_time
from shifts sh
right join volunteers v on sh.volunteer_id = v.volunteer_id
order by v.volunteer_id, sh.date;
```

**Результат:**

| volunteer_name | shift_date | start_time |
|---|---|---|
| Смирнова Ольга Викторовна | 2024-03-01 | 09:00:00 |
| Кузнецов Дмитрий Андреевич | 2024-03-02 | 13:00:00 |
| Морозова Екатерина Игоревна | 2024-03-03 | 09:00:00 |
| Волков Артём Сергеевич | 2024-03-04 | 17:00:00 |
| Орлова Алина Максимовна | NULL | NULL |

Смена от 2024-03-05 без волонтёра в результат не попала, так как она есть только в левой таблице.



### Запрос 2.3.2

Что хотим получить: все приюты и животных, причём таблица приютов стоит справа (поэтому приют без животных виден).

```sql
select
    a.name as animal_name,
    s.name as shelter_name
from animals a
right join shelters s on a.shelter_id = s.shelter_id
order by s.shelter_id, a.animal_id;
```

**Результат:**

| animal_name | shelter_name |
|---|---|
| Барсик | Добрые руки |
| Рекс | Добрые руки |
| Мурка | Верный друг |
| Дружок | Новый дом |
| NULL | Пушистый хвост |

Результат такой же, как в запросе 2.2.1: `A right join B` — это то же самое, что `B left join A`.



---

## 2.4. CROSS JOIN

`CROSS JOIN` возвращает все возможные комбинации строк двух таблиц (декартово произведение). Условия соединения нет.

### Запрос 2.4.1

Что хотим получить: все возможные комбинации приютов и ролей на смене.

```sql
select
    s.name as shelter_name,
    r.role_name
from shelters s
cross join (
    values ('выгул'), ('уборка'), ('кормление')
) as r(role_name)
order by s.shelter_id, r.role_name;
```

**Результат** (4 приюта × 3 роли = 12 строк):

| shelter_name | role_name |
|---|---|
| Добрые руки | выгул |
| Добрые руки | кормление |
| Добрые руки | уборка |
| Верный друг | выгул |
| Верный друг | кормление |
| Верный друг | уборка |
| Новый дом | выгул |
| Новый дом | кормление |
| Новый дом | уборка |
| Пушистый хвост | выгул |
| Пушистый хвост | кормление |
| Пушистый хвост | уборка |



### Запрос 2.4.2

Что хотим получить: все собаки в сочетании со всеми возможными статусами заявок.

```sql
select
    a.name as animal_name,
    st.status_name
from animals a
cross join (
    values ('pending'), ('approved'), ('rejected')
) as st(status_name)
where a.species = 'собака'
order by a.animal_id, st.status_name;
```

**Результат** (2 собаки × 3 статуса = 6 строк):

| animal_name | status_name |
|---|---|
| Рекс | approved |
| Рекс | pending |
| Рекс | rejected |
| Дружок | approved |
| Дружок | pending |
| Дружок | rejected |



---

## 2.5. FULL OUTER JOIN

`FULL OUTER JOIN` возвращает все строки из обеих таблиц. Где пары нет, подставляется `NULL` с соответствующей стороны.

### Запрос 2.5.1

Что хотим получить: все приюты и все животные: и приют без животных, и животное без приюта.

```sql
select
    s.name as shelter_name,
    a.name as animal_name
from shelters s
full outer join animals a on s.shelter_id = a.shelter_id
order by s.shelter_id, a.animal_id;
```

**Результат:**

| shelter_name | animal_name |
|---|---|
| Добрые руки | Барсик |
| Добрые руки | Рекс |
| Верный друг | Мурка |
| Новый дом | Дружок |
| Пушистый хвост | NULL |
| NULL | Бусинка |



### Запрос 2.5.2

Что хотим получить: всех волонтёров и все смены: и волонтёра без смен, и смену без волонтёра.

```sql
select
    v.name as volunteer_name,
    sh.date as shift_date,
    sh.role
from volunteers v
full outer join shifts sh on v.volunteer_id = sh.volunteer_id
order by v.volunteer_id, sh.date;
```

**Результат:**

| volunteer_name | shift_date | role |
|---|---|---|
| Смирнова Ольга Викторовна | 2024-03-01 | уход за животными |
| Кузнецов Дмитрий Андреевич | 2024-03-02 | выгул |
| Морозова Екатерина Игоревна | 2024-03-03 | уборка |
| Волков Артём Сергеевич | 2024-03-04 | кормление |
| Орлова Алина Максимовна | NULL | NULL |
| NULL | 2024-03-05 | выгул |

