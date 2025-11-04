# FPGA Wordle Game# FPGA Wordle Game# FPGA Wordle Game



โปรเจกต์เกม Wordle บน FPGA 2 บอร์ด ใช้ VHDL และ Xilinx ISE



## 🎯 Project OverviewA hardware implementation of the popular Wordle word-guessing game using dual Spartan-6 FPGA boards with VGA display output and PS/2 keyboard input.โปรเจกต์เกม Wordle บน FPGA 2 บอร์ด ใช้ VHDL และ Xilinx ISE



เกม Wordle ทำงานบน FPGA 2 บอร์ด แยกหน้าที่:

- **FPGA #1**: ตรวจสอบคำทายและเปรียบเทียบกับคำตอบ

- **FPGA #2**: แสดงผลบน VGA และรับ input จาก PS/2 keyboard## 🎯 Project Overview## สถาปัตยกรรม



**คุณสมบัติ:**

- VGA output: 640×480 @ 60Hz, 3-bit RGB (8 สี)

- PS/2 keyboard inputThis project implements a fully functional Wordle game on FPGA hardware, featuring:### FPGA Board #1: Game Logic

- Serial communication: 2.5 MHz synchronous protocol

- Word database: 16 คำเก็บใน ROM- **Dual-FPGA architecture**: Separate boards for game logic and display/input- ตรวจสอบคำทาย (Word Comparator)



---- **VGA output**: 640×480 @ 60Hz with 3-bit RGB color (8 colors)- เก็บคำตอบ (Word ROM)



## 📁 Project Structure- **PS/2 keyboard input**: Type guesses using a standard keyboard- จัดการสถานะเกม (FSM)



```- **Serial communication**: Game state transferred between FPGAs at 115200 baud- Serial Communication Transmitter

fpga-wordle/

├── fpga1_logic/              # FPGA #1: Game Logic- **On-board word database**: 40 five-letter words stored in ROM

│   ├── fpga1_top_serial.vhd

│   ├── word_comparator_20mhz.vhd**ไฟล์หลัก:**

│   ├── word_rom_20mhz.vhd

│   └── fpga1_constraints_final.ucf## 🛠️ Hardware Requirements- `fpga1_logic/fpga1_top_serial.vhd` - Top-level entity

│

├── fpga2_vga/                # FPGA #2: Display & Input- `fpga1_logic/word_comparator_20mhz.vhd` - เปรียบเทียบคำ

│   ├── fpga2_top_3bit_rgb_Version2.vhd

│   ├── display_renderer_3bit_rgb_Version2.vhd### Required Components- `fpga1_logic/word_rom_20mhz.vhd` - เก็บคำตอบ 16 คำ

│   ├── vga_controller_20mhz.vhd

│   ├── ps2_keyboard_20mhz.vhd- **2× Surveyor SV6 boards** (Spartan-6 XC6SLX9 FPGA)- `fpga1_logic/fpga1_constraints_final.ucf` - Pin constraints

│   ├── clock_generator.vhd

│   ├── char_rom.vhd- **VGA monitor** (supports 640×480 @ 60Hz)

│   ├── fpga2_constraints_3bit_rgb_Version2.ucf

│   └── archive/              # ไฟล์ทดสอบเก่า- **PS/2 keyboard**### FPGA Board #2: Display & Input

│

├── shared_modules/           # โมดูลที่ใช้ร่วมกัน- **VGA cable** (connected to FPGA2)- VGA Display (3-bit RGB, 8 สี)

│   ├── serial_transmitter.vhd

│   ├── serial_receiver.vhd- **PS/2 cable or adapter** (connected to FPGA2)- PS/2 Keyboard Input

│   └── README.md

│- **Serial cable** (connects FPGA1 ↔ FPGA2)- Display Renderer

├── archive/                  # ไฟล์ที่ไม่ได้ใช้แล้ว

│   ├── serial_transmitter_simple.vhd- **USB cables** for programming both FPGAs- Serial Communication Receiver

│   ├── serial_communication_tb.vhd

│   └── README.md

│

├── ARCHITECTURE.md           # สถาปัตยกรรมระบบ### Board Specifications**ไฟล์หลัก:**

├── CONNECTION_GUIDE.md       # คู่มือต่อสาย

├── CORRECT_WIRING.md         # การต่อสายที่ถูกต้อง- **FPGA**: Spartan-6 XC6SLX9-2TQG144- `fpga2_vga/fpga2_top_3bit_rgb_Version2.vhd` - Top-level entity

├── FINAL_CONFIG.md           # การตั้งค่าสุดท้าย

└── README.md                 # ไฟล์นี้- **Clock**: 20 MHz on-board oscillator- `fpga2_vga/display_renderer_3bit_rgb_Version2.vhd` - แสดงผลตาราง

```

- **I/O**: Standard 2.54mm headers- `fpga2_vga/vga_controller_20mhz.vhd` - VGA timing

---

- **Programming**: USB JTAG interface- `fpga2_vga/ps2_keyboard_20mhz.vhd` - Keyboard input

## 🛠️ Hardware Requirements

- `fpga2_vga/char_rom.vhd` - Character ROM

### Required Components

- **2× Spartan-6 XC6SLX9 FPGA boards** (144-pin TQFP)## 🏗️ System Architecture- `fpga2_vga/fpga2_constraints_3bit_rgb_Version2.ucf` - Pin constraints

- **VGA monitor** (640×480 @ 60Hz)

- **PS/2 keyboard**

- **8× jumper wires** (Female-to-Female, ~15cm)

- **2× USB cables** for programming```### Serial Communication



### Board Specifications┌─────────────────────────────────────────────────────────┐- **FPGA2 → FPGA1**: ส่งคำทาย (40 bits = 5 letters)

- **FPGA:** Xilinx Spartan-6 XC6SLX9-2TQG144C

- **Clock:** 20 MHz onboard oscillator│                     FPGA WORDLE SYSTEM                  │- **FPGA1 → FPGA2**: ส่งผลลัพธ์ (15 bits = 5×3 bits สี)

- **I/O:** 102 user I/O pins

- **Memory:** 576 Kb block RAM└─────────────────────────────────────────────────────────┘



---**ไฟล์ที่ใช้ร่วมกัน:**



## 🔌 Wiring Connections    ┌──────────────────┐         Serial          ┌──────────────────┐- `serial_receiver.vhd` - รับข้อมูล serial



### FPGA #1 ↔ FPGA #2 Serial Communication    │     FPGA 1       │◄──────115200 baud──────►│     FPGA 2       │- `serial_transmitter.vhd` - ส่งข้อมูล serial



**Pin-to-Pin Straight-Through Wiring:**    │   Game Logic     │                         │  Display/Input   │- `serial_communication_tb.vhd` - Testbench



| Signal | FPGA #2 Pin | ↔ | FPGA #1 Pin | Direction |    └──────────────────┘                         └──────────────────┘

|--------|-------------|---|-------------|-----------|

| serial_tx_data | P5 | ↔ | P5 | FPGA2 → FPGA1 |            │                                              │## สี (3-bit RGB)

| serial_tx_clk | P7 | ↔ | P7 | FPGA2 → FPGA1 |

| data_valid | P9 | ↔ | P9 | FPGA2 → FPGA1 |            │                                              ├─► VGA Monitor- 🟩 **เขียว (010)**: ตัวอักษรถูกต้องและตำแหน่งถูก

| serial_rx_data | P11 | ↔ | P11 | FPGA1 → FPGA2 |

| serial_rx_clk | P14 | ↔ | P14 | FPGA1 → FPGA2 |            │                                              │   (640×480@60Hz)- 🟨 **เหลือง (110)**: ตัวอักษรถูกต้องแต่ตำแหน่งผิด

| acknowledge | P16 | ↔ | P16 | FPGA1 → FPGA2 |

| result_valid | P21 | ↔ | P21 | FPGA1 → FPGA2 |            ├─► Word ROM (40 words)                       │- 🟣 **ม่วง (101)**: ตัวอักษรไม่มีในคำตอบ (แทนสีเทา)

| **GND** | **GND** | ↔ | **GND** | **Common Ground** |

            ├─► Word Comparator                           └─► PS/2 Keyboard- ⚪ **ขาว (111)**: ขอบและตัวอักษร

⚠️ **สำคัญ:** ต้องต่อ GND ระหว่าง 2 บอร์ด!

            └─► Serial Transmitter                             (A-Z input)- ⚫ **ดำ (000)**: พื้นหลัง

📄 รายละเอียดเพิ่มเติม: [CONNECTION_GUIDE.md](CONNECTION_GUIDE.md)



---

Clock: 20 MHz (input) → DCM → 50 MHz → 25 MHz (VGA pixel clock)## Clock

## 🚀 Getting Started

```- ทั้ง 2 FPGA ใช้ Clock 20 MHz

### Prerequisites

- **Xilinx ISE Design Suite 14.7** (or later)- Serial Clock: 2.5 MHz (สำหรับการสื่อสาร)

- **iMPACT** programmer tool

- **Git** (for cloning repository)### FPGA 1: Game Logic Board- VGA Pixel Clock: 10 MHz (divider จาก 20 MHz)



### Installation- **Purpose**: Manages game state and word checking



1. **Clone repository:**- **Components**:## การใช้งาน

```bash

git clone https://github.com/1AmatsuxD1/fpga-wordle.git  - `word_rom_20mhz.vhd`: 40-word database1. เปิดโปรเจกต์ด้วย Xilinx ISE

cd fpga-wordle

```  - `word_comparator_20mhz.vhd`: Checks guesses and assigns colors2. Synthesize แต่ละ FPGA แยกกัน



2. **Open ISE projects:**  - `serial_transmitter.vhd`: Sends results to FPGA23. Program ลง FPGA board

   - FPGA #1: Open `fpga1_logic/fpga1_top_serial.xise`

   - FPGA #2: Open `fpga2_vga/fpga2_top_3bit_rgb_Version2.xise`- **Top-level**: `fpga1_top_serial.vhd`4. เชื่อมต่อสาย serial ระหว่าง 2 บอร์ด



3. **Synthesize and Program:**- **Constraints**: `fpga1_constraints_final.ucf`5. เล่นเกม Wordle!



   **For both FPGAs:**

   - Double-click "Synthesize - XST"

   - Double-click "Implement Design"### FPGA 2: Display/Input Board## การพัฒนา

   - Double-click "Generate Programming File"

   - Upload `.bit` file using iMPACT- **Purpose**: Handles VGA output and keyboard input- **ภาษา**: VHDL



4. **Connect wiring** ตามตารางด้านบน- **Components**:- **เครื่องมือ**: Xilinx ISE



5. **Connect peripherals:**  - `clock_generator.vhd`: DCM-based 25 MHz pixel clock generator- **FPGA**: Spartan-3E หรือ Spartan-6

   - VGA monitor → FPGA #2

   - PS/2 keyboard → FPGA #2  - `vga_controller_20mhz.vhd`: VGA timing (H-sync, V-sync)



6. **Power on** และเริ่มเล่น!  - `display_renderer_3bit_rgb_Version2.vhd`: Renders 6×5 game grid## License



---  - `char_rom.vhd`: 8×8 pixel font for A-Z charactersMIT License



## 🎮 How to Play  - `ps2_keyboard_20mhz.vhd`: Keyboard input handler

  - `serial_receiver.vhd`: Receives game state from FPGA1

1. **พิมพ์คำทาย** (5 ตัวอักษร A-Z)- **Top-level**: `fpga2_top_3bit_rgb_Version2.vhd`

2. **กด Enter** เพื่อส่งคำทาย- **Constraints**: `fpga2_constraints_3bit_rgb_Version2.ucf`

3. **ดูสี** บนหน้าจอ:- **Standalone test**: `fpga2_standalone_working.vhd` (VGA + keyboard only)

   - 🟢 **เขียว** = ตัวอักษรถูกต้องและอยู่ตำแหน่งถูก

   - 🟡 **เหลือง** = ตัวอักษรมีในคำตอบแต่ตำแหน่งผิด## 📁 Project Structure

   - ⚫ **เทา (Magenta)** = ตัวอักษรไม่มีในคำตอบ

4. **เล่นต่อ** จนกว่าจะเดาถูกหรือครบ 6 ครั้ง```

wordle/

**ตัวอย่างคำในเกม:**├── README.md                          # This file

- APPLE, GRAPE, LEMON, PEACH, MANGO├── ARCHITECTURE.md                    # Detailed system architecture

- TIGER, EAGLE, MOUSE, HORSE, SNAKE├── DEVELOPMENT_NOTES.md               # Development history and troubleshooting

- และอื่นๆ อีก 6 คำ├── .github/

│   └── copilot-instructions.md        # AI assistant guidelines

---├── .gitignore                         # Xilinx ISE build artifacts

│

## 🎨 Display Features├── fpga1_logic/                       # FPGA 1: Game Logic

│   ├── fpga1_top_serial.vhd          # Top-level entity

- **หน้าจอ VGA:** 640×480 @ 60Hz│   ├── fpga1_constraints_final.ucf   # Pin assignments

- **สี:** 3-bit RGB (8 สี)│   ├── word_rom_20mhz.vhd            # 40-word database

- **Title:** "WORDLE" สีเขียวด้านบน│   └── word_comparator_20mhz.vhd     # Word checking logic

- **Grid:** 6×5 (6 แถว × 5 ตัวอักษร)│

- **Font:** 8×8 ASCII character ROM, scaled 4× → 32×32 pixels├── fpga2_vga/                         # FPGA 2: Display/Input

│   ├── fpga2_top_3bit_rgb_Version2.vhd           # Top-level entity (full system)

---│   ├── fpga2_constraints_3bit_rgb_Version2.ucf   # Pin assignments

│   ├── fpga2_standalone_working.vhd   # Standalone test (no serial)

## 🔧 Technical Details│   ├── fpga2_standalone_working.ucf   # Standalone constraints

│   ├── clock_generator.vhd            # DCM: 20MHz → 25MHz

### Clock Architecture│   ├── vga_controller_20mhz.vhd       # VGA timing generator

- **Main Clock:** 20 MHz (onboard oscillator)│   ├── display_renderer_3bit_rgb_Version2.vhd  # Game grid renderer

- **DCM Output:** 50 MHz│   ├── char_rom.vhd                   # Character font ROM

- **VGA Pixel Clock:** 25 MHz (50 MHz ÷ 2)│   ├── ps2_keyboard_20mhz.vhd         # Keyboard input

- **Serial Clock:** 2.5 MHz (20 MHz ÷ 8)│   └── archive/                       # Old test files (not used)

│       ├── vga_test_*.vhd

### Serial Communication Protocol│       └── fpga2_standalone_test.vhd

- **Type:** Synchronous Serial│

- **Clock:** 2.5 MHz├── serial_communication_tb.vhd        # Serial communication testbench

- **Data Width:** 40 bits (word guess), 15 bits (result)├── serial_receiver.vhd                # Serial RX (shared)

- **Timing:** └── serial_transmitter.vhd             # Serial TX (shared)

  - Transmitter sends data on falling edge```

  - Receiver samples data on rising edge

- **Synchronization:** 3-stage synchronizer for metastability protection## 🚀 Quick Start Guide



---### 1. Setup Development Environment

- Install **Xilinx ISE 14.7** (Windows/Linux)

## 🐛 Bug Fixes (2025-11-05)- Install **iMPACT** programmer for USB JTAG

- Clone this repository:

### Bug #1: Missing First Bit  ```bash

**ปัญหา:** Receiver พลาดบิตแรก (MSB)    git clone https://github.com/tachhh/fpga-wordle.git

**แก้ไข:** อ่านบิตแรกทันทีใน IDLE state และตั้ง `bit_counter = 1`  cd fpga-wordle

  ```

### Bug #2: Race Condition

**ปัญหา:** ส่งข้อมูลและ clock พร้อมกัน  ### 2. Build FPGA1 (Game Logic)

**แก้ไข:** ส่งข้อมูลที่ falling edge แทน rising edge1. Open Xilinx ISE

2. Create new project: `fpga1_logic/fpga1_wordle`

📄 รายละเอียด: [shared_modules/README.md](shared_modules/README.md)3. Add files:

   - `fpga1_top_serial.vhd`

---   - `word_rom_20mhz.vhd`

   - `word_comparator_20mhz.vhd`

## 📚 Documentation   - `serial_transmitter.vhd`

   - `fpga1_constraints_final.ucf`

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - สถาปัตยกรรมระบบโดยละเอียด4. Set top-level entity: `fpga1_top_serial`

- **[CONNECTION_GUIDE.md](CONNECTION_GUIDE.md)** - คู่มือการต่อสายทั้งหมด5. Synthesize → Implement → Generate bitstream

- **[CORRECT_WIRING.md](CORRECT_WIRING.md)** - ตรวจสอบการต่อสายที่ถูกต้อง6. Flash to FPGA1 board via iMPACT

- **[FINAL_CONFIG.md](FINAL_CONFIG.md)** - การตั้งค่าสุดท้าย

### 3. Build FPGA2 (Display/Input)

---1. Open Xilinx ISE

2. Create new project: `fpga2_vga/fpga2_vga`

## 🤝 Contributing3. Add files:

   - `fpga2_top_3bit_rgb_Version2.vhd`

Contributions are welcome! Please:   - `clock_generator.vhd`

1. Fork the repository   - `vga_controller_20mhz.vhd`

2. Create a feature branch   - `display_renderer_3bit_rgb_Version2.vhd`

3. Make your changes   - `char_rom.vhd`

4. Submit a pull request   - `ps2_keyboard_20mhz.vhd`

   - `serial_receiver.vhd`

---   - `fpga2_constraints_3bit_rgb_Version2.ucf`

4. Set top-level entity: `fpga2_top_3bit_rgb_Version2`

## 📝 License5. Synthesize → Implement → Generate bitstream

6. Flash to FPGA2 board via iMPACT

This project is open source and available under the MIT License.

### 4. Hardware Connections

---1. Connect VGA cable: FPGA2 K4 connector → VGA monitor

2. Connect PS/2 keyboard: FPGA2 K2 connector → PS/2 keyboard

## 👥 Authors3. Connect serial cable: FPGA1 TX pin → FPGA2 RX pin (with ground)

4. Power on both boards

**1AmatsuxD1** - Initial work and development5. Turn on VGA monitor



---### 5. Play Wordle!

- **Type letters A-Z** on keyboard (uppercase only)

## 📞 Contact- **Backspace**: Delete last letter

- **Enter**: Submit 5-letter guess

For questions or issues, please open an issue on GitHub.- **Colors**:

  - 🟩 **Green**: Correct letter, correct position

**Repository:** https://github.com/1AmatsuxD1/fpga-wordle  - 🟨 **Yellow**: Correct letter, wrong position

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
