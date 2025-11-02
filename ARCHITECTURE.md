# System Architecture - FPGA Wordle Game

Detailed technical documentation of the dual-FPGA Wordle implementation.

## Table of Contents
1. [System Overview](#system-overview)
2. [Clock Architecture](#clock-architecture)
3. [FPGA 1: Game Logic](#fpga-1-game-logic)
4. [FPGA 2: Display & Input](#fpga-2-display--input)
5. [Serial Communication](#serial-communication)
6. [VGA Display System](#vga-display-system)
7. [PS/2 Keyboard Interface](#ps2-keyboard-interface)
8. [Data Structures](#data-structures)

---

## System Overview

### Design Philosophy
The system uses a **dual-FPGA architecture** to separate concerns:
- **FPGA1** focuses on pure game logic (stateless word checking)
- **FPGA2** manages all I/O (display, keyboard, game state)

This separation allows for:
- Easier debugging (test each FPGA independently)
- Better resource utilization
- Cleaner code organization

### Communication Flow
```
User Input (Keyboard) → FPGA2 → Serial TX → FPGA1 (Word Check) → Serial RX → FPGA2 → Display (VGA)
```

---

## Clock Architecture

### Primary Clock: 20 MHz Oscillator
Both FPGAs have on-board 20 MHz oscillators connected to pin P54.

### FPGA2 Clock Generation (DCM)
**File**: `clock_generator.vhd`

The VGA pixel clock requires precisely 25 MHz for 640×480@60Hz. We use a Digital Clock Manager (DCM_SP) to generate this:

```
20 MHz (input) → DCM_SP → 50 MHz (CLKFX) → ÷2 → 25 MHz (pixel_clk)
```

**DCM Configuration**:
```vhdl
DCM_SP generic map (
    CLKFX_MULTIPLY => 5,      -- Multiply by 5
    CLKFX_DIVIDE => 2,        -- Divide by 2  → 20×(5/2) = 50 MHz
    CLKIN_DIVIDE_BY_2 => FALSE,
    CLKIN_PERIOD => 50.0,     -- 20 MHz = 50ns period
    CLK_FEEDBACK => "1X",
    STARTUP_WAIT => TRUE      -- Critical: wait for DCM to lock
)
```

**Output Signals**:
- `CLK0`: 20 MHz feedback (phase-aligned with input)
- `CLKFX`: 50 MHz intermediate clock
- `clk_25`: 25 MHz pixel clock (50 MHz ÷ 2)
- `LOCKED`: DCM lock indicator (connected to LED L0)

**Why DCM and not simple divider?**
- A simple ÷2 divider from 20 MHz → 10 MHz doesn't match VGA spec (25 MHz required)
- DCM provides frequency multiplication with phase-locked stability
- `STARTUP_WAIT=TRUE` ensures reliable initialization

---

## FPGA 1: Game Logic

**Top-level**: `fpga1_top_serial.vhd`

### Components

#### 1. Word ROM (`word_rom_20mhz.vhd`)
Stores 40 five-letter words in block RAM.

**Interface**:
```vhdl
entity word_rom is
    Port (
        clk      : in  std_logic;
        address  : in  std_logic_vector(5 downto 0);  -- 0-39 (40 words)
        word_out : out std_logic_vector(39 downto 0)  -- 5 letters × 8 bits
    );
end word_rom;
```

**Data Format**: Each word stored as 5 consecutive ASCII bytes:
- Example: "HELLO" = x"48454C4C4F" (0x48='H', 0x45='E', 0x4C='L', 0x4F='O')

**Critical Fix Applied**: 
- Initial version had 36 words (incomplete hex literals)
- Fixed to exactly 40 words with proper 10-digit hex values

#### 2. Word Comparator (`word_comparator_20mhz.vhd`)
Compares player's guess against target word and assigns colors.

**Interface**:
```vhdl
entity word_comparator is
    Port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        guess_word : in  std_logic_vector(39 downto 0);  -- Player guess
        target_word: in  std_logic_vector(39 downto 0);  -- Answer from ROM
        valid      : in  std_logic;                      -- Start comparison
        result     : out std_logic_vector(14 downto 0);  -- 5×3 bits color
        result_valid: out std_logic                      -- Result ready
    );
end word_comparator;
```

**Color Encoding** (3 bits per letter):
- `"010"` (2): Green - correct letter, correct position
- `"110"` (6): Yellow - correct letter, wrong position
- `"101"` (5): Magenta - letter not in word

**Algorithm**:
1. First pass: Mark exact matches (green)
2. Second pass: Check remaining letters for wrong-position matches (yellow)
3. Remaining letters: Mark as not in word (magenta)

**Critical Fix Applied**:
- Output port `result_valid` cannot be read internally in VHDL
- Solution: Use internal signal `result_valid_i` and assign to output

#### 3. Serial Transmitter (`serial_transmitter.vhd`)
Sends comparison results to FPGA2 via UART.

**Parameters**:
- Baud rate: 115200
- Clock: 20 MHz
- Data format: 8-N-1 (8 data bits, no parity, 1 stop bit)
- Frame: 1 start bit + 8 data bits + 1 stop bit = 10 bits

---

## FPGA 2: Display & Input

**Top-level**: `fpga2_top_3bit_rgb_Version2.vhd`
**Standalone test**: `fpga2_standalone_working.vhd` (no serial, keyboard testing only)

### Components

#### 1. Clock Generator (`clock_generator.vhd`)
See [Clock Architecture](#clock-architecture) section above.

#### 2. VGA Controller (`vga_controller_20mhz.vhd`)
Generates VGA timing signals for 640×480@60Hz.

**Interface**:
```vhdl
entity vga_controller is
    Port (
        pixel_clk : in  std_logic;  -- 25 MHz
        rst       : in  std_logic;
        h_sync    : out std_logic;  -- Horizontal sync (negative)
        v_sync    : out std_logic;  -- Vertical sync (negative)
        video_on  : out std_logic;  -- High during visible region
        pixel_x   : out unsigned(9 downto 0);  -- 0-799
        pixel_y   : out unsigned(9 downto 0)   -- 0-524
    );
end vga_controller;
```

**VGA 640×480@60Hz Timing** (from VESA standard):

| Parameter | Horizontal | Vertical |
|-----------|-----------|----------|
| Visible area | 640 pixels | 480 lines |
| Front porch | 16 pixels | 10 lines |
| Sync pulse | 96 pixels | 2 lines |
| Back porch | 48 pixels | 33 lines |
| **Total** | **800 pixels** | **525 lines** |
| Frequency | 31.5 kHz | 60 Hz |

**Sync Polarity**: Negative (active LOW)
- Sync pulse is LOW during sync period
- HIGH during visible + porch regions

**Critical Fixes Applied**:
1. Renamed constants `H_SYNC_WIDTH`, `V_SYNC_WIDTH` to avoid port name conflicts
2. Added internal signals `h_sync_i`, `v_sync_i` for readable sync generation
3. Changed from 10 MHz (initial attempt) to 25 MHz pixel clock (correct VGA spec)

#### 3. Display Renderer (`display_renderer_3bit_rgb_Version2.vhd`)
Renders the 6×5 Wordle grid with letters and colors.

**Interface**:
```vhdl
entity display_renderer is
    Port (
        clk         : in  std_logic;  -- 25 MHz pixel clock
        rst         : in  std_logic;
        pixel_x     : in  unsigned(9 downto 0);     -- Current pixel X
        pixel_y     : in  unsigned(9 downto 0);     -- Current pixel Y
        video_on    : in  std_logic;                -- VGA visible region
        game_grid   : in  std_logic_vector(1079 downto 0);  -- Game state (flattened)
        current_row : in  unsigned(2 downto 0);     -- Row being edited (0-5)
        current_col : in  unsigned(2 downto 0);     -- Col being edited (0-4)
        game_status : in  std_logic_vector(2 downto 0);  -- Game state (win/loss/play)
        rgb         : out std_logic_vector(2 downto 0)   -- 3-bit RGB output
    );
end display_renderer;
```

**Game Grid Format** (`game_grid`): 1080 bits total
- 6 rows × 5 columns = 30 cells
- Each cell = 11 bits (8-bit letter + 3-bit color)
- Total = 30 × 11 = 330 bits used (bits 0-329)
- Bits 330-1079 unused (filled with zeros)

**Cell Extraction**:
```vhdl
index := cell_row * 5 + cell_col;  -- 0-29
cell_letter <= game_grid(index*11+10 downto index*11+3);  -- 8 bits
cell_color  <= game_grid(index*11+2 downto index*11);     -- 3 bits
```

**Rendering Layout**:
- **Cell size**: 60×60 pixels
- **Border**: 2 pixels (white)
- **Inner area**: 56×56 pixels (for letter + color background)
- **Character**: 40×40 pixels (8×8 font scaled 5×)
- **Character offset**: 8 pixels from cell edge (centered)

**Grid Position**: Centered on 640×480 screen
- Grid total size: 300×360 pixels (5 cols × 6 rows)
- Top-left corner: (170, 60) pixels
- Each cell: `(170 + col×60, 60 + row×60)`

**Color Background**: Cell filled with game color before drawing character
- Green `"010"`: RGB = (0, 255, 0) → 3-bit = `"010"`
- Yellow `"110"`: RGB = (255, 255, 0) → 3-bit = `"110"`
- Magenta `"101"`: RGB = (255, 0, 255) → 3-bit = `"101"` (used as gray substitute)
- Black `"000"`: No color assigned yet

**Critical Fix Applied**:
- Typo: `COLOR_BORDERS` → `COLOR_BORDER` (extra 'S')

#### 4. Character ROM (`char_rom.vhd`)
8×8 pixel bitmap font for letters A-Z.

**Interface**:
```vhdl
entity char_rom is
    Port (
        clk       : in  std_logic;
        char_code : in  std_logic_vector(7 downto 0);  -- ASCII A-Z (0x41-0x5A)
        row       : in  unsigned(2 downto 0);          -- Row 0-7
        col       : in  unsigned(2 downto 0);          -- Col 0-7
        pixel     : out std_logic                      -- 0=black, 1=white
    );
end char_rom;
```

**Font Data**: 26 characters × 8 rows × 8 bits
- Each character stored as 8×8 bit matrix
- '1' = draw pixel (white), '0' = transparent (show background color)

**Usage in Renderer**:
- Character scaled 5× → 40×40 pixels displayed
- Coordinates converted: `(char_row, char_col) = (pixel_offset div 5)`

#### 5. PS/2 Keyboard (`ps2_keyboard_20mhz.vhd`)
Handles PS/2 protocol and converts scancodes to ASCII.

**Interface**:
```vhdl
entity ps2_keyboard is
    Port (
        clk           : in  std_logic;  -- 20 MHz
        rst           : in  std_logic;
        ps2_clk       : in  std_logic;  -- PS/2 clock (from keyboard)
        ps2_data      : in  std_logic;  -- PS/2 data (from keyboard)
        key_ascii     : out std_logic_vector(7 downto 0);  -- ASCII code
        key_valid     : out std_logic;                     -- New key pressed
        enter_pressed : out std_logic;                     -- Enter key
        backspace     : out std_logic                      -- Backspace key
    );
end ps2_keyboard;
```

**Supported Keys**:
- A-Z: Converted to uppercase ASCII (0x41-0x5A)
- Enter: 0x5A scancode → `enter_pressed` pulse
- Backspace: 0x66 scancode → `backspace` pulse

**PS/2 Protocol**:
- Clock frequency: ~10-16 kHz (keyboard-generated)
- Data format: 1 start bit + 8 data bits + 1 parity bit + 1 stop bit
- Start bit: 0, Stop bit: 1

#### 6. Serial Receiver (`serial_receiver.vhd`)
Receives word comparison results from FPGA1.

**Parameters**: Same as transmitter (115200 baud, 8-N-1)

---

## Serial Communication

### Protocol
- **Baud rate**: 115200
- **Data format**: 8-N-1 (8 data bits, no parity, 1 stop bit)
- **Direction**: FPGA1 (TX) → FPGA2 (RX)

### Data Frame
When player submits a guess (Enter key):
1. FPGA2 sends 5 letters (40 bits) to FPGA1 via serial
2. FPGA1 compares with target word
3. FPGA1 sends back 15 bits (5 colors × 3 bits) via serial
4. FPGA2 updates display with new colors

### Timing
- Bit period: 1/115200 ≈ 8.68 μs
- Frame time: 10 bits × 8.68 μs ≈ 86.8 μs per byte
- Total communication: ~0.5 ms per guess (negligible delay)

---

## VGA Display System

### Signal Flow
```
pixel_clk (25 MHz) → VGA Controller → (pixel_x, pixel_y, video_on)
                                              ↓
                          Display Renderer ← game_grid ← Game State
                                              ↓
                                      (rgb_signal) → VGA pins
```

### Timing Critical Points
1. **Pixel clock must be exactly 25.000 MHz**
   - Too fast/slow → monitor won't sync
   - DCM provides precise frequency synthesis

2. **Sync pulses must be negative polarity**
   - VESA standard for 640×480@60Hz
   - Sync = LOW during pulse, HIGH otherwise

3. **RGB outputs valid only during `video_on='1'`**
   - Must output BLACK ('000') during blanking intervals
   - Prevents garbage pixels in overscan areas

### Debug: VGA Not Displaying
**Checklist**:
1. Check LED L0 (DCM locked) - must be ON
2. Verify 20 MHz oscillator present on P54
3. Confirm VGA cable connected to K4 connector
4. Check pin assignments: P126 (hsync), P131 (vsync), P133/P137/P139 (RGB)
5. Ensure sync signals are negative polarity (active LOW)
6. Verify pixel clock is 25 MHz (measure with oscilloscope if available)

---

## PS/2 Keyboard Interface

### Hardware Connection
- PS/2 clock: Pin P43 (K2 connector)
- PS/2 data: Pin P44 (K2 connector)
- Both pins require pull-up resistors (usually built into keyboard connector)

### Software State Machine
1. Idle: Wait for ps2_clk falling edge
2. Receive 11 bits: start + 8 data + parity + stop
3. Verify parity and stop bit
4. Decode scancode → ASCII (if A-Z)
5. Pulse `key_valid` for one clock cycle

### Scancode Mapping (Make codes)
- 0x1C → A (0x41)
- 0x32 → B (0x42)
- ...
- 0x1A → Z (0x5A)
- 0x5A → Enter
- 0x66 → Backspace

---

## Data Structures

### Game Grid (FPGA2 Internal)
```vhdl
type grid_cell is record
    letter : std_logic_vector(7 downto 0);  -- ASCII code
    color  : std_logic_vector(2 downto 0);  -- RGB color
end record;

type grid_row is array (0 to 4) of grid_cell;  -- 5 columns
type grid_type is array (0 to 5) of grid_row;  -- 6 rows
signal game_grid : grid_type;
```

### Flattening Process
To pass `game_grid` to `display_renderer` (which expects std_logic_vector):

```vhdl
signal game_grid_flat : std_logic_vector(1079 downto 0);

process(game_grid)
    variable idx : integer;
begin
    game_grid_flat <= (others => '0');  -- Clear unused bits
    idx := 0;
    for row in 0 to 5 loop
        for col in 0 to 4 loop
            -- Pack letter (8 bits) + color (3 bits) = 11 bits per cell
            game_grid_flat(idx + 10 downto idx) <= 
                game_grid(row)(col).letter & game_grid(row)(col).color;
            idx := idx + 11;
        end loop;
    end loop;
end process;
```

**Result**: 
- Bits 0-10: Row 0, Col 0
- Bits 11-21: Row 0, Col 1
- ...
- Bits 319-329: Row 5, Col 4
- Bits 330-1079: Unused (all zeros)

### Game State
```vhdl
current_row : unsigned(2 downto 0);  -- 0-5 (which row is being edited)
current_col : unsigned(2 downto 0);  -- 0-4 (how many letters typed in current row)
```

When `current_col = 5` → row is complete → can press Enter

---

## Testing & Validation

### FPGA2 Standalone Test (`fpga2_standalone_working.vhd`)
Tests VGA + keyboard without FPGA1 connection:

**Keyboard Handler** (when standalone):
- Type A-Z → fills `game_grid` with letters (no color)
- Backspace → removes last letter
- Enter (when 5 letters) → applies test color pattern:
  - Cols 0,4: Green
  - Cols 1,3: Yellow
  - Col 2: Magenta

**Expected Result**:
- See 6×5 grid on VGA
- Type letters, see them appear
- Enter applies rainbow colors, moves to next row

### Integration Test (Full System)
1. Flash `fpga1_top_serial.vhd` to FPGA1
2. Flash `fpga2_top_3bit_rgb_Version2.vhd` to FPGA2
3. Connect serial cable (TX1 → RX2, GND)
4. Type 5-letter word
5. Press Enter
6. See real Wordle colors (based on actual word comparison)

---

## Performance Metrics

- **FPGA1 Resource Usage**: ~15% LUTs, ~5% FFs, 1 BRAM (word ROM)
- **FPGA2 Resource Usage**: ~35% LUTs, ~20% FFs, 1 BRAM (char ROM), 1 DCM
- **Max Clock Frequency**: >50 MHz (20 MHz system clock, 25 MHz pixel clock)
- **Latency**: <1 ms from keypress to display update
- **Serial Throughput**: ~11.5 KB/s (115200 bps)

---

## Known Limitations

1. **Keyboard**: Only uppercase A-Z supported (no lowercase, numbers, or symbols)
2. **Display**: 3-bit RGB limits color palette (magenta used instead of gray)
3. **Word Database**: Only 40 words (easily expandable by editing ROM)
4. **No Audio**: No buzzer or audio feedback
5. **Single Game**: Must press reset button to play again (no automatic restart)

---

## Future Improvements

- [ ] Expand word database to 100+ words
- [ ] Add game status text ("WIN!", "GAME OVER")
- [ ] Implement on-screen keyboard for easier input
- [ ] Add timer/turn counter
- [ ] Support lowercase input (auto-convert to uppercase)
- [ ] Add buzzer for audio feedback
- [ ] Implement automatic restart after win/loss

---

**Last Updated**: November 2025
