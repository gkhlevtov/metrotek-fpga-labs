# Отчёт по верификации модуля демультиплексора потоковых интерфейсов Avalon-ST

**Модуль:** `ast_dmx.sv`

**Параметры симуляции:** `DATA_WIDTH=64`, `CHANNEL_WIDTH=8`, `TX_DIR=4`, `PACKETS=40`

**Seed:** `12345`

---

## Таблица обнаруженных ошибок

| № | Название бага                                                           | Симуляционное время первого воспроизведения | Сообщение в transcript                                                                                                                                                                         |
| -- | ----------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | Потеря сигнала`channel` на выходе 2 (`dir_i=2`)            | **T = 415 ps**                                                                | `Error: [SCB] @415 beat #33 port 2: CHANNEL mismatch! Got=x Exp=11011001`<br />`Time: 415 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107`                  |
| 2  | Потеря выходного beat'а при `empty_i = 7`                     | **T = 1815 ps**                                                               | `Error: [SCB] @2285: LOST PACKETS on port 0 - 1 beat(s) sent but never received by DUT output!`<br />`Time: 2285 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.reset File: scoreboard.sv Line: 48` |
| 3  | Выдача прошлого beat'а при смене`ready` при `eop = 1` | **T = 19155 ps**                                                              | `Error: [SCB] @19155 beat #866 port 3: DATA mismatch! Got=77b9142c2343c327 Exp=070a589d3fcc7a03` <br /> `Time: 19155 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 136`  |

---

## Детальное описание ошибок

### Баг №1: Потеря сигнала `channel` на выходе 2 (`dir_i=2`)

**Описание:**
При передаче пакета с `dir_i=2` значение `channel_o` всегда равно `x`, независимо от входного `channel_i`. На остальных выходах канал передаётся корректно.

**Ожидаемое поведение:** корректная выдача текущего канала внутри передачи.

**Фактическое поведение:** На выходе 2 (`dir=2`) `channel_o = x`.

**Сообщения в transcript:**

```
Error: [SCB] @415 beat #33 port 2: CHANNEL mismatch! Got=x Exp=11011001
Time: 415 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107
```

**Время первого воспроизведения:** `T = 415 ps`

---

### Баг №2: Потеря выходного beat'а при `empty_i = 7`

**Описание:**
Если на вход демультиплексора подаётся пакет, состоящий из одного beat'а с `empty=7` (т.е. только 1 значащий байт из 8), модуль не формирует выходной beat: сигнал `valid_o` остается равным 0, `channel_o` не определён. Пакет целиком теряется. Для всех остальных значений `empty` (от 0 до 6) выходной beat генерируется корректно.

**Ожидаемое поведение:** Для пакета с `empty=7` должен быть сформирован один выходной beat с `sop=1, eop=1, empty=7` и корректными данными.

**Фактическое поведение:** Выходной beat не формируется, очередь ожиданий для порта остаётся непустой. В финальном отчёте скорборда фиксируется ошибка потерянных beat'ов.

**Сообщения в transcript:**

```
Error: [SCB] @2285: LOST PACKETS on port 0 - 1 beat(s) sent but never received by DUT output!
Time: 2285 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.reset File: scoreboard.sv Line: 48
Error: [SCB] @2285: LOST PACKETS on port 1 - 1 beat(s) sent but never received by DUT output!
Time: 2285 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.reset File: scoreboard.sv Line: 48
Error: [SCB] @2285: LOST PACKETS on port 2 - 1 beat(s) sent but never received by DUT output!
Time: 2285 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.reset File: scoreboard.sv Line: 48
Error: [SCB] @2285: LOST PACKETS on port 3 - 1 beat(s) sent but never received by DUT output!
Time: 2285 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.reset File: scoreboard.sv Line: 48
```

**Время первого воспроизведения:** `T = 1815 ps` (отправка beat'а с `empty=7`), обнаружено в ошибке после drain() на `T = 2285 ps`

---

### Баг №3: Выдача прошлого beat'а при смене `ready` при `eop = 1`

**Описание:**
При выпадении beat'a с `eop = 1` на момент, когда `ready` на выбранном порту равен 0, и возвращении к `ready = 1`, DUT переключает и передаёт data из прошлого, уже переданного beat'a.

**Ожидаемое поведение:** DUT сохраняет на выходе `data` актуальное значение со входа, дожидается `ready = 1`  и завершает передачу, не меняя данные.

**Фактическое поведение:** Как только `ready = 1`, значение `data` последнего в пакете beat'a меняется на значение `data` от предыдущего beat'a. 

**Сообщения в transcript:**

```
Error: [SCB] @19155 beat #866 port 3: DATA mismatch! Got=77b9142c2343c327 Exp=070a589d3fcc7a03
Time: 19155 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 136
```

**Время первого воспроизведения:** `T = 19155 ps`

---
