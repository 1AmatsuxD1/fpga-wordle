--------------------------------------------------------------------------------
-- Clock Generator: 20 MHz → 50 MHz using DCM
-- For Spartan-6 XC6SLX9
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity clock_generator is
    Port (
        clk_in  : in  std_logic;   -- 20 MHz input
        rst     : in  std_logic;
        clk_50  : out std_logic;   -- 50 MHz output
        clk_25  : out std_logic;   -- 25 MHz output (for VGA)
        locked  : out std_logic    -- DCM locked signal
    );
end clock_generator;

architecture Behavioral of clock_generator is
    signal clkfb        : std_logic;
    signal clk0         : std_logic;
    signal clk_50_i     : std_logic;
    signal clk_50_buf   : std_logic;
    signal clk_25_i     : std_logic;
    signal clk_divider  : std_logic := '0';
begin
    
    -- DCM_SP: Digital Clock Manager
    -- Spartan-6
    DCM_SP_inst : DCM_SP
    generic map (
        CLKDV_DIVIDE          => 2.0,       -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0,16.0
        CLKFX_DIVIDE          => 2,         -- Divide by 2
        CLKFX_MULTIPLY        => 5,         -- Multiply by 5 (20MHz * 5/2 = 50MHz)
        CLKIN_DIVIDE_BY_2     => FALSE,
        CLKIN_PERIOD          => 50.0,      -- 20 MHz = 50ns period
        CLKOUT_PHASE_SHIFT    => "NONE",
        CLK_FEEDBACK          => "1X",
        DESKEW_ADJUST         => "SYSTEM_SYNCHRONOUS",
        PHASE_SHIFT           => 0,
        STARTUP_WAIT          => TRUE
    )
    port map (
        CLKIN    => clk_in,
        CLKFB    => clkfb,
        RST      => rst,
        PSEN     => '0',
        DSSEN    => '0',
        PSCLK    => '0',
        PSINCDEC => '0',
        CLK0     => clk0,      -- Same as input (20 MHz)
        CLKFX    => clk_50_i,  -- 50 MHz output
        LOCKED   => locked,
        STATUS   => open
    );
    
    -- Feedback buffer
    BUFG_FB_inst : BUFG
    port map (
        I => clk0,
        O => clkfb
    );
    
    -- 50 MHz buffer
    BUFG_50_inst : BUFG
    port map (
        I => clk_50_i,
        O => clk_50_buf
    );
    
    clk_50 <= clk_50_buf;
    
    -- Divide 50 MHz by 2 to get 25 MHz for VGA pixel clock
    process(clk_50_buf)
    begin
        if rising_edge(clk_50_buf) then
            if rst = '1' then
                clk_divider <= '0';
            else
                clk_divider <= not clk_divider;
            end if;
        end if;
    end process;
    
    clk_25_i <= clk_divider;
    
    -- Buffer output clock
    BUFG_25_inst : BUFG
    port map (
        I => clk_25_i,
        O => clk_25
    );
    
end Behavioral;
