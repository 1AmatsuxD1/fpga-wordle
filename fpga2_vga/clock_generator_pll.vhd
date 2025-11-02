--------------------------------------------------------------------------------
-- Clock Generator using PLL: 20 MHz → 50 MHz → 25 MHz
-- For Spartan-6 XC6SLX9
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity clock_generator_pll is
    Port (
        clk_in  : in  std_logic;   -- 20 MHz input
        rst     : in  std_logic;
        clk_50  : out std_logic;   -- 50 MHz output
        clk_25  : out std_logic;   -- 25 MHz output (for VGA)
        locked  : out std_logic    -- PLL locked signal
    );
end clock_generator_pll;

architecture Behavioral of clock_generator_pll is
    signal clkfbout     : std_logic;
    signal clkfbin      : std_logic;
    signal clk_50_unbuf : std_logic;
    signal clk_50_buf   : std_logic;
    signal clk_25_unbuf : std_logic;
    signal clk_divider  : std_logic := '0';
    signal pll_locked   : std_logic;
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
        CLKOUT0_DIVIDE     => 10,       -- 500/10 = 50 MHz
        CLKOUT0_PHASE      => 0.0,
        CLKOUT0_DUTY_CYCLE => 0.5,
        CLKIN_PERIOD       => 50.0,     -- 20 MHz input
        REF_JITTER         => 0.010
    )
    port map (
        CLKFBOUT => clkfbout,
        CLKFBIN  => clkfbin,
        CLKIN    => clk_in,
        CLKOUT0  => clk_50_unbuf,
        LOCKED   => pll_locked,
        RST      => rst
    );
    
    -- Feedback buffer
    BUFG_FB : BUFG
    port map (
        I => clkfbout,
        O => clkfbin
    );
    
    -- 50 MHz buffer
    BUFG_50 : BUFG
    port map (
        I => clk_50_unbuf,
        O => clk_50_buf
    );
    
    clk_50 <= clk_50_buf;
    locked <= pll_locked;
    
    -- Divide 50 MHz by 2 to get 25 MHz
    process(clk_50_buf)
    begin
        if rising_edge(clk_50_buf) then
            if rst = '1' or pll_locked = '0' then
                clk_divider <= '0';
            else
                clk_divider <= not clk_divider;
            end if;
        end if;
    end process;
    
    -- 25 MHz buffer
    BUFG_25 : BUFG
    port map (
        I => clk_divider,
        O => clk_25
    );
    
end Behavioral;
