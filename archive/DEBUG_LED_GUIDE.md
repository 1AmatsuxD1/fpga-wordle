# Debug LED Guide - FPGA #2

## LED Positions
```
[L3] [L2] [L1] [L0]
 ↑    ↑    ↑    ↑
 |    |    |    +-- DCM Lock (led_locked)
 |    |    +------- FSM State bit 0 (LSB)
 |    +------------ FSM State bit 1
 +----------------- FSM State bit 2 (MSB)
```

## LED L0 - DCM Lock Status
- **ON (1):**  DCM locked successfully - ระบบพร้อมใช้งาน ✅
- **OFF (0):** DCM not locked - ระบบยังไม่พร้อม ❌

**ถ้า LED L0 ไม่ติด:** Reset FPGA หรือตรวจสอบ clock source

---

## LEDs L3-L2-L1 - FSM State (3-bit Binary)

### State Encoding Table

| State | L3 | L2 | L1 | Decimal | ความหมาย |
|-------|----|----|----|---------|--------------------|
| **INPUT_LETTERS** | 0 | 0 | 0 | 0 | 📝 รอรับตัวอักษร A-Z |
| **WAIT_TX** | 0 | 0 | 1 | 1 | 📤 กำลังส่งคำทายไป FPGA #1 |
| **WAIT_ACKNOWLEDGE** | 0 | 1 | 0 | 2 | ⏳ รอสัญญาณยืนยันจาก FPGA #1 |
| **RECEIVE_RESULT** | 0 | 1 | 1 | 3 | 📥 รอผลลัพธ์จาก FPGA #1 |
| **GAME_END** | 1 | 1 | 1 | 7 | 🏁 เกมจบ (ชนะหรือแพ้) |

---

## วิธีอ่าน LED

### ตัวอย่างที่ 1: Normal Operation
```
เริ่มต้น:     [L3=0][L2=0][L1=0][L0=1]  ← INPUT_LETTERS + DCM Locked
พิมพ์ "HELLO": ยังคง 0-0-0
กด Enter:     [L3=0][L2=0][L1=1][L0=1]  ← WAIT_TX (ส่งข้อมูล)
              [L3=0][L2=1][L0=0][L0=1]  ← WAIT_ACKNOWLEDGE (รอยืนยัน)
              [L3=0][L2=1][L1=1][L0=1]  ← RECEIVE_RESULT (รอผลลัพธ์)
ได้ผลลัพธ์:   [L3=0][L2=0][L1=0][L0=1]  ← กลับไป INPUT_LETTERS
```

### ตัวอย่างที่ 2: FPGA #1 ไม่ตอบสนอง (Timeout)
```
เริ่มต้น:     [L3=0][L2=0][L1=0][L0=1]  ← INPUT_LETTERS
กด Enter:     [L3=0][L2=0][L1=1][L0=1]  ← WAIT_TX
              [L3=0][L2=1][L0=0][L0=1]  ← WAIT_ACKNOWLEDGE (ค้างนาน 5 วินาที)
Timeout:      [L3=0][L2=0][L1=0][L0=1]  ← กลับไป INPUT_LETTERS (แสดงสีเทา)
```

### ตัวอย่างที่ 3: เกมจบ (ชนะหรือแพ้)
```
ทายถูก:       [L3=1][L2=1][L1=1][L0=1]  ← GAME_END (WIN)
หรือ
ทาย 6 ครั้ง:  [L3=1][L2=1][L1=1][L0=1]  ← GAME_END (LOSE)
```

---

## การ Debug ปัญหา

### ปัญหา 1: LED L0 ไม่ติด
**สาเหตุ:** DCM ไม่ lock
**แก้ไข:**
- กด Reset button
- ตรวจสอบ clock source (20 MHz)
- ตรวจสอบ constraints file

### ปัญหา 2: LED ค้างที่ [0-0-1] (WAIT_TX)
**สาเหตุ:** Serial transmitter ไม่ส่ง `tx_done`
**แก้ไข:**
- ตรวจสอบ serial_transmitter.vhd
- ตรวจสอบ clock generator (50 MHz)

### ปัญหา 3: LED ค้างที่ [0-1-0] (WAIT_ACKNOWLEDGE)
**สาเหตุ:** ไม่ได้รับ `acknowledge` จาก FPGA #1
**แก้ไข:**
- ✅ ระบบมี timeout 5 วินาที จะกลับไป INPUT_LETTERS เอง
- ตรวจสอบว่าเชื่อม FPGA #1 แล้วหรือยัง
- ตรวจสอบสาย serial connection
- ตรวจสอบว่า FPGA #1 ทำงานหรือไม่

### ปัญหา 4: LED ค้างที่ [0-1-1] (RECEIVE_RESULT)
**สาเหตุ:** ไม่ได้รับ `result_valid` จาก FPGA #1
**แก้ไข:**
- ✅ ระบบมี timeout 5 วินาที จะกลับไป INPUT_LETTERS เอง
- ตรวจสอบ serial receiver
- ตรวจสอบ FPGA #1 ส่งผลลัพธ์หรือไม่

### ปัญหา 5: LED กระพริบเร็วมาก
**สาเหตุ:** FSM เปลี่ยน state เร็วเกินไป (ปกติ)
**หมายเหตุ:** ถ้าแต่ละ state ใช้เวลาน้อยกว่า 0.1 วินาที อาจมองไม่เห็น
ให้สังเกตว่า LED กลับมาที่ [0-0-0] หรือไม่

---

## Quick Reference Card

```
┌─────────────────────────────────────────┐
│  LED Pattern Quick Reference            │
├─────────────────────────────────────────┤
│  L3 L2 L1 L0  │  Meaning                │
├──────────────┼─────────────────────────┤
│  ⚫ ⚫ ⚫ 🟢  │  พร้อมรับ input       │
│  ⚫ ⚫ 🟢 🟢  │  กำลังส่งคำทาย        │
│  ⚫ 🟢 ⚫ 🟢  │  รอยืนยัน             │
│  ⚫ 🟢 🟢 🟢  │  รอผลลัพธ์            │
│  🟢 🟢 🟢 🟢  │  เกมจบ                │
├──────────────┼─────────────────────────┤
│  x  x  x  ⚫  │  ⚠️ DCM ไม่ lock!      │
└─────────────────────────────────────────┘
```

---

## Pin Mapping Reference

| LED | Pin | Signal | Description |
|-----|-----|--------|-------------|
| L0 | P82 | `led_locked` | DCM lock status |
| L1 | P81 | `debug_led<0>` | FSM state bit 0 |
| L2 | P80 | `debug_led<1>` | FSM state bit 1 |
| L3 | P79 | `debug_led<2>` | FSM state bit 2 |

---

**สร้างเมื่อ:** 2025-11-03  
**สำหรับ:** FPGA Wordle Project - FPGA #2 Debug
