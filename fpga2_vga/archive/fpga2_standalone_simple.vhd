--------------------------------------------------------------------------------
-- FPGA2 Standalone Test - Simple version (ไม่ใช้ DCM/PLL)
-- ใช้ 20MHz หาร 2 = 10MHz pixel clock (จะไม่ถูก VGA standard แต่อาจทำงาน)
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga2_standalone_simple is
    Port (
        clk         : in  std_logic;  -- 20 MHz
        rst         : in  std_logic;
        ps2_clk     : in  std_logic;
        ps2_data    : in  std_logic;
        vga_hsync   : out std_logic;
        vga_vsync   : out std_logic;
        vga_r       : out std_logic;
        vga_g       : out std_logic;
        vga_b       : out std_logic;
        led_test    : out std_logic  -- LED กระพริบเพื่อทดสอบว่า FPGA ทำงาน
    );
end fpga2_standalone_simple;

architecture Behavioral of fpga2_standalone_simple is
    
    component ps2_keyboard is
        Port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            ps2_clk      : in  std_logic;
            ps2_data     : in  std_logic;
            ascii_code   : out std_logic_vector(7 downto 0);
            key_valid    : out std_logic;
            key_enter    : out std_logic;
            key_backspace: out std_logic
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
    
    component display_renderer is
        Port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            pixel_x     : in  unsigned(9 downto 0);
            pixel_y     : in  unsigned(9 downto 0);
            video_on    : in  std_logic;
            game_grid   : in  std_logic_vector(1079 downto 0);
            current_row : in  unsigned(2 downto 0);
            current_col : in  unsigned(2 downto 0);
            game_status : in  std_logic_vector(2 downto 0);
            rgb         : out std_logic_vector(2 downto 0)
        );
    end component;
    
    signal clk_div : std_logic := '0';
    signal pixel_clk : std_logic;
    signal led_counter : unsigned(25 downto 0) := (others => '0');
    
    signal ascii_code : std_logic_vector(7 downto 0);
    signal key_valid, key_enter, key_backspace : std_logic;
    signal pixel_x, pixel_y : unsigned(9 downto 0);
    signal video_on : std_logic;
    signal rgb_signal : std_logic_vector(2 downto 0);
    
    type grid_cell is record
        letter : std_logic_vector(7 downto 0);
        color  : std_logic_vector(2 downto 0);
    end record;
    type grid_row is array (0 to 4) of grid_cell;
    type grid_type is array (0 to 5) of grid_row;
    signal game_grid : grid_type;
    
    signal current_row : unsigned(2 downto 0) := (others => '0');
    signal current_col : unsigned(2 downto 0) := (others => '0');
    signal game_grid_flat : std_logic_vector(1079 downto 0);
    constant TEST_GAME_STATUS : std_logic_vector(2 downto 0) := "000";
    
begin
    
    -- Simple clock divider: 20 MHz / 2 = 10 MHz
    process(clk)
    begin
        if rising_edge(clk) then
            clk_div <= not clk_div;
        end if;
    end process;
    
    pixel_clk <= clk_div;
    
    -- LED test - กระพริบทุก 0.4 วินาที
    process(clk)
    begin
        if rising_edge(clk) then
            led_counter <= led_counter + 1;
        end if;
    end process;
    led_test <= led_counter(23);
    
    -- ทดสอบ: ส่ง VGA แบบง่ายที่สุด
    -- Sync = HIGH, RGB = กระพริบตาม LED counter
    vga_hsync <= '1';  -- Positive sync
    vga_vsync <= '1';
    
    vga_r <= led_counter(23);  -- กระพริบตาม LED
    vga_g <= led_counter(24);
    vga_b <= led_counter(25);
    
    -- Comment out keyboard and VGA controller ก่อน
    -- keyboard_inst: ps2_keyboard 
    --     port map (clk, rst, ps2_clk, ps2_data, ascii_code, key_valid, key_enter, key_backspace);
    -- 
    -- vga_inst: vga_controller 
    --     port map (pixel_clk, rst, vga_hsync, vga_vsync, pixel_x, pixel_y, video_on);
    -- 
    -- renderer_inst: display_renderer 
    --     port map (pixel_clk, rst, pixel_x, pixel_y, video_on, game_grid_flat, 
    --           current_row, current_col, TEST_GAME_STATUS, rgb_signal);
    -- 
    -- vga_r <= rgb_signal(2);
    -- vga_g <= rgb_signal(1);
    -- vga_b <= rgb_signal(0);
    
    -- Keyboard handler (comment out ก่อน)
    -- process(clk)
    -- begin
    --     if rising_edge(clk) then
    --         if rst = '1' then
    --             current_row <= (others => '0');
    --             current_col <= (others => '0');
    --             for row in 0 to 5 loop
    --                 for col in 0 to 4 loop
    --                     game_grid(row)(col).letter <= x"00";
    --                     game_grid(row)(col).color <= "000";
    --                 end loop;
    --             end loop;
    --         end if;
    --     end if;
    -- end process;
    
end Behavioral;
