# FPGA Wordle Game# FPGA Wordle Game



A hardware implementation of the popular Wordle word-guessing game using dual Spartan-6 FPGA boards with VGA display output and PS/2 keyboard input.โปรเจกต์เกม Wordle บน FPGA 2 บอร์ด ใช้ VHDL และ Xilinx ISE



## 🎯 Project Overview## สถาปัตยกรรม



This project implements a fully functional Wordle game on FPGA hardware, featuring:### FPGA Board #1: Game Logic

- **Dual-FPGA architecture**: Separate boards for game logic and display/input- ตรวจสอบคำทาย (Word Comparator)

- **VGA output**: 640×480 @ 60Hz with 3-bit RGB color (8 colors)- เก็บคำตอบ (Word ROM)

- **PS/2 keyboard input**: Type guesses using a standard keyboard- จัดการสถานะเกม (FSM)

- **Serial communication**: Game state transferred between FPGAs at 115200 baud- Serial Communication Transmitter

- **On-board word database**: 40 five-letter words stored in ROM

**ไฟล์หลัก:**

## 🛠️ Hardware Requirements- `fpga1_logic/fpga1_top_serial.vhd` - Top-level entity

- `fpga1_logic/word_comparator_20mhz.vhd` - เปรียบเทียบคำ

### Required Components- `fpga1_logic/word_rom_20mhz.vhd` - เก็บคำตอบ 16 คำ

- **2× Surveyor SV6 boards** (Spartan-6 XC6SLX9 FPGA)- `fpga1_logic/fpga1_constraints_final.ucf` - Pin constraints

- **VGA monitor** (supports 640×480 @ 60Hz)

- **PS/2 keyboard**### FPGA Board #2: Display & Input

- **VGA cable** (connected to FPGA2)- VGA Display (3-bit RGB, 8 สี)

- **PS/2 cable or adapter** (connected to FPGA2)- PS/2 Keyboard Input

- **Serial cable** (connects FPGA1 ↔ FPGA2)- Display Renderer

- **USB cables** for programming both FPGAs- Serial Communication Receiver



### Board Specifications**ไฟล์หลัก:**

- **FPGA**: Spartan-6 XC6SLX9-2TQG144- `fpga2_vga/fpga2_top_3bit_rgb_Version2.vhd` - Top-level entity

- **Clock**: 20 MHz on-board oscillator- `fpga2_vga/display_renderer_3bit_rgb_Version2.vhd` - แสดงผลตาราง

- **I/O**: Standard 2.54mm headers- `fpga2_vga/vga_controller_20mhz.vhd` - VGA timing

- **Programming**: USB JTAG interface- `fpga2_vga/ps2_keyboard_20mhz.vhd` - Keyboard input

- `fpga2_vga/char_rom.vhd` - Character ROM

## 🏗️ System Architecture- `fpga2_vga/fpga2_constraints_3bit_rgb_Version2.ucf` - Pin constraints



```### Serial Communication

┌─────────────────────────────────────────────────────────┐- **FPGA2 → FPGA1**: ส่งคำทาย (40 bits = 5 letters)

│                     FPGA WORDLE SYSTEM                  │- **FPGA1 → FPGA2**: ส่งผลลัพธ์ (15 bits = 5×3 bits สี)

└─────────────────────────────────────────────────────────┘

**ไฟล์ที่ใช้ร่วมกัน:**

    ┌──────────────────┐         Serial          ┌──────────────────┐- `serial_receiver.vhd` - รับข้อมูล serial

    │     FPGA 1       │◄──────115200 baud──────►│     FPGA 2       │- `serial_transmitter.vhd` - ส่งข้อมูล serial

    │   Game Logic     │                         │  Display/Input   │- `serial_communication_tb.vhd` - Testbench

    └──────────────────┘                         └──────────────────┘

            │                                              │## สี (3-bit RGB)

            │                                              ├─► VGA Monitor- 🟩 **เขียว (010)**: ตัวอักษรถูกต้องและตำแหน่งถูก

            │                                              │   (640×480@60Hz)- 🟨 **เหลือง (110)**: ตัวอักษรถูกต้องแต่ตำแหน่งผิด

            ├─► Word ROM (40 words)                       │- 🟣 **ม่วง (101)**: ตัวอักษรไม่มีในคำตอบ (แทนสีเทา)

            ├─► Word Comparator                           └─► PS/2 Keyboard- ⚪ **ขาว (111)**: ขอบและตัวอักษร

            └─► Serial Transmitter                             (A-Z input)- ⚫ **ดำ (000)**: พื้นหลัง



Clock: 20 MHz (input) → DCM → 50 MHz → 25 MHz (VGA pixel clock)## Clock

```- ทั้ง 2 FPGA ใช้ Clock 20 MHz

- Serial Clock: 2.5 MHz (สำหรับการสื่อสาร)

### FPGA 1: Game Logic Board- VGA Pixel Clock: 10 MHz (divider จาก 20 MHz)

- **Purpose**: Manages game state and word checking

- **Components**:## การใช้งาน

  - `word_rom_20mhz.vhd`: 40-word database1. เปิดโปรเจกต์ด้วย Xilinx ISE

  - `word_comparator_20mhz.vhd`: Checks guesses and assigns colors2. Synthesize แต่ละ FPGA แยกกัน

  - `serial_transmitter.vhd`: Sends results to FPGA23. Program ลง FPGA board

- **Top-level**: `fpga1_top_serial.vhd`4. เชื่อมต่อสาย serial ระหว่าง 2 บอร์ด

- **Constraints**: `fpga1_constraints_final.ucf`5. เล่นเกม Wordle!



### FPGA 2: Display/Input Board## การพัฒนา

- **Purpose**: Handles VGA output and keyboard input- **ภาษา**: VHDL

- **Components**:- **เครื่องมือ**: Xilinx ISE

  - `clock_generator.vhd`: DCM-based 25 MHz pixel clock generator- **FPGA**: Spartan-3E หรือ Spartan-6

  - `vga_controller_20mhz.vhd`: VGA timing (H-sync, V-sync)

  - `display_renderer_3bit_rgb_Version2.vhd`: Renders 6×5 game grid## License

  - `char_rom.vhd`: 8×8 pixel font for A-Z charactersMIT License

  - `ps2_keyboard_20mhz.vhd`: Keyboard input handler
  - `serial_receiver.vhd`: Receives game state from FPGA1
- **Top-level**: `fpga2_top_3bit_rgb_Version2.vhd`
- **Constraints**: `fpga2_constraints_3bit_rgb_Version2.ucf`
- **Standalone test**: `fpga2_standalone_working.vhd` (VGA + keyboard only)

## 📁 Project Structure

```
wordle/
├── README.md                          # This file
├── ARCHITECTURE.md                    # Detailed system architecture
├── DEVELOPMENT_NOTES.md               # Development history and troubleshooting
├── .github/
│   └── copilot-instructions.md        # AI assistant guidelines
├── .gitignore                         # Xilinx ISE build artifacts
│
├── fpga1_logic/                       # FPGA 1: Game Logic
│   ├── fpga1_top_serial.vhd          # Top-level entity
│   ├── fpga1_constraints_final.ucf   # Pin assignments
│   ├── word_rom_20mhz.vhd            # 40-word database
│   └── word_comparator_20mhz.vhd     # Word checking logic
│
├── fpga2_vga/                         # FPGA 2: Display/Input
│   ├── fpga2_top_3bit_rgb_Version2.vhd           # Top-level entity (full system)
│   ├── fpga2_constraints_3bit_rgb_Version2.ucf   # Pin assignments
│   ├── fpga2_standalone_working.vhd   # Standalone test (no serial)
│   ├── fpga2_standalone_working.ucf   # Standalone constraints
│   ├── clock_generator.vhd            # DCM: 20MHz → 25MHz
│   ├── vga_controller_20mhz.vhd       # VGA timing generator
│   ├── display_renderer_3bit_rgb_Version2.vhd  # Game grid renderer
│   ├── char_rom.vhd                   # Character font ROM
│   ├── ps2_keyboard_20mhz.vhd         # Keyboard input
│   └── archive/                       # Old test files (not used)
│       ├── vga_test_*.vhd
│       └── fpga2_standalone_test.vhd
│
├── serial_communication_tb.vhd        # Serial communication testbench
├── serial_receiver.vhd                # Serial RX (shared)
└── serial_transmitter.vhd             # Serial TX (shared)
```

## 🚀 Quick Start Guide

### 1. Setup Development Environment
- Install **Xilinx ISE 14.7** (Windows/Linux)
- Install **iMPACT** programmer for USB JTAG
- Clone this repository:
  ```bash
  git clone https://github.com/tachhh/fpga-wordle.git
  cd fpga-wordle
  ```

### 2. Build FPGA1 (Game Logic)
1. Open Xilinx ISE
2. Create new project: `fpga1_logic/fpga1_wordle`
3. Add files:
   - `fpga1_top_serial.vhd`
   - `word_rom_20mhz.vhd`
   - `word_comparator_20mhz.vhd`
   - `serial_transmitter.vhd`
   - `fpga1_constraints_final.ucf`
4. Set top-level entity: `fpga1_top_serial`
5. Synthesize → Implement → Generate bitstream
6. Flash to FPGA1 board via iMPACT

### 3. Build FPGA2 (Display/Input)
1. Open Xilinx ISE
2. Create new project: `fpga2_vga/fpga2_vga`
3. Add files:
   - `fpga2_top_3bit_rgb_Version2.vhd`
   - `clock_generator.vhd`
   - `vga_controller_20mhz.vhd`
   - `display_renderer_3bit_rgb_Version2.vhd`
   - `char_rom.vhd`
   - `ps2_keyboard_20mhz.vhd`
   - `serial_receiver.vhd`
   - `fpga2_constraints_3bit_rgb_Version2.ucf`
4. Set top-level entity: `fpga2_top_3bit_rgb_Version2`
5. Synthesize → Implement → Generate bitstream
6. Flash to FPGA2 board via iMPACT

### 4. Hardware Connections
1. Connect VGA cable: FPGA2 K4 connector → VGA monitor
2. Connect PS/2 keyboard: FPGA2 K2 connector → PS/2 keyboard
3. Connect serial cable: FPGA1 TX pin → FPGA2 RX pin (with ground)
4. Power on both boards
5. Turn on VGA monitor

### 5. Play Wordle!
- **Type letters A-Z** on keyboard (uppercase only)
- **Backspace**: Delete last letter
- **Enter**: Submit 5-letter guess
- **Colors**:
  - 🟩 **Green**: Correct letter, correct position
  - 🟨 **Yellow**: Correct letter, wrong position
  - 🟪 **Magenta**: Letter not in word (using magenta instead of gray for 3-bit RGB)
- **Win**: Guess the word in 6 tries or less!

## 🧪 Testing

### Standalone FPGA2 Test (No FPGA1 Required)
Test VGA display and keyboard without connecting FPGA1:

1. Build `fpga2_standalone_working.vhd` instead of `fpga2_top_3bit_rgb_Version2.vhd`
2. Use `fpga2_standalone_working.ucf` constraints
3. Flash to FPGA2
4. Should see 6×5 grid on VGA monitor
5. Type letters to fill grid
6. Press Enter to see test color pattern (green-yellow-magenta-yellow-green)

### Debug Indicators
- **LED L0** (FPGA2): DCM locked indicator (should be ON)
- If LED is OFF: Clock generation failed, check oscillator

## 🎨 VGA Display Details

### Resolution & Timing
- **Resolution**: 640×480 pixels @ 60Hz
- **Pixel clock**: 25 MHz (generated from 20 MHz via DCM)
- **Sync polarity**: Negative (active LOW)
- **H-Sync**: 800 total cycles (640 visible, 96 sync pulse)
- **V-Sync**: 525 total lines (480 visible, 2 sync pulse)

### Color Encoding (3-bit RGB)
| Color   | RGB | Hex | Usage                    |
|---------|-----|-----|--------------------------|
| Black   | 000 | 0   | Background               |
| Red     | 100 | 4   | (unused)                 |
| Green   | 010 | 2   | Correct position         |
| Yellow  | 110 | 6   | Wrong position           |
| Blue    | 001 | 1   | (unused)                 |
| Magenta | 101 | 5   | Not in word (gray)       |
| Cyan    | 011 | 3   | (unused)                 |
| White   | 111 | 7   | Text/borders             |

### Game Grid Layout
- **Grid size**: 6 rows × 5 columns
- **Cell size**: 60×60 pixels (with 2px border)
- **Character size**: 40×40 pixels (8×8 font scaled 5×)
- **Total grid area**: 300×360 pixels
- **Position**: Centered on screen

## 📝 Pin Assignments

### FPGA1 Pins (Game Logic)
| Signal | Pin | Description           |
|--------|-----|-----------------------|
| clk    | P54 | 20 MHz clock input    |
| rst    | P60 | Reset button          |
| rx     | P50 | Serial receive (from FPGA2) |
| tx     | P51 | Serial transmit (to FPGA2)  |

### FPGA2 Pins (Display/Input)
| Signal    | Pin  | Description                |
|-----------|------|----------------------------|
| clk       | P54  | 20 MHz clock input         |
| rst       | P60  | Reset button               |
| vga_hsync | P126 | VGA horizontal sync (K4)   |
| vga_vsync | P131 | VGA vertical sync (K4)     |
| vga_r     | P133 | VGA red output (K4)        |
| vga_g     | P137 | VGA green output (K4)      |
| vga_b     | P139 | VGA blue output (K4)       |
| ps2_clk   | P43  | PS/2 keyboard clock (K2)   |
| ps2_data  | P44  | PS/2 keyboard data (K2)    |
| rx        | P50  | Serial receive (from FPGA1)|
| tx        | P51  | Serial transmit (to FPGA1) |
| led_locked| P82  | DCM lock LED (L0)          |

## 🔧 Troubleshooting

### VGA Display Issues
- **No display**: Check DCM lock LED (L0). Should be ON.
- **Flickering**: Ensure 20 MHz oscillator is stable
- **Wrong colors**: Verify 3-bit RGB pin connections (P133/P137/P139)
- **Timing issues**: Confirm pixel clock is exactly 25 MHz

### Keyboard Issues
- **No response**: Check PS/2 cable connection (clock + data pins)
- **Wrong characters**: Only uppercase A-Z supported
- **Stuck keys**: Power cycle keyboard

### Serial Communication Issues
- **No color feedback**: Check serial connection (TX1→RX2, GND common)
- **Corrupt data**: Verify baud rate is 115200 on both FPGAs
- **Timeout**: Check FPGA1 is running and transmitting

### Compilation Errors
- **DCM_SP not found**: Ensure Spartan-6 device selected in project
- **Port mismatch**: Check entity declarations match component instantiations
- **Timing not met**: Reduce clock constraints or optimize logic

## 📚 Additional Resources

- **ARCHITECTURE.md**: Detailed technical documentation
- **DEVELOPMENT_NOTES.md**: Development history, known issues, solutions
- **.github/copilot-instructions.md**: Guidelines for AI assistants
- **Serial testbench**: `serial_communication_tb.vhd` (simulation only)

## 🤝 Contributing

This is a personal project, but suggestions and improvements are welcome!

## 📄 License

Educational project - free to use and modify.

## 👨‍💻 Author

Developed for FPGA digital design course using Surveyor SV6 boards.

---

**Status**: ✅ VGA display working | ⏳ Keyboard integration pending | ⏳ Full dual-FPGA system pending

**Last Updated**: November 2025
