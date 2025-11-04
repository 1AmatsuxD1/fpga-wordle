--------------------------------------------------------------------------------
-- Serial Transmitter: ส่งข้อมูลแบบ Serial
-- ใช้สำหรับส่งคำทาย (40 bits) และผลลัพธ์ (15 bits)
-- Clock: 20 MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_transmitter is
    Generic (
        DATA_WIDTH : integer := 40  -- ความกว้างข้อมูล (bits)
    );
    Port (
        clk         : in  std_logic;  -- 20 MHz
        rst         : in  std_logic;
        
        -- Parallel Input
        data_in     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        send_start  : in  std_logic;  -- สัญญาณเริ่มส่ง
   
         
        -- Serial Output
        serial_data : out std_logic;  -- ข้อมูล serial (ทีละ bit)
        serial_clk  : out std_logic;  -- clock สำหรับ receiver
        busy        : out std_logic;  -- กำลังส่งอยู่
        done        : out std_logic   -- ส่งเสร็จแล้ว
    );
end serial_transmitter;

architecture Behavioral of serial_transmitter is
    
    type state_type is (IDLE, TRANSMIT, FINISH);
    signal state : state_type;
    
    signal shift_reg   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bit_counter : integer range 0 to DATA_WIDTH;
    signal clk_divider : unsigned(3 downto 0);  -- หาร clock ลง
    signal serial_clk_i  : std_logic;

begin
    
    -- Clock divider: 20 MHz -> 2.5 MHz (หารด้วย 8)
    -- ส่ง clock เฉพาะตอน TRANSMIT เท่านั้น
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_divider <= (others => '0');
                serial_clk_i <= '0';
            elsif state = TRANSMIT then
                clk_divider <= clk_divider + 1;
                if clk_divider = 3 then  -- Toggle ทุก 4 cycles (2.5 MHz)
                    serial_clk_i <= not serial_clk_i;
                    clk_divider <= (others => '0');
                end if;
            else
                -- IDLE หรือ FINISH: reset clock เป็น 0
                clk_divider <= (others => '0');
                serial_clk_i <= '0';
            end if;
        end if;
    end process;
    
    serial_clk <= serial_clk_i;

    -- Main FSM
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= IDLE;
                shift_reg   <= (others => '0');
                bit_counter <= 0;
                serial_data <= '0';
                busy        <= '0';
                done        <= '0';
            else
                done <= '0'; -- Pulse signal
                
                case state is
                    when IDLE =>
                        busy <= '0';
                        if send_start = '1' then
                            shift_reg   <= data_in;
                            bit_counter <= 0;
                            state       <= TRANSMIT;
                            busy        <= '1';
                        end if;

                    when TRANSMIT =>
                        busy <= '1';
                        
                        -- [FIX] ส่งข้อมูลที่ "ขอบขาลง" (falling edge) ของ serial clock
                        -- (เมื่อ clk_divider = 3 และ serial_clk_i กำลังจะเปลี่ยนจาก '1' -> '0')
                        -- เพื่อให้ข้อมูลนิ่งในจังหวะที่ Receiver (ซึ่งอ่านที่ขอบขาขึ้น) มาอ่าน
                        if clk_divider = 3 and serial_clk_i = '1' then
                            -- ส่ง MSB first
                            serial_data <= shift_reg(DATA_WIDTH-1);
                            shift_reg   <= shift_reg(DATA_WIDTH-2 downto 0) & '0';
                            bit_counter <= bit_counter + 1;
                            
                            if bit_counter = DATA_WIDTH-1 then
                                state <= FINISH;
                            end if;
                        end if;
                    
                    when FINISH =>
                        busy  <= '0';
                        done  <= '1';
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
end Behavioral;