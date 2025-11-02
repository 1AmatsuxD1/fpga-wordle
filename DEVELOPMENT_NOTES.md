# Development Notes - FPGA Wordle

Development history, problems encountered, solutions applied, and lessons learned.

## Table of Contents
1. [Development Timeline](#development-timeline)
2. [Major Problems & Solutions](#major-problems--solutions)
3. [VHDL Common Pitfalls](#vhdl-common-pitfalls)
4. [VGA Debugging Guide](#vga-debugging-guide)
5. [Testing Strategy](#testing-strategy)
6. [Lessons Learned](#lessons-learned)

---

## Development Timeline

### Phase 1: Initial Compilation (Fixed VHDL Errors)
**Goal**: Get all VHDL files to compile without errors

**Problems Fixed**:
1. **word_rom_20mhz.vhd**: Incomplete hex literals
   - Had 36 words instead of 40
   - Some hex values were not 40 bits (10 hex digits)
   - **Solution**: Added 4 more words, ensured all values are exactly `x"0123456789"` format

2. **vga_controller_20mhz.vhd**: Signal name conflicts
   - Constants named `H_SYNC` and `V_SYNC` conflicted with output ports
   - **Solution**: Renamed to `H_SYNC_WIDTH` and `V_SYNC_WIDTH`
   
3. **vga_controller_20mhz.vhd**: Cannot read output ports
   - VHDL output ports are write-only
   - Trying to read `h_sync` and `v_sync` in process caused errors
   - **Solution**: Created internal signals `h_sync_i` and `v_sync_i`, assigned to outputs

4. **fpga1_top_serial.vhd**: Cannot read output port `result_valid`
   - Same issue as VGA controller
   - **Solution**: Internal signal `result_valid_i`, assigned to output

5. **display_renderer_3bit_rgb_Version2.vhd**: Typo in constant name
   - `COLOR_BORDERS` had extra 'S'
   - **Solution**: Changed to `COLOR_BORDER`

6. **Constraints files**: Unused debug LEDs
   - LEDs L1-L7 not connected, caused warnings
   - **Solution**: Commented out unused LED constraints

**Result**: ✅ All files compile successfully

---

### Phase 2: VGA Display Issues (The Big Debug)
**Goal**: Get VGA monitor to display something

**Problem**: VGA monitor showed **no signal** (black screen)

**Initial Diagnosis**:
- Compiled without errors ✓
- Flashed to FPGA successfully ✓
- VGA cable connected ✓
- But monitor said "No Signal"

**Root Cause Analysis**:
The VGA controller was generating pixel data but missing **critical timing signals**:
1. No H-sync/V-sync pulses → monitor couldn't synchronize
2. Wrong pixel clock frequency (10 MHz instead of 25 MHz)
3. Missing DCM clock generator

**Why Timing Matters**:
VGA is a **strictly timed protocol**. The monitor expects:
- Exactly 25.175 MHz pixel clock (we use 25.000 MHz, close enough)
- Precise sync pulses at specific intervals
- Negative polarity (active LOW) for 640×480@60Hz

Without proper timing, the monitor literally cannot understand the signal.

**Solution Process**:

#### Step 1: Create Simple Test Files
Created progressively complex test files:
1. `vga_ultra_simple.vhd`: Just outputs solid colors (no timing)
2. `vga_test_basic.vhd`: Basic timing with simple clock divider
3. `vga_test_dcm.vhd`: Added DCM for clock generation
4. `vga_test_full.vhd`: Complete timing + DCM + test pattern

#### Step 2: Implement Clock Generator
**File**: `clock_generator.vhd`

Problem: 20 MHz ÷ 2 = 10 MHz (wrong for VGA)

Solution: Use DCM_SP to multiply frequency:
```vhdl
20 MHz × (5/2) = 50 MHz → ÷2 → 25 MHz ✓
```

**Critical Setting**: `STARTUP_WAIT => TRUE`
- Without this, DCM might not lock reliably on power-up
- Symptoms: Intermittent failures, works sometimes but not others
- With `STARTUP_WAIT`: Reliable every time

#### Step 3: Fix Sync Polarity
Initially used positive sync (active HIGH), but 640×480@60Hz requires **negative sync**.

**Wrong**:
```vhdl
h_sync <= '1' when (h_counter >= H_SYNC_START) else '0';
```

**Correct**:
```vhdl
h_sync <= '0' when (h_counter >= H_SYNC_START and h_counter < H_SYNC_END) else '1';
```

#### Step 4: Verify with Test Pattern
Created `vga_test_full.vhd` with color bars:
- Red bar: pixels 0-212
- Green bar: pixels 213-425
- Blue bar: pixels 426-639

**Test Result**: ✅ Color bars displayed correctly!

This confirmed:
- Clock generation works (DCM locked, LED L0 ON)
- VGA timing correct (monitor synced)
- RGB outputs functional (colors visible)

---

### Phase 3: Integrate Display Renderer
**Goal**: Show actual Wordle grid with letters

**Challenges**:
1. **Data Structure Conversion**
   - Game grid stored as VHDL record type (structured)
   - Display renderer needs std_logic_vector (flat)
   - **Solution**: Flattening process (see ARCHITECTURE.md)

2. **Signal Declarations**
   - Forgot to declare `rst_i` signal
   - **Solution**: Added `signal rst_i : std_logic;` and `rst_i <= rst or not dcm_locked;`

3. **Warnings About Unused Bits**
   - `game_grid_flat(1079 downto 330)` never assigned
   - Only 330 bits used (30 cells × 11 bits)
   - **Solution**: Initialize with `game_grid_flat <= (others => '0');` before packing data

**Test Strategy**:
Created `fpga2_standalone_working.vhd` to test without FPGA1:
- Keyboard input handler
- Test color pattern on Enter key
- Allows testing VGA + keyboard independently

**Hardcoded Test Data** (for validation):
Temporarily replaced keyboard handler with pre-filled grid:
- Row 0: "HELLO" (all green)
- Row 1: "WORLD" (all yellow)
- Row 2: "FPGAS" (all magenta)
- Row 3: "TE___" (partial, no color)
- Row 4: "DEBUG" (mixed colors)

**Result**: ✅ Letters and colors display correctly!

---

## Major Problems & Solutions

### Problem: DCM Not Locking
**Symptoms**: LED L0 stays OFF, VGA shows no signal

**Possible Causes**:
1. **Missing `STARTUP_WAIT => TRUE`**
   - DCM starts before clock is stable
   - Solution: Add `STARTUP_WAIT => TRUE` to generic map

2. **Wrong input clock frequency**
   - DCM expects 20 MHz but receiving something else
   - Solution: Verify oscillator on pin P54, measure with scope if available

3. **Incorrect CLKIN_PERIOD**
   - Must match actual input clock
   - For 20 MHz: `CLKIN_PERIOD => 50.0` (50ns period)

4. **Power supply issues**
   - Insufficient current to FPGA
   - Solution: Use quality USB cable, try different USB port

**Debug Steps**:
```vhdl
-- Add DCM lock indicator to LED
led_locked <= dcm_locked;  -- Connect to pin P82 (L0)
```
- LED ON: DCM working ✓
- LED OFF: DCM problem, check settings

---

### Problem: VGA Flickering/Unstable
**Symptoms**: Image flickers, monitor loses sync intermittently

**Causes & Solutions**:
1. **Timing Violations**
   - Logic too slow for 25 MHz pixel clock
   - Solution: Simplify combinational logic, add pipeline stages

2. **Floating Inputs**
   - Unused pins picking up noise
   - Solution: Add pull-ups/downs in constraints file

3. **Power Supply Noise**
   - Decoupling capacitors insufficient
   - Solution: Hardware issue, use better power supply

4. **Clock Jitter**
   - DCM not properly locked
   - Solution: Check LOCKED signal, ensure `CLK_FEEDBACK => "1X"` for DCM_SP

---

### Problem: Wrong Colors Displayed
**Symptoms**: Colors are inverted, wrong, or random

**Causes & Solutions**:
1. **Bit Order Mismatch**
   - RGB vs BGR pin assignment
   - Solution: Verify `vga_r` = red, `vga_g` = green, `vga_b` = blue in UCF

2. **Color Encoding Error**
   - Expected binary value doesn't match hardware
   - Example: Green should be `"010"` but displayed as yellow
   - Solution: Check color constant definitions

3. **Active HIGH vs LOW**
   - Some VGA monitors use inverted logic
   - Solution: Try inverting RGB signals: `vga_r <= not rgb_signal(2);`

4. **Timing Issue**
   - RGB changes during blanking period
   - Solution: Only output color when `video_on='1'`, else output black

---

### Problem: Keyboard Not Responding
**Symptoms**: Typing keys does nothing

**Causes & Solutions**:
1. **PS/2 Cable Not Connected**
   - Most obvious, check first
   - Solution: Verify physical connection to K2 connector

2. **Wrong Pin Assignment**
   - ps2_clk/ps2_data swapped
   - Solution: Check UCF file, P43=clock, P44=data

3. **Pull-up Resistors Missing**
   - PS/2 protocol requires pull-ups (keyboard provides open-drain)
   - Solution: Check if board has built-in pull-ups, add external if needed

4. **Clock Sampling Issues**
   - Reading PS/2 clock too fast
   - Solution: Add debouncing/edge detection logic

5. **Scancode Mapping Incomplete**
   - Some keys not mapped to ASCII
   - Solution: Check `ps2_keyboard_20mhz.vhd` scancode table

**Debug Method**:
```vhdl
-- Output raw scancode to LEDs for debugging
debug_leds <= scancode(7 downto 0);
```

---

## VHDL Common Pitfalls

### 1. Output Ports Are Write-Only
❌ **Wrong**:
```vhdl
signal_out <= some_logic;
if signal_out = '1' then  -- ERROR: Can't read output port!
```

✅ **Correct**:
```vhdl
signal signal_internal : std_logic;
signal_internal <= some_logic;
signal_out <= signal_internal;  -- Assign to output
if signal_internal = '1' then   -- Read from internal signal
```

### 2. Sensitivity List Must Be Complete
❌ **Wrong** (causes simulation/synthesis mismatch):
```vhdl
process(clk)  -- Missing reset and other inputs
begin
    if rst = '1' then
        counter <= 0;
    elsif rising_edge(clk) then
        counter <= counter + 1;
    end if;
end process;
```

✅ **Correct**:
```vhdl
process(clk, rst)  -- Include all signals read in process
```

### 3. Variables vs Signals
**Variables**: Updated immediately (like software)
**Signals**: Updated at end of process (hardware registers)

Use **signals** for values that persist between clock cycles.
Use **variables** for temporary calculations within a process.

### 4. Indexed Arrays Must Have Consistent Types
❌ **Wrong**:
```vhdl
signal index : integer;
data <= array(index);  -- May not synthesize!
```

✅ **Correct**:
```vhdl
signal index : integer;
data <= array(to_integer(unsigned(index_vector)));
```

### 5. For Loops Are Unrolled (Not Sequential)
```vhdl
for i in 0 to 7 loop
    output(i) <= input(i) and mask(i);
end loop;
```
This creates **8 parallel AND gates**, not a sequential loop!

---

## VGA Debugging Guide

### Step-by-Step Diagnosis

#### 1. Check DCM Lock
```vhdl
led_locked <= dcm_locked;
```
- LED OFF → DCM problem (see "Problem: DCM Not Locking" above)
- LED ON → DCM good, continue

#### 2. Verify Pixel Clock Frequency
Ideal: Oscilloscope measurement
- Expect: 25 MHz (40ns period)
- Tolerance: ±0.5 MHz acceptable

Without scope:
- Check synthesis report for DCM settings
- Verify CLKFX_MULTIPLY and CLKFX_DIVIDE values

#### 3. Test with Solid Color
Simplify display renderer to output single color:
```vhdl
rgb <= "111";  -- White
```
- No display → timing issue
- Display OK → renderer issue

#### 4. Test with Color Bars
```vhdl
if pixel_x < 213 then
    rgb <= "100";  -- Red
elsif pixel_x < 426 then
    rgb <= "010";  -- Green
else
    rgb <= "001";  -- Blue
end if;
```
- Vertical bars → H-sync working
- Horizontal bars → V-sync working

#### 5. Verify Sync Signals with Scope
Measure on pins P126 (hsync) and P131 (vsync):
- **H-sync**: 31.5 kHz, negative pulse width 3.8 μs
- **V-sync**: 60 Hz, negative pulse width 64 μs

Wrong polarity: signal inverted, change `'0'` ↔ `'1'` in controller

#### 6. Check Pin Assignments
Verify UCF file matches actual hardware connections:
```
NET "vga_hsync" LOC = "P126";
NET "vga_vsync" LOC = "P131";
NET "vga_r" LOC = "P133";
NET "vga_g" LOC = "P137";
NET "vga_b" LOC = "P139";
```

Try different VGA cable/monitor if possible.

---

## Testing Strategy

### Bottom-Up Approach
1. **Clock Generation**: Test DCM in isolation → verify lock LED
2. **VGA Timing**: Test with simple color bars → verify sync
3. **Character ROM**: Test single character display → verify font
4. **Display Renderer**: Test with hardcoded grid → verify layout
5. **Keyboard Input**: Test with LED output → verify scancodes
6. **Full Integration**: Combine all components → test gameplay

### Incremental Testing
Don't test everything at once! Add one feature at a time:
1. Blank screen → Color bars
2. Color bars → Single character
3. Single character → Full grid
4. Empty grid → Hardcoded letters
5. Hardcoded → Keyboard input
6. Keyboard only → + Serial communication

If something breaks, you know which change caused it.

### Use Standalone Test Files
Created `fpga2_standalone_working.vhd` to test FPGA2 without FPGA1.

**Benefits**:
- Faster iteration (only recompile one FPGA)
- Isolate problems (keyboard issue vs serial issue?)
- Easier debugging (fewer variables)

**When to Use**:
- Developing new display features
- Testing keyboard input changes
- Verifying VGA timing fixes

**When to Integrate**:
- After standalone test passes
- Need to test serial communication
- Ready for full system validation

---

## Lessons Learned

### 1. VGA Timing Is Non-Negotiable
You can't "approximately" meet VGA timing. It's either correct or it doesn't work.
- Use exact 25.000 MHz (or 25.175 MHz for strict VESA compliance)
- Match sync pulse widths precisely
- Use correct polarity (negative for 640×480@60Hz)

### 2. DCM STARTUP_WAIT Is Critical
Without `STARTUP_WAIT => TRUE`, the DCM works *sometimes* but fails unpredictably.
Always include this for reliable operation.

### 3. Test Early, Test Often
The VGA debugging took hours because we tried to test the complete system.
Creating simple test files (vga_test_basic → vga_test_full) found the problem quickly.

### 4. VHDL Output Ports Are Annoying
This gotcha cost 30 minutes of debugging:
- Can't read output ports
- Must use internal signals
- Easy to forget when copying code

**Solution**: Always use internal signals, assign to outputs at end.

### 5. Constraints Matter
Commenting out unused LED constraints eliminated dozens of warnings.
Clean synthesis reports make real issues easier to spot.

### 6. Document While Developing
These notes written during development, not after.
Saves time later when you forget why something was done.

### 7. Version Control Is Essential
Git repository let us:
- Revert bad changes (tried different DCM settings)
- Track what worked (vga_test_full.vhd became reference)
- Share project (moved between computers)

### 8. Hardware Debugging Is Hard
Unlike software:
- Can't add `printf()` statements
- Need oscilloscope for signal measurement
- LEDs are your best friend for debugging

**Pro tip**: Reserve LED outputs for debug signals during development.

---

## Common Error Messages & Fixes

### "Signal is never assigned"
**Cause**: Signal declared but not driven
**Fix**: Add assignment or remove unused signal

### "Multiple drivers"
**Cause**: Signal assigned in multiple processes
**Fix**: Assign in only one process, or use resolved types

### "Timing constraint not met"
**Cause**: Logic path too slow for clock frequency
**Fix**: 
- Simplify logic
- Add pipeline stages
- Reduce clock frequency (if possible)
- Check for combinational loops

### "DCM_SP not found"
**Cause**: Wrong FPGA family selected
**Fix**: Project settings → Device → Spartan-6 XC6SLX9

### "Port <name> not connected"
**Cause**: Component instantiation missing port
**Fix**: Add missing port to port map (or use `=> open` if intentional)

---

## Future Development Notes

### If Adding New Features:

**More Words**:
- Edit `word_rom_20mhz.vhd`
- Increase address width if >64 words (currently 6 bits = 64 max)
- Update ROM initialization with new words

**Game Status Display**:
- Modify `display_renderer_3bit_rgb_Version2.vhd`
- Add text rendering for "WIN!", "GAME OVER", etc.
- Use `char_rom` for letters

**Audio Feedback**:
- Add PWM module for buzzer
- Connect to available GPIO pin
- Trigger on key press, win, loss events

**Automatic Restart**:
- Add timer in game state machine
- Detect win/loss condition
- Reset `game_grid` after 5 seconds

---

**Status**: ✅ VGA working | ✅ Display renderer working | ⏳ Full system integration pending

**Last Updated**: November 2025
