--------------------------------------------------------------------------------
-- VGA Test with DCM - ทดสอบ DCM + แสดงสีกระพริบ
-- ใช้ DCM สร้าง 50MHz และ 25MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity vga_test_dcm is
    Port (
        clk       : in  std_logic;  -- 20 MHz
        rst       : in  std_logic;
        vga_hsync : out std_logic;
        vga_vsync : out std_logic;
        vga_r     : out std_logic;
        vga_g     : out std_logic;
        vga_b     : out std_logic;
        led_locked: out std_logic   -- LED แสดงว่า DCM lock แล้ว
    );
end vga_test_dcm;

architecture Behavioral of vga_test_dcm is
    
    -- DCM signals
    signal clkfb        : std_logic;
    signal clk0         : std_logic;
    signal clkfx        : std_logic;  -- 50 MHz
    signal clk_50       : std_logic;
    signal clk_25_unbuf : std_logic;
    signal clk_25       : std_logic;  -- 25 MHz for VGA
    signal dcm_locked   : std_logic;
    signal clk_divider  : std_logic := '0';
    
    -- Counter for color animation
    signal counter : unsigned(25 downto 0) := (others => '0');
    
begin
    
    -- DCM_SP: Digital Clock Manager
    DCM_SP_inst : DCM_SP
    generic map (
        CLKDV_DIVIDE          => 2.0,
        CLKFX_DIVIDE          => 2,         -- Divide by 2
        CLKFX_MULTIPLY        => 5,         -- Multiply by 5 (20MHz * 5/2 = 50MHz)
        CLKIN_DIVIDE_BY_2     => FALSE,
        CLKIN_PERIOD          => 50.0,      -- 20 MHz = 50ns
        CLKOUT_PHASE_SHIFT    => "NONE",
        CLK_FEEDBACK          => "1X",
        DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
        PHASE_SHIFT           => 0,
        STARTUP_WAIT          => TRUE       -- Wait for DCM to lock
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
        CLKFX    => clkfx,      -- 50 MHz
        LOCKED   => dcm_locked,
        STATUS   => open
    );
    
    -- Feedback buffer
    BUFG_FB : BUFG
    port map (
        I => clk0,
        O => clkfb
    );
    
    -- 50 MHz buffer
    BUFG_50 : BUFG
    port map (
        I => clkfx,
        O => clk_50
    );
    
    -- Divide 50 MHz by 2 to get 25 MHz
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
    
    clk_25_unbuf <= clk_divider;
    
    -- 25 MHz buffer
    BUFG_25 : BUFG
    port map (
        I => clk_25_unbuf,
        O => clk_25
    );
    
    -- LED shows DCM is locked
    led_locked <= dcm_locked;
    
    -- Sync signals: HIGH for now (will fix later)
    vga_hsync <= '1';
    vga_vsync <= '1';
    
    -- Color animation using 25 MHz clock
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if rst = '1' or dcm_locked = '0' then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    -- RGB output - กระพริบสีช้าๆ
    -- ถ้า DCM ทำงาน จะเห็นสีเปลี่ยนเร็วกว่าตอนใช้ 20MHz
    vga_r <= counter(23) when dcm_locked = '1' else '0';
    vga_g <= counter(24) when dcm_locked = '1' else '0';
    vga_b <= counter(25) when dcm_locked = '1' else '0';
    
end Behavioral;
