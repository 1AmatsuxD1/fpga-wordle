# FPGA Wordle Game

โปรเจกต์เกม Wordle บน FPGA 2 บอร์ด ใช้ VHDL และ Xilinx ISE

## สถาปัตยกรรม

### FPGA Board #1: Game Logic
- ตรวจสอบคำทาย (Word Comparator)
- เก็บคำตอบ (Word ROM)
- จัดการสถานะเกม (FSM)
- Serial Communication Transmitter

**ไฟล์หลัก:**
- `fpga1_logic/fpga1_top_serial.vhd` - Top-level entity
- `fpga1_logic/word_comparator_20mhz.vhd` - เปรียบเทียบคำ
- `fpga1_logic/word_rom_20mhz.vhd` - เก็บคำตอบ 16 คำ
- `fpga1_logic/fpga1_constraints_final.ucf` - Pin constraints

### FPGA Board #2: Display & Input
- VGA Display (3-bit RGB, 8 สี)
- PS/2 Keyboard Input
- Display Renderer
- Serial Communication Receiver

**ไฟล์หลัก:**
- `fpga2_vga/fpga2_top_3bit_rgb_Version2.vhd` - Top-level entity
- `fpga2_vga/display_renderer_3bit_rgb_Version2.vhd` - แสดงผลตาราง
- `fpga2_vga/vga_controller_20mhz.vhd` - VGA timing
- `fpga2_vga/ps2_keyboard_20mhz.vhd` - Keyboard input
- `fpga2_vga/char_rom.vhd` - Character ROM
- `fpga2_vga/fpga2_constraints_3bit_rgb_Version2.ucf` - Pin constraints

### Serial Communication
- **FPGA2 → FPGA1**: ส่งคำทาย (40 bits = 5 letters)
- **FPGA1 → FPGA2**: ส่งผลลัพธ์ (15 bits = 5×3 bits สี)

**ไฟล์ที่ใช้ร่วมกัน:**
- `serial_receiver.vhd` - รับข้อมูล serial
- `serial_transmitter.vhd` - ส่งข้อมูล serial
- `serial_communication_tb.vhd` - Testbench

## สี (3-bit RGB)
- 🟩 **เขียว (010)**: ตัวอักษรถูกต้องและตำแหน่งถูก
- 🟨 **เหลือง (110)**: ตัวอักษรถูกต้องแต่ตำแหน่งผิด
- 🟣 **ม่วง (101)**: ตัวอักษรไม่มีในคำตอบ (แทนสีเทา)
- ⚪ **ขาว (111)**: ขอบและตัวอักษร
- ⚫ **ดำ (000)**: พื้นหลัง

## Clock
- ทั้ง 2 FPGA ใช้ Clock 20 MHz
- Serial Clock: 2.5 MHz (สำหรับการสื่อสาร)
- VGA Pixel Clock: 10 MHz (divider จาก 20 MHz)

## การใช้งาน
1. เปิดโปรเจกต์ด้วย Xilinx ISE
2. Synthesize แต่ละ FPGA แยกกัน
3. Program ลง FPGA board
4. เชื่อมต่อสาย serial ระหว่าง 2 บอร์ด
5. เล่นเกม Wordle!

## การพัฒนา
- **ภาษา**: VHDL
- **เครื่องมือ**: Xilinx ISE
- **FPGA**: Spartan-3E หรือ Spartan-6

## License
MIT License
