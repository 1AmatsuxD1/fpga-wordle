--------------------------------------------------------------------------------
-- FPGA2 Standalone Test - ทดสอบจอและคีย์บอร์ดโดยไม่ต้องการ FPGA1
-- แสดงตารางและให้พิมพ์ตัวอักษรได้ แต่ไม่มีการตรวจสอบคำ
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga2_standalone_test is
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
        led_locked  : out std_logic
    );
end fpga2_standalone_test;

architecture Behavioral of fpga2_standalone_test is
    
    component clock_generator_pll is
        Port (
            clk_in  : in  std_logic;
            rst     : in  std_logic;
            clk_50  : out std_logic;
            clk_25  : out std_logic;
            locked  : out std_logic
        );
    end component;
    
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
    
    signal clk_50, clk_25, clk_locked : std_logic;
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
    
    -- Test: กำหนดสีสำหรับแต่ละแถว (เพื่อทดสอบการแสดงผล)
    constant TEST_GAME_STATUS : std_logic_vector(2 downto 0) := "000";  -- Playing
    
begin
    
    clk_gen_inst: clock_generator_pll port map (clk, rst, clk_50, clk_25, clk_locked);
    led_locked <= clk_locked;
    
    keyboard_inst: ps2_keyboard port map (clk, rst, ps2_clk, ps2_data, ascii_code, key_valid, key_enter, key_backspace);
    
    vga_inst: vga_controller port map (clk_25, rst, vga_hsync, vga_vsync, pixel_x, pixel_y, video_on);
    
    renderer_inst: display_renderer port map (clk_25, rst, pixel_x, pixel_y, video_on, game_grid_flat, current_row, current_col, TEST_GAME_STATUS, rgb_signal);
    
    vga_r <= rgb_signal(2);
    vga_g <= rgb_signal(1);
    vga_b <= rgb_signal(0);
    
    -- Keyboard input handler
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_row <= (others => '0');
                current_col <= (others => '0');
                for row in 0 to 5 loop
                    for col in 0 to 4 loop
                        game_grid(row)(col).letter <= x"00";
                        game_grid(row)(col).color <= "000";
                    end loop;
                end loop;
            else
                if key_valid = '1' then
                    if ascii_code >= x"41" and ascii_code <= x"5A" then  -- A-Z
                        if current_col < 5 then
                            game_grid(to_integer(current_row))(to_integer(current_col)).letter <= ascii_code;
                            game_grid(to_integer(current_row))(to_integer(current_col)).color <= "000";  -- Gray
                            current_col <= current_col + 1;
                        end if;
                    end if;
                elsif key_backspace = '1' then
                    if current_col > 0 then
                        current_col <= current_col - 1;
                        game_grid(to_integer(current_row))(to_integer(current_col - 1)).letter <= x"00";
                    end if;
                elsif key_enter = '1' then
                    if current_col = 5 and current_row < 6 then
                        -- เปลี่ยนสีทดสอบ: แถบละสีต่างกัน
                        for col in 0 to 4 loop
                            if col = 0 or col = 4 then
                                game_grid(to_integer(current_row))(col).color <= "010";  -- Green
                            elsif col = 1 or col = 3 then
                                game_grid(to_integer(current_row))(col).color <= "001";  -- Yellow
                            else
                                game_grid(to_integer(current_row))(col).color <= "000";  -- Gray
                            end if;
                        end loop;
                        current_row <= current_row + 1;
                        current_col <= (others => '0');
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Flatten grid
    process(game_grid)
    begin
        for row in 0 to 5 loop
            for col in 0 to 4 loop
                game_grid_flat((row*5+col)*11+10 downto (row*5+col)*11+3) <= game_grid(row)(col).letter;
                game_grid_flat((row*5+col)*11+2 downto (row*5+col)*11) <= game_grid(row)(col).color;
            end loop;
        end loop;
    end process;
    
end Behavioral;
