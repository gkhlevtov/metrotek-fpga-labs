# Отчёт по верификации модуля инкремента байтов на Avalon-MM

**Модуль:** `byte_inc.sv`

**Параметры симуляции:** `DATA_WIDTH=64`, `ADDR_WIDTH=10`, `BYTE_CNT=8`

**Seed:** `12345`

---

## Таблица обнаруженных ошибок

| № | Название бага | Симуляционное время первого воспроизведения | Сообщение в transcript  |
| -- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | Игнорирование задания при length = `BYTE_CNT` (8 байт) | **T = 1605 ps**  | `Error: [ENV] drain: TIMEOUT waiting for job completion (target=2, completed=1)`<br />`Time: 1605 ps  Scope: byte_inc_pkg.environment.environment__1.drain File: environment.sv Line: 67`                  |
| 2  | Нулевой `wr_byteenable` для полностью заполненного последнего слова | **T = 1755 ps** | `Error: [SCB] @1755 beat #12: BYTEENABLE mismatch! addr=3ff Got=00000000 Exp=11111111`<br />`Time: 1755 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 158` |
| 3  | `writedata = x` при переполнении байта (`0xFF -> 0x00`) | **T = 3815 ps** | `Error: [SCB] @3815 beat #33: WRITEDATA mismatch! addr=3fe byte=7 Got=xx Exp=00` <br /> `Time: 3815 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167`  |
| 4  | Некорректные данные записи при выполнении длинных заданий (смещение и накопление ошибок) | **T = 4495 ps** | `Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=0 Got=3c Exp=72` <br /> `Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167` <br /> `...` |
---

## Детальное описание ошибок

### Баг №1: Игнорирование задания при length = `BYTE_CNT` (8 байт)

**Описание:**
При отправке задания с длиной ровно 8 байт (одно полное слово) модуль не поднимает `waitrequest`, не отправляет запросы на чтение и запись по шине Avalon‑MM. DUT выставляет на шины лишь текущий адрес. В результате тестовая среда ожидает завершения задания до таймаута.

**Ожидаемое поведение:** Модуль должен начать обработку задания, выполнить чтение одного слова, инкрементировать байты и записать результат обратно, после чего снять `waitrequest`.

**Фактическое поведение:** Задание игнорируется, `waitrequest` остаётся равным 0, `amm_rd_read` и `amm_wr_write` не активируются.

**Сообщения в transcript:**

```
Error: [ENV] drain: TIMEOUT waiting for job completion (target=2, completed=1)
Time: 1605 ps  Scope: byte_inc_pkg.environment.environment__1.drain File: environment.sv Line: 67
```

**Время первого воспроизведения:** `T = 1605 ps`

---

### Баг №2: Нулевой `​wr_byteenable`​ для полностью заполненного последнего слова

**Описание:**
Когда последнее слово задания задействовано целиком (маска должна быть `11111111`), модуль выставляет `wr_byteenable` = `8'b00000000`. Ошибка возникает как на максимальном адресе (`0x3ff`), так и на других адресах, если последнее слово полностью входит в диапазон.

**Ожидаемое поведение:** Для полностью заполненного слова `wr_byteenable` должен быть равен `11111111`.

**Фактическое поведение:** wr_byteenable обнуляется.

**Сообщения в transcript:**

```
Error: [SCB] @1755 beat #12: BYTEENABLE mismatch! addr=3ff Got=00000000 Exp=11111111
Time: 1755 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 158
```

**Время первого воспроизведения:** `T = 1755 ps`

---

### Баг №3: `writedata = x` при переполнении байта (`0xFF -> 0x00`)

**Описание:**
При инкременте байта со значением `0xFF` модуль не выполняет перекрутку к `0x00`, а выдаёт неопределённое состояние (`xxx`) на соответствующие биты `writedata`.

**Ожидаемое поведение:** Байт `0xFF` должен стать `0x00`.

**Фактическое поведение:** На шине записи появляются `x` в разрядах, соответствующих этому байту.

**Сообщения в transcript:**

```
Error: [SCB] @3815 beat #33: WRITEDATA mismatch! addr=3fe byte=7 Got=xx Exp=00
Time: 3815 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
```

**Время первого воспроизведения:** `T = 3815 ps`

---

### Баг №4: Некорректные данные записи при выполнении длинных заданий (смещение и накопление ошибок)

**Описание:**
При выполнении задания с максимальной длиной (`length` = 1023 байта) модуль выполняет большое количество чтений и записей, однако записываемые данные не соответствуют ожидаемым (инкрементированным значениям исходных байтов).
Ошибки имеют систематический характер: первое смещение происходит на 6 по порядку слове, далее через каждые 32 слова смещение данных относительно адреса, выдаваемого модулем, растёт на 1.

**Ожидаемое поведение:** Все слова должны быть прочитаны, инкрементированы и записаны по тем же адресам.

**Фактическое поведение:** Данные записываются с ошибками (выполняется запись по неверным адресам - смещение)

**Сообщения в transcript:**

```
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=0 Got=3c Exp=72
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=1 Got=94 Exp=ef
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=2 Got=cd Exp=02
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=4 Got=a9 Exp=b5
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=5 Got=19 Exp=63
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=6 Got=9f Exp=a6
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
Error: [SCB] @4495 beat #74: WRITEDATA mismatch! addr=005 byte=7 Got=f0 Exp=1e
Time: 4495 ps  Scope: byte_inc_pkg.scoreboard.scoreboard__1.check_beat_wr File: scoreboard.sv Line: 167
```

**Время первого воспроизведения:** `T = 4495 ps`

---