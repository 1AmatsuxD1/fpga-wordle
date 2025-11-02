--------------------------------------------------------------------------------
-- Testbench: Serial Communication
-- ทดสอบการส่ง-รับข้อมูล Serial ระหว่าง 2 บอร์ด
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity serial_communication_tb is
end serial_communication_tb;

architecture Behavioral of serial_communication_tb is
    
    component serial_transmitter is
        Generic (DATA_WIDTH : integer := 40);
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
    end component;
    
    component serial_receiver is
        Generic (DATA_WIDTH : integer := 40);
        Port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            serial_data : in  std_logic;
            serial_clk  : in  std_logic;
            data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
            data_ready  : out std_logic;
            busy        : out std_logic
        );
    end component;
    
    constant CLK_PERIOD : time := 50 ns;  -- 20 MHz
    
    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    
    -- TX signals
    signal tx_data_in   : std_logic_vector(39 downto 0);
    signal tx_start     : std_logic := '0';
    signal serial_data  : std_logic;
    signal serial_clk   : std_logic;
    signal tx_busy      : std_logic;
    signal tx_done      : std_logic;
    
    -- RX signals
    signal rx_data_out  : std_logic_vector(39 downto 0);
    signal rx_ready     : std_logic;
    signal rx_busy      : std_logic;
    
begin
    
    -- Clock generation
    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
    
    -- Transmitter
    tx_inst: serial_transmitter
        generic map (DATA_WIDTH => 40)
        port map (
            clk         => clk,
            rst         => rst,
            data_in     => tx_data_in,
            send_start  => tx_start,
            serial_data => serial_data,
            serial_clk  => serial_clk,
            busy        => tx_busy,
            done        => tx_done
        );
    
    -- Receiver
    rx_inst: serial_receiver
        generic map (DATA_WIDTH => 40)
        port map (
            clk         => clk,
            rst         => rst,
            serial_data => serial_data,
            serial_clk  => serial_clk,
            data_out    => rx_data_out,
            data_ready  => rx_ready,
            busy        => rx_busy
        );
    
    -- Test stimulus
    stim_process: process
    begin
        -- Reset
        rst <= '1';
        wait for 200 ns;
        rst <= '0';
        wait for 100 ns;
        
        -- Test 1: ส่ง "HELLO" = 0x48454C4C4F
        report "Test 1: Sending HELLO";
        tx_data_in <= x"48454C4C4F";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        wait until tx_done = '1';
        wait for 1 us;
        
        -- ตรวจสอบผลลัพธ์
        assert rx_ready = '1' report "RX should be ready" severity error;
        assert rx_data_out = x"48454C4C4F" 
            report "Data mismatch! Expected: 48454C4C4F, Got: " & 
                   integer'image(to_integer(unsigned(rx_data_out)))
            severity error;
        
        report "Test 1 PASSED: HELLO received correctly";
        wait for 1 us;
        
        -- Test 2: ส่ง "WORLD" = 0x574F524C44
        report "Test 2: Sending WORLD";
        tx_data_in <= x"574F524C44";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        wait until tx_done = '1';
        wait for 1 us;
        
        assert rx_data_out = x"574F524C44"
            report "Test 2 FAILED" severity error;
        
        report "Test 2 PASSED: WORLD received correctly";
        wait for 1 us;
        
        -- Test 3: ส่งข้อมูล random
        report "Test 3: Sending random data";
        tx_data_in <= x"DEADBEEF12";
        tx_start <= '1';
        wait for CLK_PERIOD;
        tx_start <= '0';
        
        wait until tx_done = '1';
        wait for 1 us;
        
        assert rx_data_out = x"DEADBEEF12"
            report "Test 3 FAILED" severity error;
        
        report "Test 3 PASSED: Random data received correctly";
        
        report "========================================";
        report "ALL TESTS PASSED!";
        report "========================================";
        
        wait;
    end process;
    
end Behavioral;