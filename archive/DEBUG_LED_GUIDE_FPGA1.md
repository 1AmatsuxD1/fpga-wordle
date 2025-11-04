# Debug LED Guide - FPGA #1 (Game Logic)

## LED Positions
```
[L2] [L1] [L0]
 ↑    ↑    ↑
 |    |    +-- FSM State bit 0 (LSB)
 |    +------- FSM State bit 1
 +------------ FSM State bit 2 (MSB)
```

---

## FSM State Encoding Table

| State | L2 | L1 | L0 | Decimal | ความหมาย |
|-------|----|----|----|---------|--------------------|
| **IDLE** | 0 | 0 | 0 | 0 | ⏳ รอรับคำทายจาก FPGA #2 |
| **RECEIVE_WORD** | 0 | 0 | 1 | 1 | 📥 รับคำทายแล้ว ส่ง ACK |
| **COMPARE** | 0 | 1 | 0 | 2 | 🔍 กำลังเปรียบเทียบคำ |
| **SEND_RESULT** | 0 | 1 | 1 | 3 | 📤 ส่งผลลัพธ์กลับไป |
| **WIN** | 1 | 0 | 0 | 4 | 🎉 ผู้เล่นชนะ! |
| **LOSE** | 1 | 0 | 1 | 5 | 😢 หมดโอกาส |

---

## วิธีอ่าน LED

### ตัวอย่างที่ 1: Normal Operation (ทายผิด)
```
เริ่มต้น:      [0-0-0]  IDLE - รอรับคำ
ได้รับคำทาย:   [0-0-1]  RECEIVE_WORD - ส่ง acknowledge
เปรียบเทียบ:   [0-1-0]  COMPARE - ตรวจสอบคำ
ส่งผลลัพธ์:    [0-1-1]  SEND_RESULT - ส่งสีกลับไป
กลับสู่รอรับ:  [0-0-0]  IDLE - พร้อมรับคำใหม่
```

### ตัวอย่างที่ 2: ทายถูก (ชนะ)
```
เริ่มต้น:      [0-0-0]  IDLE
ได้รับคำทาย:   [0-0-1]  RECEIVE_WORD
เปรียบเทียบ:   [0-1-0]  COMPARE - พบว่าถูกทั้งหมด!
ส่งผลลัพธ์:    [0-1-1]  SEND_RESULT
ชนะ:          [1-0-0]  WIN - ค้างไว้
```

### ตัวอย่างที่ 3: ทาย 6 ครั้งแล้ว (แพ้)
```
ครั้งที่ 6:    [0-1-0]  COMPARE - ตรวจสอบครั้งสุดท้าย
ส่งผลลัพธ์:    [0-1-1]  SEND_RESULT
แพ้:          [1-0-1]  LOSE - ค้างไว้
```

---

## การ Debug ปัญหา

### ปัญหา 1: LED ค้างที่ [0-0-0] (IDLE)
**สาเหตุ:** FPGA #1 ไม่ได้รับข้อมูลจาก FPGA #2

**ตรวจสอบ:**
- ✅ สาย `serial_rx_data` (P5) เชื่อมหรือไม่?
- ✅ สาย `serial_rx_clk` (P7) เชื่อมหรือไม่?
- ✅ สาย `data_valid` (P9) เชื่อมหรือไม่?
- ✅ GND เชื่อมร่วมกันหรือไม่?
- ✅ FPGA #2 ส่งข้อมูลหรือไม่? (ดู LED FPGA #2 ที่ `001` WAIT_TX)

**การแก้:**
```
1. ตรวจสอบการเชื่อมสายทั้ง 3 เส้น
2. ใช้ multimeter วัดว่ามี continuity หรือไม่
3. ตรวจสอบว่า pin assignment ตรงกัน:
   FPGA #2 TX (P5) → FPGA #1 RX (P5)
```

### ปัญหา 2: LED กระพริบ [0-0-1] แล้วกลับ [0-0-0]
**สาเหตุ:** รับข้อมูลได้แต่ไม่เข้า COMPARE

**ตรวจสอบ:**
- Serial receiver อาจได้รับข้อมูลไม่ครบ
- `word_received` signal มี glitch

**การแก้:**
- ตรวจสอบ serial_receiver.vhd
- เพิ่ม synchronizer

### ปัญหา 3: LED ค้างที่ [0-1-0] (COMPARE)
**สาเหตุ:** Word comparator ไม่ส่ง `done`

**ตรวจสอบ:**
- word_comparator_20mhz.vhd
- `compare_start` signal

### ปัญหา 4: LED ค้างที่ [0-1-1] (SEND_RESULT)
**สาเหตุ:** Serial transmitter ไม่ส่ง `tx_done`

**ตรวจสอบ:**
- serial_transmitter.vhd
- `tx_send_start` signal

---

## Quick Reference - LED Pattern

```
┌─────────────────────────────────────┐
│  FPGA #1 LED Pattern Reference      │
├─────────────────────────────────────┤
│  L2 L1 L0  │  State      │ Action   │
├────────────┼─────────────┼──────────┤
│  ⚫ ⚫ ⚫  │  IDLE       │ รอรับคำ │
│  ⚫ ⚫ 🟢  │  RECEIVE    │ ส่ง ACK │
│  ⚫ 🟢 ⚫  │  COMPARE    │ ตรวจคำ  │
│  ⚫ 🟢 🟢  │  SEND       │ ส่งผล   │
│  🟢 ⚫ ⚫  │  WIN        │ ชนะ     │
│  🟢 ⚫ 🟢  │  LOSE       │ แพ้     │
└─────────────────────────────────────┘
```

---

## Pin Mapping Reference

| LED | Pin | Signal | Description |
|-----|-----|--------|-------------|
| L0 | P82 | `debug_led<0>` | FSM state bit 0 |
| L1 | P81 | `debug_led<1>` | FSM state bit 1 |
| L2 | P80 | `debug_led<2>` | FSM state bit 2 |

---

## Expected Flow

### Normal Game Flow:
```
FPGA #2: กด Enter
  ↓
FPGA #2: [0-0-1] WAIT_TX → ส่งคำทาย
  ↓
FPGA #1: [0-0-1] RECEIVE_WORD → ส่ง acknowledge
  ↓
FPGA #2: [0-1-0] WAIT_ACKNOWLEDGE → ได้รับ ACK
  ↓
FPGA #1: [0-1-0] COMPARE → เปรียบเทียบคำ
  ↓
FPGA #1: [0-1-1] SEND_RESULT → ส่งสีกลับ
  ↓
FPGA #2: [0-1-1] RECEIVE_RESULT → แสดงสี
  ↓
ทั้งคู่กลับ: [0-0-0] / [0-0-0] → พร้อมรอบใหม่
```

---

**สร้างเมื่อ:** 2025-11-03  
**สำหรับ:** FPGA Wordle Project - FPGA #1 Debug
