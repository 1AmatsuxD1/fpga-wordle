--------------------------------------------------------------------------------
-- VGA Test Pattern - แสดงสีเต็มจอเพื่อทดสอบ VGA พร้อม DCM
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_test_simple is
    Port (
        clk       : in  std_logic;  -- 20 MHz
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic
    );
end vga_test_simple;

architecture Behavioral of vga_test_simple is
    
    component clock_generator is
        Port (
            clk_in  : in  std_logic;
            rst     : in  std_logic;
            clk_50  : out std_logic;
            clk_25  : out std_logic;
            locked  : out std_logic
        );
    end component;
    
    component vga_controller is
        Port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            h_sync   : out std_logic;
            v_sync   : out std_logic;
            pixel_x  : out unsigned(9 downto 0);
            pixel_y  : out unsigned(9 downto 0);
            video_on : out std_logic
        );
    end component;
    
    signal clk_50    : std_logic;
    signal clk_25    : std_logic;
    signal clk_locked: std_logic;
    signal pixel_x   : unsigned(9 downto 0);
    signal pixel_y   : unsigned(9 downto 0);
    signal video_on  : std_logic;
    signal rgb       : std_logic_vector(2 downto 0);
    
begin
    
    -- Clock Generator
    clk_gen: clock_generator
        port map (
            clk_in => clk,
            rst    => rst,
            clk_50 => clk_50,
            clk_25 => clk_25,
            locked => clk_locked
        );
    
    -- VGA Controller
    vga_ctrl: vga_controller
        port map (
            clk      => clk_25,
            rst      => rst,
            h_sync   => vga_hsync,
            v_sync   => vga_vsync,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y,
            video_on => video_on
        );
    
    -- Simple color pattern based on position
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if video_on = '1' then
                -- Create color bars
                if pixel_x < 213 then
                    rgb <= "100";  -- Red
                elsif pixel_x < 426 then
                    rgb <= "010";  -- Green
                else
                    rgb <= "001";  -- Blue
                end if;
            else
                rgb <= "000";  -- Black during blanking
            end if;
        end if;
    end process;
    
    vga_r <= rgb(2);
    vga_g <= rgb(1);
    vga_b <= rgb(0);
    
end Behavioral;
