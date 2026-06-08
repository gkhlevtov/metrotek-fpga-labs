# Отчёт по верификации модуля демультиплексора потоковых интерфейсов Avalon-ST

**Модуль:** `ast_dmx.sv`

**Параметры симуляции:** `DATA_WIDTH=64`, `CHANNEL_WIDTH=8`, `TX_DIR=4`, `PACKETS=10`

**Seed:** `12345`

---

## Таблица обнаруженных ошибок

| № | Название бага                                               | Симуляционное время первого воспроизведения | Сообщение в transcript                                                                                                                                                                                                                                                                                                                                                                                                                                                 |
| -- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | Инверсия выходных портов                          | **T = 75 ps**                                                                 | `[DRV] @75: valid=1 sop=0 eop=0 empty=0 ch=47 dir=1 data=99dd9c65028fff4a`<br />`Error: [SCB] @75 beat #1 port 2: CHANNEL mismatch! Got=47 Exp=249`<br />`Time: 75 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107`<br />`Error: [SCB] @75 beat #1 port 2: DATA mismatch! Got=09cfcc2ee6d4028b Exp=bdc6047a309cb18c`<br />`Time: 75 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 136` |
| 2  | Потеря сигнала `channel` на выходе 1 (`dir=2`) | **T = 785 ps** | `Error: [SCB] @785 beat #62 port 1: CHANNEL mismatch! Got=0 Exp=47`<br />`Time: 785 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107` |
| 3  | Потеря выходного beat'а при `empty_i = 7`          | **T = 2105 ps**  | `Error: [SCB] Port 0 has 26 pending beat(s) never received - LOST PACKETS!`<br />`Time: 2155 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158` |

---

## Детальное описание ошибок

### Баг №1: Инверсия выходных портов

**Описание:**
Биты сигнала `dir_i` интерпретируются модулем в обратном порядке.
В результате:
- `dir=00` активирует выход 3,
- `dir=01` -> выход 2,
- `dir=10` -> выход 1,
- `dir=11` -> выход 0.

Пакет направляется не на заданный порт.

**Ожидаемое поведение:** `dir=0` -> выход 0, `dir=1` -> выход 1, `dir=2` -> выход 2, `dir=3` -> выход 3.

**Фактическое поведение:** Обратный порядок выходных портов

**Сообщение в transcript:**

```
[DRV] @75: valid=1 sop=0 eop=0 empty=0 ch=47 dir=1 data=99dd9c65028fff4a
Error: [SCB] @75 beat #1 port 2: CHANNEL mismatch! Got=47 Exp=249`
Time: 75 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107
Error: [SCB] @75 beat #1 port 2: DATA mismatch! Got=09cfcc2ee6d4028b Exp=bdc6047a309cb18c
Time: 75 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 136
```

**Время первого воспроизведения:** `T = 75 ps`

---

### Баг №2: Потеря сигнала `channel` на выходе 1 (`dir=2`)

**Описание:**
При передаче пакета с `dir=2` (который из-за инверсии портов попадает на выход 1) значение `channel_o` всегда равно 0, независимо от входного `channel_i`. На остальных выходах канал передаётся корректно.

**Ожидаемое поведение:** корректная выдача текущего канала внутри передачи.

**Фактическое поведение:** На выходе 1 (`dir=2`) `channel_o = 0`, даже если на входе `channel_i != 0`.

**Сообщения в transcript:**

```
Error: [SCB] @785 beat #62 port 1: CHANNEL mismatch! Got=0 Exp=47
Time: 785 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107
```

**Время первого воспроизведения:** `T = 785 ps`

---

### Баг №3: Потеря выходного beat'а при `empty_i = 7`

**Описание:**
Если на вход демультиплексора подаётся пакет, состоящий из одного beat'а с `empty_i=7` (т.е. только 1 значащий байт из 8), модуль не формирует выходной beat: сигнал `valid_o` остается равным 0, `channel_o` не определён. Пакет целиком теряется. Для всех остальных значений `empty_i` (от 0 до 6) выходной beat генерируется корректно.

**Ожидаемое поведение:** Для пакета с `empty=7` должен быть сформирован один выходной beat с `sop=1, eop=1, empty=7` и корректными данными.

**Фактическое поведение:** Выходной beat не формируется, очередь ожиданий для порта остаётся непустой. В финальном отчёте скорборда фиксируется ошибка потерянных beat'ов.

**Сообщения в transcript:**

```
Error: [SCB] Port 0 has 26 pending beat(s) never received - LOST PACKETS!
Time: 2155 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158
```

**Время первого воспроизведения:** `T = 2105 ps` (отправка beat'а с `empty=7`), обнаружено в `final_report` на `T = 2155 ps`

---
