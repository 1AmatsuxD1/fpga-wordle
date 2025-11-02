library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_controller is
    Port (
        clk      : in  std_logic;  -- 25 MHz pixel clock
        rst      : in  std_logic;
        h_sync   : out std_logic;
        v_sync   : out std_logic;
        pixel_x  : out unsigned(9 downto 0);
        pixel_y  : out unsigned(9 downto 0);
        video_on : out std_logic
    );
end vga_controller;

architecture Behavioral of vga_controller is
    
    constant H_DISPLAY : integer := 640;
    constant H_FRONT   : integer := 16;
    constant H_SYNC_WIDTH : integer := 96;
    constant H_BACK    : integer := 48;
    constant H_TOTAL   : integer := 800;
    
    constant V_DISPLAY : integer := 480;
    constant V_FRONT   : integer := 10;
    constant V_SYNC_WIDTH : integer := 2;
    constant V_BACK    : integer := 33;
    constant V_TOTAL   : integer := 525;
    
    signal h_counter   : unsigned(9 downto 0) := (others => '0');
    signal v_counter   : unsigned(9 downto 0) := (others => '0');
    signal video_on_i  : std_logic;
    signal h_sync_i    : std_logic;
    signal v_sync_i    : std_logic;
    
begin
    
    -- Horizontal counter (uses 25 MHz pixel clock directly)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
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
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
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
    
    h_sync_i <= '0' when (h_counter >= (H_DISPLAY + H_FRONT) and h_counter < (H_DISPLAY + H_FRONT + H_SYNC_WIDTH)) else '1';
    
    v_sync_i <= '0' when (v_counter >= (V_DISPLAY + V_FRONT) and v_counter < (V_DISPLAY + V_FRONT + V_SYNC_WIDTH)) else '1';
    
    video_on_i <= '1' when (h_counter < H_DISPLAY and v_counter < V_DISPLAY) else '0';
    
    h_sync   <= h_sync_i;
    v_sync   <= v_sync_i;
    video_on <= video_on_i;
    pixel_x  <= h_counter when video_on_i = '1' else (others => '0');
    pixel_y  <= v_counter when video_on_i = '1' else (others => '0');
    
end Behavioral;