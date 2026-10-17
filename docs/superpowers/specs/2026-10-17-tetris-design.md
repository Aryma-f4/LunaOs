# Tetris — completion design (scope C)

Date: 2026-10-17
Status: approved (design), pending spec review

## Context / evidence

`software/tetris.asm` + `software/tetris/*` is a skeleton:

- Main loop runs `tetris_collision` once, one `bosu_event`, then `jmp $` — the
  process hangs; the window registers with the WM (taskbar entry "Tetri") but is
  never flushed, so it never appears on screen.
- `tetris_collision` detects overlap but discards it (`nop`, no result flag).
- `tetris_random_block`/`tetris_random_model` `div` with uninitialized `edx`
  (128-bit dividend) — `#DE` or garbage whenever entry `rdx >= 7`.
- Window title length byte is `db 5` → shows "Tetri" instead of "Tetris".
- No drawing, gravity, input handling, locking, line clear, score, or game over.

Verified in QEMU: frame identical after arrow-key spam + 2 s; no window pixels.

## Scope (user choice: C)

Playable Tetris with score label, next-piece preview, and escalating drop speed.
Explicitly out of scope: wall kicks, hold piece, 7-bag randomizer, pause,
high-score persistence, sound.

## Chosen approach (user choice: A)

Single poll loop, full redraw on state change, no kernel changes. Window is
140×144 px; redrawing everything per state change is trivially cheap.

## 1. Loop & architecture (`software/tetris.asm`)

```
tetris:
  create window (bosu)               ; jc .close
  init game state (reset routine)
  spawn first piece
  full redraw
.loop:
  bosu_event → CF=1: no message
               keyboard: dx = key code → input handler
               mouse: close button (existing bosu path → tetris.close)
  SYSTEM_time → if rax >= [tetris_next_tick]:
                  gravity step (try y+1; on blocked: lock → clear → spawn)
                  [tetris_next_tick] = now + [tetris_interval]
  if state changed → full redraw (flush flag + KERNEL_WM_WINDOW_update)
  jmp .loop
```

Register convention: r8 = piece x, r9 = piece y (skeleton convention kept).
State-changed flag: one byte, set by any input/gravity/lock outcome, cleared by
redraw.

## 2. State & data (`software/tetris/data.asm`)

Kept as-is:

- `tetris_brick_platform`: 23 words — rows 0..21 + floor row 22.
  Row = 16 bits: bit 0 = left wall, bits 1..10 = playfield (10 cells),
  bit 11 = right wall, floor row = `0x0FFF`. Empty row = `0x0801`.
- `tetris_bricks`: 7 qwords × 4 words = rotation states; state 0 = lowest word;
  pattern row r = `(pattern >> r*4) & 0xF` (row 0 = top).
- `tetris_brick_position_x/y`.

Added:

- `tetris_brick_pattern` (word) — active pattern.
- `tetris_brick_next` (word) — next piece (preview); spawn fills from it.
- `tetris_brick_piece` (byte) — active piece index 0..6 (color source).
- `tetris_score`, `tetris_lines`, `tetris_level` (qwords).
- `tetris_game_over` (byte), `tetris_tick` (byte — state changed flag).
- `tetris_next_tick`, `tetris_interval` (qwords, RTC ticks).
- `tetris_brick_colors`: 7 × dd BGRA palette (one color per piece).
- `tetris_cell_colors`: 22 × 10 bytes; 0 = empty, else piece index + 1.
- Title length `db 5` → `db 6`.

## 3. Collision contract (`software/tetris/collision.asm`)

Entry: r8 = x (bit shift), r9 = y (platform row), bx = pattern word.
For each of the 4 rows: `(nibble << x) & platform[y + row]`; if `y + row > 22`
treat as collision without reading past the array.

Exit: **CF = 1 collision, CF = 0 free** (codebase convention). The `nop`
placeholder is replaced by a real `stc` result path. r8/r9/bx preserved.

Movement = trial position → collision → restore on fail. x additionally
clamped to [1,7] so pattern bits always land inside bits 1..10.

## 4. Rendering (NEW `software/tetris/draw.asm`)

Full redraw; all writes go through `tetris_window.address` +
`LIBRARY_BOSU_STRUCTURE_WINDOW_EXTRA.scanline_byte`. Element origins are read
from the element structs *after* border correction (playground = x 1, y
border+header).

Window layout: playground 70×140 px (left) + **panel 70 px wide** (right);
`TETRIS_WINDOW_WIDTH_pixel = TETRIS_PLAYGROUND_WIDTH_pixel + TETRIS_PANEL_WIDTH_pixel`.

- Playground: fill background → for rows 2..21 × cols 1..10, draw 6×6 px tile at
  7 px pitch from `tetris_cell_colors` (the 1 px gap forms the grid) → draw the
  active piece cells on top in `tetris_brick_colors[piece]`, **skipping piece
  rows whose platform row < 2** (hidden rows — never write above the header).
- Panel (x = 70 pre-correction → 71 after; top = border+header):
  - `NEXT` draw element 70×64: clears its area, draws the next pattern as
    4×4 tiles (7 px pitch) centered in its color.
  - label `SCORE n` 70×16 at y+64, `LINES n` 70×16 at y+80,
    `LEVEL n` 70×16 at y+96 (font 6×12 → 11-char budget, 66 px).
- Labels: write string bytes + length into the element structs, then call
  `library_bosu_element_label` per element — same pattern as calculator's
  `.refresh`.
- After all drawing: `or flags, LIBRARY_BOSU_WINDOW_FLAG_flush` +
  `mov al, KERNEL_WM_WINDOW_update; int KERNEL_WM_IRQ`.
- Number→string via `integer_to_string` (already used by calculator).

## 5. Input (dx from `bosu_event`; unrecognised codes ignored — releases, E0 junk)

| key | code | action |
|---|---|---|
| ← | `0xE04B` | x−1 (clamp ≥1), trial collision |
| → | `0xE04D` | x+1 (clamp ≤7), trial collision |
| ↑ | `0xE048` | `rol bx,16` rotate, restore on collision (no wall kicks) |
| ↓ | `0xE050` | soft drop one row + reset `next_tick` |
| space | `0x20` | hard drop: move down until blocked → lock immediately |
| r / R / Enter | `0x72` / `0x52` / `0x0D` | restart **only while game over** (ps2.asm delivers ASCII for letters) |

Successful actions set the state-changed flag.

## 6. Gravity, levels, score

- `interval = max(102, 1024 − level × 102)` ticks (1 s → 0.1 s floor);
  `next_tick = now + interval` after every tick (no drift).
- `level = lines / 10`.
- Clear of n rows (n = 1..4): `score += table[n] × (level + 1)` with
  table = {40, 100, 300, 1200}, using the level **before** the update; then
  recompute `level` and `interval`.

## 7. Line clear

Bottom-up scan of rows 0..21: full row when `(row & 0x07FE) == 0x07FE` → shift
every row above down by one (platform words and `tetris_cell_colors` rows in
parallel), reset top row to `0x0801` / zeros, re-check the same index.
Floor row (22) and wall bits are preserved by the copy.

## 8. Game over & restart

- Spawn collision → `tetris_game_over = 1`, title via `library_bosu_header_set`
  → `"Tetris - game over, press R"`; gravity and piece input frozen.
- Restart (`r`/Enter): platform ← walls+empty+floor, colors ← 0, score/lines/
  level ← 0, game_over ← 0, title ← `"Tetris"`, interval/next_tick reset,
  spawn, full redraw.

## 9. Verification (QEMU, screenshots — no unit framework in this OS)

1. Launch → window visible with grid, piece, preview, labels (today: invisible).
2. send-key `left/right/up/down/space` between screenshots: move, rotate,
   soft drop, hard drop + lock, next-piece spawn each observable.
3. Line clear hands-on: read each frame, aim pieces to fill the bottom row,
   confirm the row disappears and SCORE increments.
4. Game over: scripted hard-drop spam until the title changes; `r` restores.
5. Regression: close button still closes the window.

## Files

- rewrite: `software/tetris.asm` (loop, input, gravity)
- new: `software/tetris/draw.asm`, `software/tetris/game.asm`
  (spawn/lock/clear/reset — game rules independent of I/O)
- fix: `collision.asm` (result contract + bounds), `random.asm` (`xor edx,edx`
  before both `div`s), `data.asm` (state, elements, panel, title length),
  `config.asm` (panel/window sizes)

## Known simplifications (deliberate)

- No wall kicks: rotation that collides is rejected as-is.
- Random = existing xorshift + uniform-mod (slight modulo bias, not worth
  fixing), not a 7-bag.
- Full redraw per state change instead of dirty regions.
- Score label shows at most 11 chars (`SCORE 99999`); longer scores clip —
  unreachable in a normal session.
