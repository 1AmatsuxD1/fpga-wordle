--------------------------------------------------------------------------------
-- VGA Test - Positive Sync (บางจอต้องการ active HIGH)
-- เหมือน vga_test_full แต่ sync เป็น positive
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity vga_test_possync is
    Port (
        clk       : in  std_logic;
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic;
        led_locked: out std_logic
    );
end vga_test_possync;

architecture Behavioral of vga_test_possync is
    -- (คัดลอกทุกอย่างจาก vga_test_full)
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
    
    signal clkfb, clk0, clkfx, clk_50, clk_25 : std_logic;
    signal clk_divider, dcm_locked : std_logic := '0';
    signal h_counter, v_counter : unsigned(9 downto 0) := (others => '0');
    signal video_on, h_sync_i, v_sync_i : std_logic;
    
begin
    
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
    
    process(clk_50) begin
        if rising_edge(clk_50) then
            clk_divider <= not clk_divider;
        end if;
    end process;
    
    BUFG_25 : BUFG port map (I => clk_divider, O => clk_25);
    led_locked <= dcm_locked;
    
    process(clk_25) begin
        if rising_edge(clk_25) then
            if h_counter = H_TOTAL - 1 then
                h_counter <= (others => '0');
            else
                h_counter <= h_counter + 1;
            end if;
        end if;
    end process;
    
    process(clk_25) begin
        if rising_edge(clk_25) then
            if h_counter = H_TOTAL - 1 then
                if v_counter = V_TOTAL - 1 then
                    v_counter <= (others => '0');
                else
                    v_counter <= v_counter + 1;
                end if;
            end if;
        end if;
    end process;
    
    -- POSITIVE Sync (active HIGH)
    h_sync_i <= '1' when (h_counter >= (H_DISPLAY + H_FRONT) and 
                          h_counter < (H_DISPLAY + H_FRONT + H_SYNC)) 
                else '0';
    
    v_sync_i <= '1' when (v_counter >= (V_DISPLAY + V_FRONT) and 
                          v_counter < (V_DISPLAY + V_FRONT + V_SYNC)) 
                else '0';
    
    video_on <= '1' when (h_counter < H_DISPLAY and v_counter < V_DISPLAY) else '0';
    
    vga_hsync <= h_sync_i;
    vga_vsync <= v_sync_i;
    
    process(clk_25) begin
        if rising_edge(clk_25) then
            if video_on = '1' then
                if h_counter < 213 then
                    vga_r <= '1'; vga_g <= '0'; vga_b <= '0';
                elsif h_counter < 426 then
                    vga_r <= '0'; vga_g <= '1'; vga_b <= '0';
                else
                    vga_r <= '0'; vga_g <= '0'; vga_b <= '1';
                end if;
            else
                vga_r <= '0'; vga_g <= '0'; vga_b <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;
