# Отчёт по верификации модуля демультиплексора потоковых интерфейсов Avalon-ST

**Модуль:** `ast_dmx.sv`

**Параметры симуляции:** `DATA_WIDTH=64`, `CHANNEL_WIDTH=8`, `TX_DIR=4`, `PACKETS=20`

**Seed:** `12345`

---

## Таблица обнаруженных ошибок

| № | Название бага                                                 | Симуляционное время первого воспроизведения | Сообщение в transcript                                                                                                                                                            |
| -- | ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1  | Потеря сигнала `channel` на выходе 2 (`dir_i=2`) | **T = 325 ps**                                                                | `Error: [SCB] @325 beat #24 port 2: CHANNEL mismatch! Got=x Exp=1000100`<br />`Time: 325 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107`      |
| 2  | Потеря выходного beat'а при `empty_i = 7`            | **T = 1765 ps**                                                               | `Error: [SCB] Port 0 has 6 pending beat(s) never received - LOST PACKETS!`<br />`Time: 5035 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158` |

---

## Детальное описание ошибок

### Баг №1: Потеря сигнала `channel` на выходе 2 (`dir_i=2`)

**Описание:**
При передаче пакета с `dir_i=2` значение `channel_o` всегда равно `x`, независимо от входного `channel_i`. На остальных выходах канал передаётся корректно.

**Ожидаемое поведение:** корректная выдача текущего канала внутри передачи.

**Фактическое поведение:** На выходе 2 (`dir=2`) `channel_o = x`.

**Сообщения в transcript:**

```
Error: [SCB] @325 beat #24 port 2: CHANNEL mismatch! Got=x Exp=1000100
Time: 325 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.check_beat File: scoreboard.sv Line: 107
```

**Время первого воспроизведения:** `T = 325 ps`

---

### Баг №2: Потеря выходного beat'а при `empty_i = 7`

**Описание:**
Если на вход демультиплексора подаётся пакет, состоящий из одного beat'а с `empty=7` (т.е. только 1 значащий байт из 8), модуль не формирует выходной beat: сигнал `valid_o` остается равным 0, `channel_o` не определён. Пакет целиком теряется. Для всех остальных значений `empty` (от 0 до 6) выходной beat генерируется корректно.

**Ожидаемое поведение:** Для пакета с `empty=7` должен быть сформирован один выходной beat с `sop=1, eop=1, empty=7` и корректными данными.

**Фактическое поведение:** Выходной beat не формируется, очередь ожиданий для порта остаётся непустой. В финальном отчёте скорборда фиксируется ошибка потерянных beat'ов.

**Сообщения в transcript:**

```
Error: [SCB] Port 0 has 6 pending beat(s) never received - LOST PACKETS!
Time: 5035 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158
Error: [SCB] Port 1 has 4 pending beat(s) never received - LOST PACKETS!
Time: 5035 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158
Error: [SCB] Port 2 has 7 pending beat(s) never received - LOST PACKETS!
Time: 5035 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158
Error: [SCB] Port 3 has 10 pending beat(s) never received - LOST PACKETS!
Time: 5035 ps  Scope: ast_dmx_pkg.Scoreboard.Scoreboard__1.final_report File: scoreboard.sv Line: 158
```

**Время первого воспроизведения:** `T = 1765 ps` (отправка beat'а с `empty=7`), обнаружено в `final_report` на `T = 5035 ps`

---
