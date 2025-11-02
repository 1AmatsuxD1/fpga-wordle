--------------------------------------------------------------------------------
-- VGA Test with Proper Timing - 640x480@60Hz
-- ใช้ DCM + VGA timing ที่ถูกต้อง
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity vga_test_full is
    Port (
        clk       : in  std_logic;  -- 20 MHz
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic;
        led_locked: out std_logic
    );
end vga_test_full;

architecture Behavioral of vga_test_full is
    
    -- VGA 640x480 @ 60Hz timing parameters
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
    signal clkfb        : std_logic;
    signal clk0         : std_logic;
    signal clkfx        : std_logic;
    signal clk_50       : std_logic;
    signal clk_25_unbuf : std_logic;
    signal clk_25       : std_logic;
    signal dcm_locked   : std_logic;
    signal clk_divider  : std_logic := '0';
    
    -- VGA signals
    signal h_counter : unsigned(9 downto 0) := (others => '0');
    signal v_counter : unsigned(9 downto 0) := (others => '0');
    signal video_on  : std_logic;
    signal h_sync_i  : std_logic;
    signal v_sync_i  : std_logic;
    
begin
    
    -- DCM_SP: Generate 50 MHz
    DCM_SP_inst : DCM_SP
    generic map (
        CLKDV_DIVIDE          => 2.0,
        CLKFX_DIVIDE          => 2,
        CLKFX_MULTIPLY        => 5,
        CLKIN_DIVIDE_BY_2     => FALSE,
        CLKIN_PERIOD          => 50.0,
        CLKOUT_PHASE_SHIFT    => "NONE",
        CLK_FEEDBACK          => "1X",
        DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
        PHASE_SHIFT           => 0,
        STARTUP_WAIT          => TRUE
    )
    port map (
        CLKIN    => clk,
        CLKFB    => clkfb,
        RST      => rst,
        PSEN     => '0',
        DSSEN    => '0',
        PSCLK    => '0',
        PSINCDEC => '0',
        CLK0     => clk0,
        CLKFX    => clkfx,
        LOCKED   => dcm_locked,
        STATUS   => open
    );
    
    BUFG_FB : BUFG port map (I => clk0, O => clkfb);
    BUFG_50 : BUFG port map (I => clkfx, O => clk_50);
    
    -- Divide 50 MHz by 2 = 25 MHz
    process(clk_50)
    begin
        if rising_edge(clk_50) then
            if rst = '1' then
                clk_divider <= '0';
            else
                clk_divider <= not clk_divider;
            end if;
        end if;
    end process;
    
    BUFG_25 : BUFG port map (I => clk_divider, O => clk_25);
    
    led_locked <= dcm_locked;
    
    -- Horizontal counter
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
    
    -- Vertical counter
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
    
    -- H-Sync: Active LOW during sync period
    h_sync_i <= '0' when (h_counter >= (H_DISPLAY + H_FRONT) and 
                          h_counter < (H_DISPLAY + H_FRONT + H_SYNC)) 
                else '1';
    
    -- V-Sync: Active LOW during sync period
    v_sync_i <= '0' when (v_counter >= (V_DISPLAY + V_FRONT) and 
                          v_counter < (V_DISPLAY + V_FRONT + V_SYNC)) 
                else '1';
    
    -- Video ON during display area
    video_on <= '1' when (h_counter < H_DISPLAY and v_counter < V_DISPLAY) 
                else '0';
    
    -- Output sync signals
    vga_hsync <= h_sync_i;
    vga_vsync <= v_sync_i;
    
    -- Display test pattern: Color bars
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if video_on = '1' and dcm_locked = '1' then
                -- Vertical color bars
                if h_counter < 213 then
                    vga_r <= '1'; vga_g <= '0'; vga_b <= '0';  -- Red
                elsif h_counter < 426 then
                    vga_r <= '0'; vga_g <= '1'; vga_b <= '0';  -- Green
                else
                    vga_r <= '0'; vga_g <= '0'; vga_b <= '1';  -- Blue
                end if;
            else
                -- Black during blanking
                vga_r <= '0';
                vga_g <= '0';
                vga_b <= '0';
            end if;
        end if;
    end process;
    
end Behavioral;
