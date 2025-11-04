--------------------------------------------------------------------------------
-- PS/2 Keyboard Controller
-- หน้าที่: รับ scan code จากคีย์บอร์ด PS/2 และแปลงเป็น ASCII (A-Z)
-- รองรับ: Enter, Backspace
-- Clock: 20 MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ps2_keyboard is
    Port (
        clk          : in  std_logic;  -- 20 MHz
        rst          : in  std_logic;
        ps2_clk      : in  std_logic;  -- Clock จากคีย์บอร์ด (~10-16 kHz)
        ps2_data     : in  std_logic;  -- Data จากคีย์บอร์ด
        ascii_code   : out std_logic_vector(7 downto 0);  -- รหัส ASCII ที่ได้
        key_valid    : out std_logic;                      -- สัญญาณว่ามีตัวอักษรใหม่
        key_enter    : out std_logic;                      -- กด Enter
        key_backspace: out std_logic                       -- กด Backspace
    );
end ps2_keyboard;

architecture Behavioral of ps2_keyboard is
    
    -- สถานะของ PS/2 protocol
    type state_type is (IDLE, DATA_BITS, PARITY, STOP);
    signal state : state_type;
    
    -- Synchronizer สำหรับ ps2_clk และ ps2_data (ป้องกัน metastability)
    signal ps2_clk_sync  : std_logic_vector(2 downto 0);
    signal ps2_data_sync : std_logic_vector(2 downto 0);
    signal ps2_clk_fall  : std_logic;  -- Edge detector สำหรับ falling edge
    
    -- ตัวแปรสำหรับรับข้อมูล
    signal bit_count     : unsigned(3 downto 0);
    signal scan_code     : std_logic_vector(7 downto 0);  -- Scan code จากคีย์บอร์ด
    signal scan_ready    : std_logic;                      -- Scan code พร้อม
    
    signal break_code    : std_logic;  -- ตรวจจับ F0 (break code = ปล่อยปุ่ม)
    
begin
    
    -- Synchronizer: ป้องกัน metastability โดยใช้ flip-flop 3 ชั้น
    process(clk)
    begin
        if rising_edge(clk) then
            ps2_clk_sync  <= ps2_clk_sync(1 downto 0) & ps2_clk;
            ps2_data_sync <= ps2_data_sync(1 downto 0) & ps2_data;
        end if;
    end process;
    
    -- ตรวจจับ falling edge ของ PS/2 clock (เมื่อ clock เปลี่ยนจาก 1 → 0)
    ps2_clk_fall <= '1' when ps2_clk_sync(2 downto 1) = "10" else '0';
    
    -- State Machine สำหรับ PS/2 Protocol
    -- โปรโตคอล: [Start bit (0)] + [8 data bits] + [Parity bit] + [Stop bit (1)]
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state      <= IDLE;
                bit_count  <= (others => '0');
                scan_code  <= (others => '0');
                scan_ready <= '0';
            else
                scan_ready <= '0';  -- รีเซ็ตสัญญาณ
                
                if ps2_clk_fall = '1' then  -- อ่านข้อมูลที่ falling edge
                    case state is
                        when IDLE =>
                            -- รอ start bit (ต้องเป็น 0)
                            if ps2_data_sync(2) = '0' then
                                state     <= DATA_BITS;
                                bit_count <= (others => '0');
                            end if;
                        
                        when DATA_BITS =>
                            -- อ่าน 8 bits (LSB first)
                            scan_code <= ps2_data_sync(2) & scan_code(7 downto 1);
                            bit_count <= bit_count + 1;
                            
                            if bit_count = 7 then
                                state <= PARITY;
                            end if;
                        
                        when PARITY =>
                            -- ข้ามการตรวจสอบ parity (เพื่อความง่าย)
                            state <= STOP;
                        
                        when STOP =>
                            -- ตรวจสอบ stop bit (ต้องเป็น 1)
                            if ps2_data_sync(2) = '1' then
                                scan_ready <= '1';  -- Scan code พร้อม
                            end if;
                            state <= IDLE;
                    end case;
                end if;
            end if;
        end if;
    end process;
    
    -- แปลง Scan Code เป็น ASCII
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ascii_code    <= (others => '0');
                key_valid     <= '0';
                key_enter     <= '0';
                key_backspace <= '0';
                break_code    <= '0';
            else
                -- รีเซ็ตสัญญาณ output
                key_valid     <= '0';
                key_enter     <= '0';
                key_backspace <= '0';
                
                if scan_ready = '1' then
                    -- ตรวจสอบ break code (F0 = ปล่อยปุ่ม)
                    if scan_code = x"F0" then
                        break_code <= '1';  -- ปุ่มถัดไปจะเป็น break code
                    else
                        -- ประมวลผลเฉพาะเมื่อกดปุ่ม (break_code = '0')
                        if break_code = '0' then
                            -- ตารางแปลง Scan Code → ASCII (Make Code)
                        case scan_code is
                            -- แถวบนสุด (QWERTY)
                            when x"15" => ascii_code <= x"51"; key_valid <= '1';  -- Q
                            when x"1D" => ascii_code <= x"57"; key_valid <= '1';  -- W
                            when x"24" => ascii_code <= x"45"; key_valid <= '1';  -- E
                            when x"2D" => ascii_code <= x"52"; key_valid <= '1';  -- R
                            when x"2C" => ascii_code <= x"54"; key_valid <= '1';  -- T
                            when x"35" => ascii_code <= x"59"; key_valid <= '1';  -- Y
                            when x"3C" => ascii_code <= x"55"; key_valid <= '1';  -- U
                            when x"43" => ascii_code <= x"49"; key_valid <= '1';  -- I
                            when x"44" => ascii_code <= x"4F"; key_valid <= '1';  -- O
                            when x"4D" => ascii_code <= x"50"; key_valid <= '1';  -- P
                            
                            -- แถวกลาง (ASDF)
                            when x"1C" => ascii_code <= x"41"; key_valid <= '1';  -- A
                            when x"1B" => ascii_code <= x"53"; key_valid <= '1';  -- S
                            when x"23" => ascii_code <= x"44"; key_valid <= '1';  -- D
                            when x"2B" => ascii_code <= x"46"; key_valid <= '1';  -- F
                            when x"34" => ascii_code <= x"47"; key_valid <= '1';  -- G
                            when x"33" => ascii_code <= x"48"; key_valid <= '1';  -- H
                            when x"3B" => ascii_code <= x"4A"; key_valid <= '1';  -- J
                            when x"42" => ascii_code <= x"4B"; key_valid <= '1';  -- K
                            when x"4B" => ascii_code <= x"4C"; key_valid <= '1';  -- L
                            
                            -- แถวล่าง (ZXCV)
                            when x"1A" => ascii_code <= x"5A"; key_valid <= '1';  -- Z
                            when x"22" => ascii_code <= x"58"; key_valid <= '1';  -- X
                            when x"21" => ascii_code <= x"43"; key_valid <= '1';  -- C
                            when x"2A" => ascii_code <= x"56"; key_valid <= '1';  -- V
                            when x"32" => ascii_code <= x"42"; key_valid <= '1';  -- B
                            when x"31" => ascii_code <= x"4E"; key_valid <= '1';  -- N
                            when x"3A" => ascii_code <= x"4D"; key_valid <= '1';  -- M
                            
                            -- ปุ่มพิเศษ
                            when x"5A" => key_enter     <= '1';  -- Enter
                            when x"29" => key_enter     <= '1';  -- Space (สำรอง)
                            when x"66" => key_backspace <= '1';  -- Backspace
                            
                            when others => null;  -- ไม่ทำอะไร
                        end case;
                        end if;
                        -- รีเซ็ต break_code หลังประมวลผล scan code ทุกตัว
                        break_code <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;