# Debug Checklist - FPGA Wordle System

## 🔍 ตารางวินิจฉัยปัญหา

### ปัญหา A: FPGA #2 ไม่รับ input
```
อาการ: พิมพ์แล้วไม่เห็นตัวอักษรบนจอ
```

**ตรวจสอบ:**
- [ ] VGA cable เสียบแน่นหรือไม่?
- [ ] จอรับสัญญาณ 640x480 @ 60Hz ได้หรือไม่?
- [ ] LED L0 (DCM) ติดหรือไม่?
- [ ] PS/2 keyboard เสียบถูก port หรือไม่?
- [ ] LED L1-L3 = `[0-0-0]` หรือไม่?

**แก้ไข:**
1. เช็ค VGA connection
2. เช็ค PS/2 connection (P124, P127)
3. กด Reset button

---

### ปัญหา B: พิมพ์ได้ แต่กด Enter แล้ว LED ไม่เปลี่ยน
```
อาการ: พิมพ์ครบ 5 ตัว กด Enter แล้ว LED ยังคงเป็น [0-0-0]
```

**ตรวจสอบ:**
- [ ] `TEST_MODE = false` หรือไม่?
- [ ] Serial transmitter ทำงานหรือไม่?

**แก้ไข:**
```vhdl
-- ใน fpga2_top_3bit_rgb_Version2.vhd
constant TEST_MODE : boolean := false;  -- ต้องเป็น false!
```

---

### ปัญหา C: FPGA #2 LED กระพริบ [0-0-1] แต่ FPGA #1 ไม่ตอบสนอง
```
อาการ: 
- FPGA #2: [0-0-1] (WAIT_TX) แล้วเปลี่ยนเป็น [0-1-0] (WAIT_ACK)
- FPGA #1: L0, L1, L2 ดับหมด
```

**ปัญหา: สายไม่เชื่อมหรือ GND ไม่ร่วมกัน**

**ตรวจสอบ:**

| FPGA #2 | → | FPGA #1 | Connector | Status |
|---------|---|---------|-----------|--------|
| P5 (TX_data) | → | P5 (RX_data) | K1 Pin 15 | [ ] |
| P7 (TX_clk) | → | P7 (RX_clk) | K1 Pin 13 | [ ] |
| P9 (data_valid) | → | P9 (data_valid) | K1 Pin 11 | [ ] |
| GND | ─ | GND | K1 Pin 16,14,12... | [ ] |

**วิธีเช็ค Continuity:**
1. ปิด FPGA ทั้ง 2 ตัว
2. ใช้ Multimeter (Continuity mode)
3. แตะ P5 ของ FPGA #2 กับ P5 ของ FPGA #1
4. **ต้องมีเสียงบี๊บ** = connected ✅
5. ทำซ้ำกับ P7, P9, GND

**ถ้าไม่มี Continuity:**
- ❌ สายหลุด
- ❌ สายขาด
- ❌ Ribbon cable เสียบไม่แน่น
- ❌ เสียบผิด connector

**แก้ไข:**
1. ถอดสายทั้งหมด
2. เชื่อม K1 ใหม่ (ribbon cable)
3. เชื่อม K2 ใหม่ (ribbon cable)
4. **สำคัญ:** ตรวจสอบ orientation (Pin 1 ตรง Pin 1)

---

### ปัญหา D: FPGA #1 LED L3 ไม่กระพริบ
```
อาการ: LED ทั้งหมดของ FPGA #1 ดับ
```

**ปัญหา: FPGA #1 ไม่ทำงาน**

**ตรวจสอบ:**
- [ ] FPGA #1 มีไฟเลี้ยงหรือไม่?
- [ ] Flash bitstream แล้วหรือยัง?
- [ ] Reset button ค้างหรือไม่?

**แก้ไข:**
1. เช็ค power supply (ไฟ LED บนบอร์ดติดหรือไม่)
2. Flash FPGA #1 ใหม่
3. กด Reset button แล้วปล่อย

---

### ปัญหา E: FPGA #1 L3 กระพริบ แต่ L0, L1, L2 ดับ
```
อาการ: 
- FPGA #1 ทำงาน (L3 กระพริบ)
- แต่ไม่ได้รับสัญญาณจาก FPGA #2 (L0, L1, L2 ดับ)
```

**ปัญหา: สายไม่เชื่อมหรือ FPGA #2 ไม่ส่ง**

**ทดสอบแบบละเอียด:**

#### Test 1: ใช้ Multimeter วัด Voltage
```
เครื่องมือ: Multimeter (DC Voltage Mode)

1. เข็มดำ → GND ของ FPGA #1
2. เข็มแดง → P9 ของ FPGA #1
3. บน FPGA #2: พิมพ์ 5 ตัว → กด Enter
4. สังเกต Multimeter:
   
   ผลที่คาดหวัง:
   - เห็น 0V → กระโดดเป็น 3.3V → ค้างไว้ 2-5 วินาที → กลับเป็น 0V
   
   ถ้าไม่เห็นอะไร:
   - ❌ สายไม่เชื่อม หรือ
   - ❌ FPGA #2 ไม่ส่ง data_valid
```

#### Test 2: ใช้ LED external
```
เครื่องมือ: LED + Resistor 330Ω

1. LED Anode (+) → P9 (FPGA #1)
2. LED Cathode (-) → Resistor → GND
3. บน FPGA #2: พิมพ์ 5 ตัว → กด Enter
4. สังเกต LED:
   
   ผลที่คาดหวัง:
   - LED ติดค้างไว้ 2-5 วินาที
   
   ถ้า LED ไม่ติด:
   - ❌ P9 ไม่มีสัญญาณ
```

**แก้ไข:**
1. ตรวจสอบสาย K1 Pin 11 (P9)
2. ตรวจสอบ GND ร่วมกัน
3. ตรวจสอบ FPGA #2 ว่า LED เป็น `[0-0-1]` หรือไม่

---

### ปัญหา F: FPGA #1 L0 ติด แต่ L1, L2 ดับ
```
อาการ:
- L0 (data_valid) = ✅ ติด
- L1 (word_received) = ❌ ดับ
- L2 (serial_rx_clk) = ❌ ดับ
```

**ปัญหา: มี data_valid แต่ไม่มี clock หรือ data**

**ตรวจสอบ:**
- [ ] สาย P7 (serial_tx_clk) เชื่อมหรือไม่?
- [ ] สาย P5 (serial_tx_data) เชื่อมหรือไม่?

**แก้ไข:**
1. เช็ค continuity ของ P7
2. เช็ค continuity ของ P5

---

### ปัญหา G: FPGA #1 L0, L2 กระพริบ แต่ L1 ดับ
```
อาการ:
- L0 (data_valid) = 💛 กระพริบ
- L2 (serial_rx_clk) = 💛 กระพริบ
- L1 (word_received) = ❌ ดับ
```

**ปัญหา: Serial receiver ไม่รับข้อมูลครบ**

**สาเหตุ:**
- Serial receiver มีปัญหา
- Data corruption
- Clock timing ไม่ตรง

**แก้ไข:**
1. ตรวจสอบ serial_receiver.vhd
2. ตรวจสอบ baud rate / clock frequency
3. เพิ่ม synchronizer สำหรับ serial_rx_clk

---

## 🎯 ขั้นตอนการ Debug แบบเป็นระบบ

### Step 1: ทดสอบ FPGA #2 แบบ Standalone
```
1. ตั้ง TEST_MODE = true
2. Synthesize และ Flash
3. ทดสอบ:
   - พิมพ์ 5 ตัว → กด Enter
   - ต้องเห็นสีทันที (ไม่รอ 5 วินาที)
   - LED ไม่เปลี่ยน (ค้างที่ [0-0-0])

ถ้าผ่าน: FPGA #2 ทำงานดี ✅
ถ้าไม่ผ่าน: ปัญหาอยู่ที่ FPGA #2 ❌
```

### Step 2: ทดสอบ FPGA #1 แบบ Standalone
```
1. เปิด FPGA #1
2. ดู LED L3 (heartbeat):
   - กระพริบ = ทำงานดี ✅
   - ไม่กระพริบ = ไม่ทำงาน ❌

ถ้าผ่าน: FPGA #1 ทำงานดี ✅
```

### Step 3: ทดสอบการเชื่อมต่อ
```
1. ตั้ง TEST_MODE = false (FPGA #2)
2. Synthesize และ Flash
3. เชื่อมสาย K1, K2
4. ทดสอบ:
   - พิมพ์ 5 ตัว → กด Enter
   - ดู LED ทั้ง 2 boards

ผลที่คาดหวัง:
┌──────────────┬────────────────┬──────────────────┐
│ เวลา         │ FPGA #2 LED    │ FPGA #1 LED      │
├──────────────┼────────────────┼──────────────────┤
│ พิมพ์        │ [0-0-0]        │ L3 กระพริบ       │
│ กด Enter     │ [0-0-1] แปปเดียว│ L0 ติด          │
│ หลัง 0.1s    │ [0-1-0]        │ L1 ติด          │
│ หลัง 0.2s    │ [0-1-1]        │ L2 กระพริบ      │
│ แสดงผล      │ [0-0-0]        │ กลับปกติ        │
└──────────────┴────────────────┴──────────────────┘

ถ้าไม่ตรงตาราง: มีปัญหาการเชื่อมต่อ ❌
```

### Step 4: Debug Serial Communication
```
ถ้าถึงขั้นนี้แล้วยังไม่ได้:

1. ใช้ Oscilloscope ดู waveform:
   - P7: ต้องเห็น square wave 2.5 MHz
   - P5: ต้องเห็น data bits
   - P9: ต้องเห็น pulse นาน 2-5 วินาที

2. ใช้ Logic Analyzer:
   - Decode serial protocol
   - ดูว่า data ส่งถูกต้องหรือไม่

3. เพิ่ม Testbench:
   - Simulate serial_transmitter
   - Simulate serial_receiver
   - ดูว่า logic ถูกต้องหรือไม่
```

---

## 🛠️ เครื่องมือที่แนะนำ

### ระดับพื้นฐาน (มีอยู่แล้ว)
- ✅ LED บน board (ใช้ได้ดี!)
- ✅ จอ VGA (ดูผลลัพธ์)
- ✅ คีย์บอร์ด PS/2 (input)

### ระดับกลาง (แนะนำมี)
- 📏 Multimeter - วัด voltage/continuity
- 🔦 Logic Probe - ดู digital signals
- 💡 LED external + resistor - ทดสอบ pins

### ระดับสูง (ถ้ามีดีมาก)
- 📊 Oscilloscope - ดู waveforms
- 🔬 Logic Analyzer - decode protocols
- 💻 JTAG Debugger - debug ใน real-time

---

## 📞 ติดต่อ Support

ถ้า debug แล้วยังไม่ได้ ให้บอกข้อมูลนี้:

1. **LED Status:**
   ```
   FPGA #2 L0: [ติด/ดับ]
   FPGA #2 L1-L3: [x-x-x]
   FPGA #1 L3: [กระพริบ/ดับ]
   FPGA #1 L0-L2: [x-x-x]
   ```

2. **การทดสอบที่ทำแล้ว:**
   - [ ] Test Mode ทำงานหรือไม่
   - [ ] Continuity test
   - [ ] Voltage test
   - [ ] ฯลฯ

3. **สิ่งที่เห็น:**
   - อาการผิดปกติ
   - Error messages
   - LED patterns

---

**อัปเดตล่าสุด:** 2025-11-04
**สำหรับ:** FPGA Wordle Project Debug Guide
