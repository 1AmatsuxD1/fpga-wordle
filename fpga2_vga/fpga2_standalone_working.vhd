--------------------------------------------------------------------------------
-- FPGA2 Standalone Working - ใช้ PLL + VGA timing ที่ถูกต้อง
-- ตามแบบ vga_test_full.vhd ที่ทำงานได้
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity fpga2_standalone_working is
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
end fpga2_standalone_working;

architecture Behavioral of fpga2_standalone_working is
    
    -- VGA timing (เหมือน vga_test_full.vhd)
    constant H_DISPLAY : integer := 640;
    constant H_FRONT   : integer := 16;
    constant H_SYNC    : integer := 96;
    constant H_BACK    : integer := 48;
    constant H_TOTAL   : integer := 800;
    constant V_DISPLAY : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC    : integer := 2;
    constant V_BACK    : integer := 33;
    constant V_TOTAL   : integer := 525;
    
    -- DCM signals
    signal clkfb, clk0, clkfx, clk_50, clk_25 : std_logic;
    signal clk_divider, dcm_locked : std_logic := '0';
    
    -- VGA signals
    signal h_counter, v_counter : unsigned(9 downto 0) := (others => '0');
    signal video_on, h_sync_i, v_sync_i : std_logic;
    
    -- Keyboard
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
    
    -- Display Renderer
    component display_renderer is
        Port (
            pixel_clk   : in  std_logic;
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
    
    signal ascii_code : std_logic_vector(7 downto 0);
    signal key_valid, key_enter, key_backspace : std_logic;
    signal rst_i : std_logic;
    
    -- Game grid
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
    signal rgb_signal : std_logic_vector(2 downto 0);
    constant TEST_GAME_STATUS : std_logic_vector(2 downto 0) := "000";
    
begin
    
    -- DCM (เหมือน vga_test_full.vhd)
    DCM_SP_inst : DCM_SP
    generic map (
        CLKFX_DIVIDE => 2, CLKFX_MULTIPLY => 5, CLKIN_DIVIDE_BY_2 => FALSE,
        CLKIN_PERIOD => 50.0, CLK_FEEDBACK => "1X", STARTUP_WAIT => TRUE
    )
    port map (
        CLKIN => clk, CLKFB => clkfb, RST => rst, PSEN => '0',
        CLK0 => clk0, CLKFX => clkfx, LOCKED => dcm_locked
    );
    
    BUFG_FB : BUFG port map (I => clk0, O => clkfb);
    BUFG_50 : BUFG port map (I => clkfx, O => clk_50);
    
    process(clk_50)
    begin
        if rising_edge(clk_50) then
            clk_divider <= not clk_divider;
        end if;
    end process;
    
    BUFG_25 : BUFG port map (I => clk_divider, O => clk_25);
    led_locked <= dcm_locked;
    
    -- Reset signal
    rst_i <= rst or not dcm_locked;
    
    -- VGA timing (เหมือน vga_test_full.vhd)
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if rst = '1' or dcm_locked = '0' then
                h_counter <= (others => '0');
            else
                if h_counter = H_TOTAL - 1 then
                    h_counter <= (others => '0');
                else
                    h_counter <= h_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if rst = '1' or dcm_locked = '0' then
                v_counter <= (others => '0');
            else
                if h_counter = H_TOTAL - 1 then
                    if v_counter = V_TOTAL - 1 then
                        v_counter <= (others => '0');
                    else
                        v_counter <= v_counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;
    
    -- Sync signals
    h_sync_i <= '0' when (h_counter >= (H_DISPLAY + H_FRONT) and 
                          h_counter < (H_DISPLAY + H_FRONT + H_SYNC)) else '1';
    v_sync_i <= '0' when (v_counter >= (V_DISPLAY + V_FRONT) and 
                          v_counter < (V_DISPLAY + V_FRONT + V_SYNC)) else '1';
    video_on <= '1' when (h_counter < H_DISPLAY and v_counter < V_DISPLAY) else '0';
    
    vga_hsync <= h_sync_i;
    vga_vsync <= v_sync_i;
    
    -- Keyboard
    keyboard_inst: ps2_keyboard 
        port map (clk, rst, ps2_clk, ps2_data, ascii_code, key_valid, key_enter, key_backspace);
    
    -- Keyboard handler
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
                if key_valid = '1' and ascii_code >= x"41" and ascii_code <= x"5A" then
                    if current_col < 5 then
                        game_grid(to_integer(current_row))(to_integer(current_col)).letter <= ascii_code;
                        game_grid(to_integer(current_row))(to_integer(current_col)).color <= "000";
                        current_col <= current_col + 1;
                    end if;
                elsif key_backspace = '1' and current_col > 0 then
                    current_col <= current_col - 1;
                    game_grid(to_integer(current_row))(to_integer(current_col - 1)).letter <= x"00";
                elsif key_enter = '1' and current_col = 5 and current_row < 6 then
                    -- Test colors
                    for col in 0 to 4 loop
                        if col = 0 or col = 4 then
                            game_grid(to_integer(current_row))(col).color <= "010";  -- Green
                        elsif col = 1 or col = 3 then
                            game_grid(to_integer(current_row))(col).color <= "110";  -- Yellow
                        else
                            game_grid(to_integer(current_row))(col).color <= "101";  -- Magenta
                        end if;
                    end loop;
                    current_row <= current_row + 1;
                    current_col <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    -- Flatten game_grid to std_logic_vector
    process(game_grid)
        variable idx : integer;
    begin
        -- Fill with zeros first
        game_grid_flat <= (others => '0');
        -- Pack 30 cells (6 rows × 5 cols)
        idx := 0;
        for row in 0 to 5 loop
            for col in 0 to 4 loop
                game_grid_flat(idx + 10 downto idx) <= game_grid(row)(col).letter & game_grid(row)(col).color;
                idx := idx + 11;
            end loop;
        end loop;
    end process;
    
    -- Instantiate display_renderer
    renderer_inst : display_renderer
    port map (
        pixel_clk => clk_25,
        rst => rst_i,
        pixel_x => h_counter,
        pixel_y => v_counter,
        video_on => video_on,
        game_grid => game_grid_flat,
        current_row => current_row,
        current_col => current_col,
        game_status => TEST_GAME_STATUS,
        rgb => rgb_signal
    );
    
    -- Connect display renderer output to VGA
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if video_on = '1' and dcm_locked = '1' then
                vga_r <= rgb_signal(2);
                vga_g <= rgb_signal(1);
                vga_b <= rgb_signal(0);
            else
                vga_r <= '0';
                vga_g <= '0';
                vga_b <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;
