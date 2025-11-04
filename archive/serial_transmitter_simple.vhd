--------------------------------------------------------------------------------
-- Serial Transmitter SIMPLE VERSION (for debugging)
-- ส่ง clock ตลอดเวลา เพื่อทดสอบว่า hardware ทำงานหรือไม่
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_transmitter is
    Generic (
        DATA_WIDTH : integer := 40
    );
    Port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        data_in     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        send_start  : in  std_logic;
        serial_data : out std_logic;
        serial_clk  : out std_logic;
        busy        : out std_logic;
        done        : out std_logic
    );
end serial_transmitter;

architecture Behavioral of serial_transmitter is
    
    type state_type is (IDLE, TRANSMIT, FINISH);
    signal state : state_type := IDLE;
    
    signal shift_reg   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal bit_counter : integer range 0 to DATA_WIDTH := 0;
    signal clk_divider : unsigned(2 downto 0) := (others => '0');
    signal serial_clk_i : std_logic := '0';
    
begin
    
    -- Clock divider: 20 MHz → 2.5 MHz (หารด้วย 8)
    -- ส่ง clock ตลอดเวลา (ไม่สนใจ state) เพื่อ debug
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_divider <= (others => '0');
                serial_clk_i <= '0';
            else
                clk_divider <= clk_divider + 1;
                if clk_divider = 3 then
                    serial_clk_i <= not serial_clk_i;
                    clk_divider <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    serial_clk <= serial_clk_i;  -- ส่งออกตลอดเวลา
    
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
                case state is
                    when IDLE =>
                        busy <= '0';
                        done <= '0';
                        bit_counter <= 0;
                        
                        if send_start = '1' then
                            shift_reg   <= data_in;
                            state       <= TRANSMIT;
                            busy        <= '1';
                        end if;
                    
                    when TRANSMIT =>
                        busy <= '1';
                        done <= '0';
                        
                        -- ส่งข้อมูลที่ rising edge ของ serial clock
                        if clk_divider = 3 and serial_clk_i = '0' then
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
