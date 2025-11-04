# Shared Modules

โมดูลที่ใช้ร่วมกันระหว่าง FPGA #1 และ FPGA #2

## Files

### 1. serial_transmitter.vhd
**Serial Transmitter Module**
- ส่งข้อมูลแบบ Serial (Synchronous)
- รองรับ DATA_WIDTH ปรับได้ (40 bits สำหรับคำทาย, 15 bits สำหรับผลลัพธ์)
- Clock: 20 MHz → 2.5 MHz serial clock
- ส่งข้อมูลที่ falling edge เพื่อหลีกเลี่ยง race condition

**Ports:**
- `data_in`: ข้อมูล parallel input
- `send_start`: สัญญาณเริ่มส่ง (pulse)
- `serial_data`: ข้อมูล serial output
- `serial_clk`: clock สำหรับ receiver
- `busy`: กำลังส่งอยู่
- `done`: ส่งเสร็จแล้ว (pulse)

**ใช้ใน:**
- FPGA #1: ส่งผลลัพธ์การเปรียบเทียบ (15 bits)
- FPGA #2: ส่งคำทาย (40 bits)

---

### 2. serial_receiver.vhd
**Serial Receiver Module**
- รับข้อมูลแบบ Serial (Synchronous)
- รองรับ DATA_WIDTH ปรับได้
- มี 3-stage synchronizer ป้องกัน metastability
- อ่านข้อมูลที่ rising edge ของ serial_clk
- รับบิตแรก (MSB) ทันทีที่ตรวจพบ serial_clk ครั้งแรก

**Ports:**
- `serial_data`: ข้อมูล serial input
- `serial_clk`: clock จาก transmitter
- `data_out`: ข้อมูล parallel output
- `data_ready`: ข้อมูลพร้อม (pulse)
- `busy`: กำลังรับอยู่

**ใช้ใน:**
- FPGA #1: รับคำทาย (40 bits)
- FPGA #2: รับผลลัพธ์การเปรียบเทียบ (15 bits)

---

## Protocol Specification

**Serial Communication Protocol:**
- **Clock Frequency:** 2.5 MHz (หารจาก 20 MHz ÷ 8)
- **Data Transfer:** MSB first
- **Timing:** 
  - Transmitter ส่งข้อมูลที่ falling edge
  - Receiver อ่านข้อมูลที่ rising edge
- **Synchronization:** 3-stage synchronizer ในฝั่ง receiver

**Signal Lines:**
- `serial_data`: ข้อมูล (1 bit)
- `serial_clk`: clock สำหรับ synchronization
- `data_valid`: สัญญาณยืนยันว่าข้อมูลพร้อม
- `acknowledge`: สัญญาณตอบรับ

---

## Bug Fixes (2025-11-05)

### Bug #1: Missing First Bit
**ปัญหา:** Receiver พลาดบิตแรก (MSB) เพราะเข้า RECEIVE state ช้าเกินไป

**แก้ไข:** ย้ายการอ่านบิตแรกมาไว้ใน IDLE state ทันทีที่ตรวจพบ `serial_clk_rise` ครั้งแรก และตั้ง `bit_counter = 1`

### Bug #2: Race Condition
**ปัญหา:** Transmitter ส่งข้อมูลและ toggle clock พร้อมกัน ทำให้ receiver อ่านข้อมูลผิด

**แก้ไข:** เปลี่ยนจากส่งข้อมูลที่ rising edge (`serial_clk_i = '0'`) เป็น falling edge (`serial_clk_i = '1'`) เพื่อให้ข้อมูล stable ก่อน receiver อ่าน

---

## Usage

**ใน ISE Project:**
1. เพิ่มไฟล์ `serial_transmitter.vhd` และ `serial_receiver.vhd` เข้า project
2. Instantiate component ในไฟล์ top-level
3. ตั้งค่า `DATA_WIDTH` generic ตามความต้องการ

**ตัวอย่าง:**
```vhdl
word_transmitter: serial_transmitter
    generic map (DATA_WIDTH => 40)
    port map (
        clk         => clk,
        rst         => rst,
        data_in     => word_to_send,
        send_start  => tx_send_start,
        serial_data => serial_tx_data,
        serial_clk  => serial_tx_clk,
        busy        => tx_busy,
        done        => tx_done
    );
```
