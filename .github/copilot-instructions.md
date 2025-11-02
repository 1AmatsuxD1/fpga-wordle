# GitHub Copilot Instructions - FPGA Wordle Project

**READ THIS FIRST** when assisting with this project. This document provides critical context for AI assistants.

---

## 🎯 Project Context

### What Is This Project?
A **hardware implementation of Wordle** on dual Spartan-6 FPGA boards with VGA display and PS/2 keyboard input.

### Current Status (November 2025)
- ✅ **FPGA1** (Game Logic): Code complete, compiled successfully
- ✅ **FPGA2** (Display): VGA working with 6×5 grid, display renderer tested
- ✅ **Clock Generation**: DCM working (20MHz → 25MHz pixel clock)
- ✅ **VGA Output**: 640×480@60Hz, 3-bit RGB, test pattern confirmed working
- ⏳ **Keyboard Integration**: Code exists but not yet tested with physical keyboard
- ⏳ **Serial Communication**: Code exists but not yet tested between FPGAs
- ⏳ **Full System**: Not yet integrated and tested

### What Works Right Now
1. **Standalone FPGA2 test** (`fpga2_standalone_working.vhd`):
   - VGA displays 6×5 Wordle grid correctly
   - DCM locks reliably (LED L0 indicator)
   - Display renderer shows letters and colors (verified with hardcoded test data)
   - Keyboard handler code present (not yet tested)

2. **Individual FPGA1 components** (not tested together):
   - Word ROM with 40 words
   - Word comparator logic
   - Serial transmitter

### Known Working Hardware
- **Board**: Surveyor SV6 (Spartan-6 XC6SLX9-2TQG144)
- **Oscillator**: 20 MHz on pin P54
- **VGA Connector**: K4 (pins P126=hsync, P131=vsync, P133/P137/P139=RGB)
- **DCM**: Successfully generates 25 MHz from 20 MHz input

---

## 🗂️ File Organization

### Active Files (DO USE)

#### FPGA1 - Game Logic (`fpga1_logic/`)
- **`fpga1_top_serial.vhd`**: Top-level entity (MAIN FILE for FPGA1)
  - Instantiates word_rom, word_comparator, serial_transmitter
  - Handles game state machine
  - NOT YET TESTED ON HARDWARE

- **`word_rom_20mhz.vhd`**: 40-word database
  - Fixed: Now has exactly 40 words (was 36)
  - Each word is 40 bits (5 letters × 8-bit ASCII)
  - **DO NOT** modify word format without updating comparator

- **`word_comparator_20mhz.vhd`**: Word checking logic
  - Compares guess vs target word
  - Outputs 15-bit result (5 colors × 3 bits)
  - Fixed: Uses internal signal `result_valid_i` (output ports are write-only)

- **`fpga1_constraints_final.ucf`**: Pin assignments for FPGA1

#### FPGA2 - Display/Input (`fpga2_vga/`)
- **`fpga2_top_3bit_rgb_Version2.vhd`**: Top-level entity (MAIN FILE for full system)
  - Includes serial receiver for FPGA1 communication
  - NOT YET TESTED - use standalone version for now

- **`fpga2_standalone_working.vhd`**: Standalone test version (USE THIS FOR TESTING)
  - NO serial communication
  - VGA + keyboard only
  - **CURRENTLY WORKING** - verified on hardware
  - Good starting point for modifications

- **`clock_generator.vhd`**: DCM-based clock generator ⚡ CRITICAL
  - 20MHz → 50MHz → 25MHz pixel clock
  - `STARTUP_WAIT => TRUE` is essential for reliability
  - **DO NOT** change DCM settings without understanding VGA timing

- **`vga_controller_20mhz.vhd`**: VGA timing generator
  - 640×480@60Hz, negative sync (active LOW)
  - Fixed: Uses internal signals `h_sync_i`, `v_sync_i` (output ports are write-only)
  - **DO NOT** change timing constants (verified against VESA standard)

- **`display_renderer_3bit_rgb_Version2.vhd`**: Game grid renderer
  - Renders 6 rows × 5 columns = 30 cells
  - Each cell: 60×60 pixels, character 40×40 pixels
  - Fixed: `COLOR_BORDER` (was `COLOR_BORDERS` typo)

- **`char_rom.vhd`**: 8×8 pixel bitmap font for A-Z
  - 26 characters, scaled 5× to 40×40 pixels
  - **DO NOT** modify unless adding new characters

- **`ps2_keyboard_20mhz.vhd`**: PS/2 keyboard input
  - Converts scancodes to ASCII (A-Z only)
  - **NOT YET TESTED** with physical keyboard

- **`fpga2_constraints_3bit_rgb_Version2.ucf`**: Pin assignments for full FPGA2
- **`fpga2_standalone_working.ucf`**: Pin assignments for standalone test

#### Shared Components (root directory)
- **`serial_transmitter.vhd`**: UART TX (115200 baud, 8-N-1)
- **`serial_receiver.vhd`**: UART RX (115200 baud, 8-N-1)
- **`serial_communication_tb.vhd`**: Testbench (simulation only, not for synthesis)

### Archive Files (DO NOT USE)
- **`fpga2_vga/archive/`**: Old VGA test files
  - `vga_test_*.vhd`: Debugging files (kept for reference)
  - `fpga2_standalone_test.vhd`, `fpga2_standalone_simple.vhd`: Superseded by `fpga2_standalone_working.vhd`
  - These files were used during VGA debugging but are no longer needed

---

## 🔧 Critical Technical Details

### Clock Architecture (MUST UNDERSTAND)
```
20 MHz input → DCM_SP → 50 MHz (CLKFX) → ÷2 → 25 MHz pixel clock
```

**Why This Matters**:
- VGA 640×480@60Hz **requires** 25 MHz pixel clock (VESA standard)
- Simple clock divider (20MHz ÷ 2 = 10MHz) is WRONG
- DCM provides frequency multiplication: 20 × (5/2) = 50 MHz
- Must use `STARTUP_WAIT => TRUE` for reliable DCM initialization

**If Changing Clock**:
- Pixel clock MUST be 25 MHz for VGA to work
- DCM settings in `clock_generator.vhd` are verified working
- Changing these will break VGA display

### VGA Timing (DO NOT MODIFY)
**Verified Working Configuration**:
- Resolution: 640×480 @ 60Hz
- Pixel clock: 25 MHz
- H-total: 800 pixels (640 visible + 160 blanking)
- V-total: 525 lines (480 visible + 45 blanking)
- **Sync polarity**: Negative (active LOW) ← CRITICAL
- Sync pulse widths: H=96 pixels, V=2 lines

**If VGA Stops Working**:
1. Check LED L0 (DCM lock) - must be ON
2. Verify pixel clock is 25 MHz
3. Confirm sync polarity is negative (LOW during sync pulse)
4. Don't change timing constants in `vga_controller_20mhz.vhd`

### Color Encoding (3-bit RGB)
| Color   | Binary | Usage                          |
|---------|--------|--------------------------------|
| Black   | 000    | Background, empty cells        |
| Green   | 010    | Correct letter, correct position |
| Yellow  | 110    | Correct letter, wrong position  |
| Magenta | 101    | Letter not in word (used as gray) |
| White   | 111    | Text, borders                  |

**Note**: Using magenta instead of gray because 3-bit RGB doesn't have gray.

### Data Structure Conversions
**Game Grid (Internal)**:
```vhdl
type grid_cell is record
    letter : std_logic_vector(7 downto 0);  -- ASCII
    color  : std_logic_vector(2 downto 0);  -- RGB
end record;
type grid_type is array (0 to 5) of array (0 to 4) of grid_cell;
```

**Flattened for Display Renderer**:
```vhdl
signal game_grid_flat : std_logic_vector(1079 downto 0);
-- Bits 0-329: 30 cells × 11 bits (8-bit letter + 3-bit color)
-- Bits 330-1079: Unused (must be initialized to '0')
```

**Extraction Formula**:
```vhdl
index := row * 5 + col;  -- 0 to 29
cell_letter <= game_grid_flat(index*11+10 downto index*11+3);
cell_color  <= game_grid_flat(index*11+2 downto index*11);
```

---

## ⚠️ Common Pitfalls & Solutions

### 1. VHDL Output Ports Are Write-Only
**Problem**: Can't read from output ports in VHDL
```vhdl
-- ❌ WRONG
h_sync : out std_logic;
if h_sync = '1' then  -- ERROR!
```

**Solution**: Use internal signal
```vhdl
signal h_sync_i : std_logic;
h_sync <= h_sync_i;  -- Assign to output
if h_sync_i = '1' then  -- Read from internal signal
```

**Already Fixed In**:
- `vga_controller_20mhz.vhd`: `h_sync_i`, `v_sync_i`
- `fpga1_top_serial.vhd`: `result_valid_i`

### 2. DCM Lock Indicator Is Essential
**Always Connect DCM LOCKED Signal to LED**:
```vhdl
led_locked <= dcm_locked;  -- Pin P82 (LED L0)
```

**Debug**:
- LED OFF = DCM not locked → VGA won't work
- LED ON = DCM working → check other issues

### 3. VGA RGB Must Be Black During Blanking
```vhdl
if video_on = '1' then
    vga_r <= rgb_signal(2);
    vga_g <= rgb_signal(1);
    vga_b <= rgb_signal(0);
else
    vga_r <= '0';  -- Black during blanking
    vga_g <= '0';
    vga_b <= '0';
end if;
```

### 4. Game Grid Flattening Must Zero Unused Bits
```vhdl
process(game_grid)
begin
    game_grid_flat <= (others => '0');  -- Initialize first!
    -- Then pack cells...
end process;
```

Without initialization, bits 330-1079 are undefined (causes warnings).

### 5. Constants vs Ports Name Conflicts
**Problem**: Constant and port with same name
```vhdl
-- ❌ WRONG
constant H_SYNC : integer := 96;
h_sync : out std_logic;  -- Name conflict!
```

**Solution**: Rename constant
```vhdl
constant H_SYNC_WIDTH : integer := 96;  -- Different name
h_sync : out std_logic;
```

**Already Fixed In**: `vga_controller_20mhz.vhd`

---

## 🧪 Testing Procedures

### Testing FPGA2 Display (Recommended Starting Point)
1. Use **`fpga2_standalone_working.vhd`** (not the full version)
2. Add **`clock_generator.vhd`**, **`vga_controller_20mhz.vhd`**, **`display_renderer_3bit_rgb_Version2.vhd`**, **`char_rom.vhd`**, **`ps2_keyboard_20mhz.vhd`**
3. Use **`fpga2_standalone_working.ucf`** constraints
4. Synthesize, implement, generate bitstream
5. Flash to FPGA2
6. **Expected result**:
   - LED L0 turns ON (DCM locked)
   - VGA shows 6×5 grid with borders
   - Grid initially empty (black cells)

### Testing Keyboard Input (Next Step)
1. Connect PS/2 keyboard to FPGA2 K2 connector
2. Type letters A-Z (uppercase only)
3. **Expected result**:
   - Letters appear in cells as you type
   - Cursor advances automatically
   - Backspace removes last letter

### Testing Color Feedback (Standalone Mode)
1. Type 5 letters in a row
2. Press Enter
3. **Expected result** (test pattern):
   - Columns 0,4: Green background
   - Columns 1,3: Yellow background
   - Column 2: Magenta background
4. Cursor moves to next row

### Testing Full System (Future)
1. Flash `fpga1_top_serial.vhd` to FPGA1
2. Flash `fpga2_top_3bit_rgb_Version2.vhd` to FPGA2
3. Connect serial cable (TX1 → RX2, common ground)
4. Type 5-letter word and press Enter
5. **Expected result**:
   - Colors based on actual word comparison (not test pattern)
   - Real Wordle gameplay

---

## 📝 Coding Conventions

### File Naming
- `*_20mhz.vhd`: Clocked at 20 MHz (system clock)
- `*_3bit_rgb_*.vhd`: Uses 3-bit RGB color encoding
- `*_Version2.vhd`: Second iteration (supersedes Version1)
- `*_working.vhd`: Verified working on hardware
- `*_test.vhd`: Test/debug files (usually in archive/)

### Signal Naming
- `clk`: 20 MHz system clock
- `pixel_clk` or `clk_25`: 25 MHz VGA pixel clock
- `rst`: Active HIGH reset
- `*_i`: Internal signal (when output port needs to be read)
- `led_*`: LED outputs (debugging)

### Entity Naming
- Top-level: `fpga1_top_*`, `fpga2_top_*`
- Standalone: `fpga2_standalone_*`
- Descriptive: `word_comparator`, `display_renderer`, `vga_controller`

### Comments
- Use `--` for single-line comments
- Add purpose comments above major sections
- Document fixed bugs: `-- Fixed: reason for fix`

---

## 🚨 When User Says...

### "VGA not working" / "No display"
**Check List**:
1. Is LED L0 ON? (DCM locked)
   - No → Check DCM settings in `clock_generator.vhd`
   - Yes → Continue
2. Is `fpga2_standalone_working.vhd` being used? (Not full version)
3. Are correct pins assigned in UCF file?
   - P126 = vga_hsync
   - P131 = vga_vsync
   - P133/P137/P139 = RGB
4. Is VGA cable connected to K4 connector?
5. Does monitor support 640×480@60Hz?

**Don't Suggest**:
- Changing DCM settings (already verified working)
- Changing VGA timing constants (match VESA standard)
- Using different pixel clock (must be 25 MHz)

### "Keyboard not working"
**Check List**:
1. Is PS/2 cable connected to K2 connector (pins P43/P44)?
2. Are only uppercase A-Z keys being pressed? (Others not supported)
3. Is code using `key_valid` signal to detect new keys?
4. Check `ps2_keyboard_20mhz.vhd` is included in project

**Debug Method**:
```vhdl
-- Output ASCII code to LEDs for debugging
debug_leds <= key_ascii;
```

### "Want to add feature X"
**Response Strategy**:
1. **First**: Check if it breaks VGA timing (anything touching clocks/timing)
2. **Test**: Use `fpga2_standalone_working.vhd` for rapid iteration
3. **Incremental**: Add feature, test, commit before next feature
4. **Document**: Update relevant .md file (README, ARCHITECTURE, or DEVELOPMENT_NOTES)

### "Getting compilation errors"
**Common Causes**:
1. **Output port reading**: Add internal signal (see Pitfall #1)
2. **Type mismatch**: Check std_logic vs unsigned conversions
3. **Missing files**: Ensure all dependencies added to project
4. **Wrong device**: Must be Spartan-6 XC6SLX9-2TQG144

### "Want to test without FPGA1" / "Don't have second FPGA"
**Solution**: Use `fpga2_standalone_working.vhd`
- This is exactly what it's for!
- Test VGA + keyboard independently
- Faster development cycle (only recompile one FPGA)

### "Moving to different computer"
**Required**:
1. Xilinx ISE 14.7 installed
2. Clone repo: `git clone https://github.com/tachhh/fpga-wordle.git`
3. Start with `fpga2_standalone_working.vhd` to verify setup works
4. Read README.md → ARCHITECTURE.md → this file

---

## 🎓 Teaching Moments (For AI Assistant)

### When Explaining VGA
**Good**: "VGA requires precise 25 MHz pixel clock. We use DCM to multiply 20 MHz to 50 MHz, then divide by 2."

**Bad**: "Just change the clock frequency." (User needs to understand WHY)

### When Fixing Bugs
**Good**: Explain the problem, show solution, indicate where else it might occur

**Bad**: Just give fixed code without explanation

### When Suggesting Changes
**Good**: "This change requires recompiling and reflashing the FPGA. Test on `fpga2_standalone_working.vhd` first."

**Bad**: "Just modify `fpga2_top_3bit_rgb_Version2.vhd`." (Full version not yet tested)

---

## 📚 Reference Documents

**For Quick Start**: `README.md`
**For Technical Details**: `ARCHITECTURE.md`
**For Problem Solving**: `DEVELOPMENT_NOTES.md`
**For AI Context**: This file (`.github/copilot-instructions.md`)

---

## ✅ Before Modifying Code

**Checklist**:
1. [ ] Understand which FPGA the change affects (FPGA1 or FPGA2)?
2. [ ] Know if change impacts clock/timing (if yes, be VERY careful)
3. [ ] Check if similar issue fixed before (search DEVELOPMENT_NOTES.md)
4. [ ] Use standalone test file for FPGA2 changes
5. [ ] Test incrementally (one change at a time)
6. [ ] Document fix if it solves a bug

---

## 🎯 Current Priorities (November 2025)

1. **Test keyboard input** on `fpga2_standalone_working.vhd` with physical PS/2 keyboard
2. **Verify full FPGA1** compilation and flashing
3. **Test serial communication** between FPGA1 and FPGA2
4. **Integrate full system** (`fpga2_top_3bit_rgb_Version2.vhd` with serial)
5. **Play actual Wordle game** to validate complete functionality

---

## 💡 AI Assistant Best Practices

1. **Always check** current status (what's working, what's not)
2. **Read error messages** carefully - often indicate exact problem
3. **Use standalone test files** for rapid development
4. **Don't break** what's already working (DCM, VGA timing)
5. **Explain WHY** not just WHAT when fixing issues
6. **Reference** specific files and line numbers when helping
7. **Test incrementally** - small changes are easier to debug
8. **Document** bug fixes in DEVELOPMENT_NOTES.md

---

**Last Updated**: November 2025

**Status**: VGA display working ✅ | Display renderer working ✅ | Awaiting keyboard/serial testing ⏳
