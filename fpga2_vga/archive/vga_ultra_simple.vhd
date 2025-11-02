--------------------------------------------------------------------------------
-- VGA Ultra Simple Test - แค่กระพริบสี
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_ultra_simple is
    Port (
        clk       : in  std_logic;  -- 20 MHz
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic;
        led_test  : out std_logic
    );
end vga_ultra_simple;

architecture Behavioral of vga_ultra_simple is
    signal counter : unsigned(25 downto 0) := (others => '0');
begin
    
    process(clk)
    begin
        if rising_edge(clk) then
            counter <= counter + 1;
        end if;
    end process;
    
    led_test <= counter(23);
    
    -- ทดสอบทั้ง 4 แบบ
    -- แบบ 1: Positive sync
    vga_hsync <= '1';
    vga_vsync <= '1';
    
    -- แบบ 2: Negative sync (uncomment ถ้าแบบ 1 ไม่ได้)
    -- vga_hsync <= '0';
    -- vga_vsync <= '0';
    
    -- แบบ 3: Mixed (uncomment ถ้าแบบ 1-2 ไม่ได้)
    -- vga_hsync <= '1';
    -- vga_vsync <= '0';
    
    -- แบบ 4: Mixed opposite (uncomment ถ้าแบบ 1-3 ไม่ได้)
    -- vga_hsync <= '0';
    -- vga_vsync <= '1';
    
    -- RGB กระพริบ
    vga_r <= counter(23);
    vga_g <= counter(24);
    vga_b <= counter(25);
    
end Behavioral;
