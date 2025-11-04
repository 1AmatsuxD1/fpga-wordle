--------------------------------------------------------------------------------
-- Serial Receiver: รับข้อมูลแบบ Serial
-- ใช้สำหรับรับคำทาย (40 bits) และผลลัพธ์ (15 bits)
-- Clock: 20 MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_receiver is
    Generic (
        DATA_WIDTH : integer := 40  -- ความกว้างข้อมูล (bits)
    );
    Port (
        clk         : in  std_logic;  -- 20 MHz
        rst         : in  std_logic;
        
        -- Serial Input
        serial_data : in  std_logic;  -- ข้อมูล serial
        serial_clk  : in  std_logic;  -- clock จาก transmitter
   
             
        -- Parallel Output
        data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        data_ready  : out std_logic;  -- ข้อมูลพร้อม
        busy        : out std_logic   -- กำลังรับอยู่
    );
end serial_receiver;

architecture Behavioral of serial_receiver is
    
    type state_type is (IDLE, RECEIVE, FINISH);
    signal state : state_type;
    
    signal shift_reg   : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal bit_counter : integer range 0 to DATA_WIDTH;

    -- Synchronizer สำหรับ serial_clk และ serial_data
    signal serial_clk_sync  : std_logic_vector(2 downto 0);
    signal serial_data_sync : std_logic_vector(2 downto 0);
    signal serial_clk_rise  : std_logic;

begin
    
    -- Synchronizer: ป้องกัน metastability
    process(clk)
    begin
        if rising_edge(clk) then
            serial_clk_sync  <= serial_clk_sync(1 downto 0) & serial_clk;
            serial_data_sync <= serial_data_sync(1 downto 0) & serial_data;
        end if;
    end process;

    -- ตรวจจับ rising edge ของ serial_clk
    serial_clk_rise <= '1' when serial_clk_sync(2 downto 1) = "01" else '0';

    -- Main FSM
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state       <= IDLE;
                shift_reg   <= (others => '0');
                bit_counter <= 0;
                data_out    <= (others => '0');
                data_ready  <= '0';
                busy        <= '0';
            else
                data_ready <= '0'; -- Pulse signal
                
                case state is
                    when IDLE =>
                        busy <= '0';
                        
                        -- [FIX] ตรวจจับเมื่อ serial_clk เริ่มทำงาน
                        if serial_clk_rise = '1' then
                            -- "รับบิตแรก (MSB) ทันที" ที่เจอขอบขาขึ้นครั้งแรก
                            shift_reg   <= shift_reg(DATA_WIDTH-2 downto 0) & serial_data_sync(2); 
                            bit_counter <= 1;  -- เริ่มนับเป็น 1 (เพราะได้มาแล้ว 1 บิต)
                            state       <= RECEIVE;
                            busy        <= '1';
                        end if;
                    
                    when RECEIVE =>
                        busy <= '1';
                        
                        -- รับข้อมูลที่ rising edge ของ serial_clk (บิตที่ 2 ถึง DATA_WIDTH)
                        if serial_clk_rise = '1' then
                            -- รับ MSB first
                            shift_reg <= shift_reg(DATA_WIDTH-2 downto 0) & serial_data_sync(2);
                            bit_counter <= bit_counter + 1;
                            
                            if bit_counter = DATA_WIDTH-1 then
                                state <= FINISH;
                            end if;
                        end if;
                    
                    when FINISH =>
                        data_out   <= shift_reg;
                        data_ready <= '1';
                        busy       <= '0';
                        state      <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
end Behavioral;