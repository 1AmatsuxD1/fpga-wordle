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
// LED L0: DCM locked
// LED L1-L3: buffer_index (จำนวนตัวอักษร 0-5)
// Pin P12: key_valid_latch
// Pin P15: key_enter_latch (ติดค้าง 1 วินาที)
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
// LED L3: Heartbeat (กระพริบทุก 0.5 วินาที)
// LED L0: data_valid (รับสัญญาณจาก FPGA #2)
// LED L1: word_received (รับคำสำเร็จ)
// LED L2: serial_rx_clk (กระพริบเมื่อรับ clock)
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
