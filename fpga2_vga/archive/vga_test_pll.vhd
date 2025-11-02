--------------------------------------------------------------------------------
-- VGA Test with DCM - Alternative (ใช้ PLL แทน DCM)
-- สำหรับกรณี DCM ไม่ทำงาน
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity vga_test_pll is
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
end vga_test_pll;

architecture Behavioral of vga_test_pll is
    
    signal clkfbout : std_logic;
    signal clkfbin  : std_logic;
    signal clk_25_unbuf : std_logic;
    signal clk_25   : std_logic;
    signal pll_locked : std_logic;
    signal counter  : unsigned(25 downto 0) := (others => '0');
    
begin
    
    -- PLL_BASE: Base Phase Locked Loop for Spartan-6
    PLL_BASE_inst : PLL_BASE
    generic map (
        BANDWIDTH          => "OPTIMIZED",
        CLK_FEEDBACK       => "CLKFBOUT",
        COMPENSATION       => "INTERNAL",
        DIVCLK_DIVIDE      => 1,
        CLKFBOUT_MULT      => 25,       -- 20 * 25 = 500 MHz VCO
        CLKFBOUT_PHASE     => 0.0,
        CLKOUT0_DIVIDE     => 20,       -- 500/20 = 25 MHz
        CLKOUT0_PHASE      => 0.0,
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKIN_PERIOD       => 50.0,     -- 20 MHz input
        REF_JITTER         => 0.010
    )
    port map (
        CLKFBOUT => clkfbout,
        CLKFBIN  => clkfbin,
        CLKIN    => clk,
        CLKOUT0  => clk_25_unbuf,
        LOCKED   => pll_locked,
        RST      => rst
    );
    
    -- Feedback buffer
    BUFG_FB : BUFG
    port map (
        I => clkfbout,
        O => clkfbin
    );
    
    -- Output buffer
    BUFG_25 : BUFG
    port map (
        I => clk_25_unbuf,
        O => clk_25
    );
    
    led_locked <= pll_locked;
    
    vga_hsync <= '1';
    vga_vsync <= '1';
    
    process(clk_25)
    begin
        if rising_edge(clk_25) then
            if rst = '1' or pll_locked = '0' then
                counter <= (others => '0');
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;
    
    vga_r <= counter(23) when pll_locked = '1' else '0';
    vga_g <= counter(24) when pll_locked = '1' else '0';
    vga_b <= counter(25) when pll_locked = '1' else '0';
    
end Behavioral;
