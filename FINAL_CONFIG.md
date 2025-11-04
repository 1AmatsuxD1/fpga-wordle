# 📋 สรุปการตั้งค่าก่อน Synthesize

## ⚙️ **FPGA #2 - Final Configuration:**

### **1. TEST_MODE**
```vhdl
// File: fpga2_top_3bit_rgb_Version2.vhd
// Line: ~52

constant TEST_MODE : boolean := false;  // false = เชื่อมต่อกับ FPGA #1
```

### **2. Clock Configuration**
```vhdl
// Input: 20 MHz (OSC)
// DCM: 20 MHz → 50 MHz
// Divider: 50 MHz → 25 MHz (VGA pixel clock)
```

### **3. Display Settings**
```vhdl
// Title: "WORDLE" (32×32 pixels, สีเขียว)
// Position: X=214, Y=10

// Grid: 6 rows × 5 columns
// Cell: 55×55 pixels
// Spacing: 8 pixels
// Position: X=167, Y=70
```

### **4. Debug Signals**
```vhdl
// LED Configuration (UCF):
// LED L0 (P82): DCM locked (clk_locked)
// LED L1 (P81): debug_led[0] - FSM state bit 0
// LED L2 (P80): debug_led[1] - FSM state bit 1
// LED L3 (P79): debug_led[2] - tx_busy

// Debug Pin Outputs:
// Pin P12: debug_tx_clk = serial_tx_clk_i (clock output)
// Pin P15: debug_data_valid = data_valid_i (data valid signal)

// LED Interpretation (L3:L2:L1 = binary):
// 000 = INPUT_LETTERS
// 001 = START_TX
// 101 = WAIT_TX (with tx_busy=1)
// 001 = WAIT_TX (tx_busy=0, waiting to complete)
// 010 = WAIT_ACKNOWLEDGE
// 110 = RECEIVE_RESULT
// 011 = GAME_END
```

---

## ⚙️ **FPGA #1 - Configuration:**

### **1. Game Settings**
```vhdl
// File: fpga1_top_serial.vhd

constant MAX_GUESSES : integer := 6;  // ทาย 6 ครั้ง

// Status:
// "000" = กำลังเล่น
// "001" = ชนะ
// "010" = แพ้
```

### **2. Debug LEDs**
```vhdl
// LED Configuration (UCF):
// LED L3 (P79): heartbeat_led (กระพริบทุก 0.5 วินาที)
// LED L0 (P82): debug_led[0] = data_valid_s2 (synchronized)
// LED L1 (P81): debug_led[1] = word_received
// LED L2 (P80): debug_led[2] = serial_rx_clk

// LED Functions:
// L3: ติดกระพริบ = FPGA ทำงานปกติ
// L0: ติด = ได้รับ data_valid จาก FPGA #2
// L1: ติด = รับคำทาย 40 bits สำเร็จ
// L2: กระพริบ = กำลังรับ serial clock จาก FPGA #2
```

---

## 📁 **Files to Synthesize:**

### **FPGA #2:**
```
Top Module: fpga2_top_3bit_rgb_Version2.vhd
UCF: fpga2_constraints_3bit_rgb_Version2.ucf

Dependencies:
- clock_generator.vhd (หรือ clock_generator_pll.vhd)
- ps2_keyboard_20mhz.vhd
- vga_controller_20mhz.vhd
- display_renderer_3bit_rgb_Version2.vhd
- char_rom.vhd
- serial_transmitter.vhd
- serial_receiver.vhd
```

### **FPGA #1:**
```
Top Module: fpga1_top_serial.vhd
UCF: fpga1_constraints_final.ucf

Dependencies:
- serial_transmitter.vhd
- serial_receiver.vhd
- word_comparator_20mhz.vhd
- word_rom_20mhz.vhd
```

---

## 🎯 **Synthesis Checklist:**

### **FPGA #2:**
```
☐ TEST_MODE = false ✅
☐ All files added to project
☐ Top module selected
☐ UCF constraints applied
☐ Synthesize → Implement → Generate Programming File
☐ Check for errors
☐ Generate .bit file
```

### **FPGA #1:**
```
☐ All files added to project
☐ Top module selected
☐ UCF constraints applied
☐ Synthesize → Implement → Generate Programming File
☐ Check for errors
☐ Generate .bit file
```

---

## 🔌 **Connection Summary:**

### **Quick Reference:**
```
ต่อตรงกัน (Pin-to-Pin):
P5  ↔ P5   (TX Data #2 ↔ RX Data #1)
P7  ↔ P7   (TX Clock #2 ↔ RX Clock #1)
P9  ↔ P9   (Data Valid #2 ↔ RX Valid #1)
P11 ↔ P11  (RX Data #2 ↔ TX Data #1)
P14 ↔ P14  (RX Clock #2 ↔ TX Clock #1)
P16 ↔ P16  (RX Ack #2 ↔ TX Ack #1)
P21 ↔ P21  (RX Valid #2 ↔ TX Valid #1)

Status (Bi-directional):
P6  ↔ P6   (Status[0])
P8  ↔ P8   (Status[1])
P10 ↔ P10  (Status[2])

GND ↔ GND  ⚠️ สำคัญ!
```

---

## 📌 **Complete Pin Assignment Reference:**

### **FPGA #2 Pin Assignments:**
```
// Serial TX (to FPGA #1):
P5  - serial_tx_data
P7  - serial_tx_clk
P9  - data_valid

// Serial RX (from FPGA #1):
P11 - serial_rx_data
P14 - serial_rx_clk
P16 - acknowledge
P21 - result_valid

// Game Status (from FPGA #1):
P6  - game_status[0]
P8  - game_status[1]
P10 - game_status[2]

// Debug Outputs:
P12 - debug_tx_clk (serial_tx_clk monitor)
P15 - debug_data_valid (data_valid monitor)

// LEDs:
P82 - led_locked (L0)
P81 - debug_led[0] (L1)
P80 - debug_led[1] (L2)
P79 - debug_led[2] (L3)

// VGA:
P35 - vga_r (Red)
P33 - vga_g (Green)
P34 - vga_b (Blue)
P43 - vga_hsync
P44 - vga_vsync

// PS/2 Keyboard:
P22 - ps2_clk
P23 - ps2_data
```

### **FPGA #1 Pin Assignments:**
```
// Serial RX (from FPGA #2):
P5  - serial_rx_data
P7  - serial_rx_clk
P9  - data_valid

// Serial TX (to FPGA #2):
P11 - serial_tx_data
P14 - serial_tx_clk
P16 - acknowledge
P21 - result_valid

// Game Status (to FPGA #2):
P6  - game_status[0]
P8  - game_status[1]
P10 - game_status[2]

// LEDs:
P79 - heartbeat_led (L3)
P82 - debug_led[0] (L0)
P81 - debug_led[1] (L1)
P80 - debug_led[2] (L2)
```

---

## ✅ **Final Checks Before Upload:**

### **1. Code Verification:**
```
☐ TEST_MODE = false (FPGA #2)
☐ No syntax errors
☐ No warnings (หรือเข้าใจ warnings)
☐ Timing constraints met
```

### **2. Hardware Verification:**
```
☐ สายต่อครบ 11 เส้น + GND
☐ ใช้ multimeter ตรวจ continuity
☐ ไม่มี short circuit
☐ GND ต่อระหว่างบอร์ด
```

### **3. Upload Process:**
```
☐ เปิดเครื่อง FPGA #1
☐ Upload fpga1_top_serial.bit
☐ เช็ค LED L3 ต้องกระพริบ
☐ เปิดเครื่อง FPGA #2  
☐ Upload fpga2_top_3bit_rgb_Version2.bit
☐ เช็ค LED L0 ต้องติด (DCM)
```

---

## 🎮 **Expected Behavior:**

### **ขั้นตอนการเล่น:**
```
1. เปิดทั้ง 2 บอร์ด
   FPGA #1: L3 กระพริบ (Heartbeat)
   FPGA #2: L0 ติด (DCM), จอแสดง "WORDLE"

2. พิมพ์คำ 5 ตัว (เช่น HELLO)
   FPGA #2: L1-L3 เพิ่มขึ้น (001→010→011→100→101)
   จอ: แสดง "HELLO" สีม่วง

3. กด Enter
   FPGA #2: P15 ติด 1 วินาที
   FPGA #1: L0 ติด (data_valid)
   FPGA #1: L1 ติด (word_received)

4. รอ 1-2 วินาที
   FPGA #1: ประมวลผลคำตอบ
   FPGA #1: ส่งผลลัพธ์กลับ

5. จอแสดงสี:
   🟢 เขียว = ถูกต้อง
   🟡 เหลือง = มีตัวอักษร แต่ตำแหน่งผิด
   🟣 ม่วง = ไม่มีตัวอักษรนี้

6. ทำซ้ำได้ 6 รอบ
```

---

## 🔍 **LED Troubleshooting Guide:**

### **FPGA #2 LED States:**

| LED State | L3 | L2 | L1 | L0 | Meaning |
|-----------|----|----|----|----|---------|
| Power On | 0 | 0 | 0 | 1 | DCM locked, waiting for input |
| Typing (1 letter) | 0 | 0 | 1 | 1 | Buffer has 1 letter |
| Typing (5 letters) | 1 | 0 | 1 | 1 | Buffer full, ready to send |
| START_TX | 0 | 0 | 1 | 1 | Starting transmission |
| WAIT_TX (busy) | 1 | 0 | 1 | 1 | Transmitting (tx_busy=1) |
| WAIT_ACK | 0 | 1 | 0 | 1 | Waiting for FPGA #1 acknowledge |
| Success | 0 | 0 | 0 | 1 | Back to INPUT_LETTERS |

**⚠️ If stuck at:**
- **`010` (WAIT_ACK)** = FPGA #1 not responding → Check wiring P11,P14,P16,P21
- **`101` (WAIT_TX forever)** = tx_busy stuck → Check serial_transmitter
- **`001` (START_TX forever)** = Not entering WAIT_TX → Check tx_send_start

### **FPGA #1 LED States:**

| LED | Pin | Signal | Normal Behavior |
|-----|-----|--------|-----------------|
| L3 | P79 | heartbeat | กระพริบทุก 0.5 วินาที |
| L2 | P80 | serial_rx_clk | กระพริบเมื่อรับข้��มูล |
| L1 | P81 | word_received | ติดเมื่อรับครบ 40 bits |
| L0 | P82 | data_valid | ติดเมื่อ FPGA #2 ส่ง data_valid |

**⚠️ If:**
- **L3 not blinking** = FPGA #1 not running → Re-upload .bit file
- **L0 ON, L2 OFF** = No serial clock → Check P7 connection
- **L0 ON, L2 ON, L1 OFF** = Clock but no data complete → Check serial_receiver
- **All LEDs OFF** = Power issue or wrong .bit file

---

## 🏆 **Success Criteria:**

```
✅ จอแสดง "WORDLE" สีเขียว
✅ พิมพ์ตัวอักษรได้ (A-Z)
✅ กด Enter/Space ส่งข้อมูล
✅ FPGA #1 รับข้อมูลได้ (L0-L1 ติด)
✅ จอแสดงสี 3 แบบ (เขียว/เหลือง/ม่วง)
✅ เล่นได้ 6 รอบ
✅ ชนะ → Status bar เขียว
✅ แพ้ → Status bar เหลือง
```

---

## 📞 **Contact for Help:**

ถ้ามีปัญหา ให้เก็บข้อมูลนี้:
- LED status ของทั้ง 2 บอร์ด
- จอแสดงอะไร
- ขั้นตอนที่ทำก่อนเกิดปัญหา
- Error messages (ถ้ามี)

Good luck! 🎉
