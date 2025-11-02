--------------------------------------------------------------------------------
-- VGA Test - Very Simple (ไม่ใช้ DCM, ไม่ใช้ timing)
-- แค่ส่งสัญญาณคงที่เพื่อทดสอบว่าสายต่อถูกหรือไม่
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_test_basic is
    Port (
        clk       : in  std_logic;  -- 20 MHz
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic
    );
end vga_test_basic;

architecture Behavioral of vga_test_basic is
    signal counter : unsigned(25 downto 0) := (others => '0');
begin
    
    -- H-Sync และ V-Sync: HIGH ตลอด (บางจอต้องการ)
    vga_hsync <= '1';
    vga_vsync <= '1';
    
    -- กระพริบสี RGB สลับกันช้าๆ
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    -- เปลี่ยนสีทุก 2^23 clocks (~0.4 วินาที ที่ 20MHz)
    vga_r <= counter(23);
    vga_g <= counter(24);
    vga_b <= counter(25);
    
end Behavioral;
