--------------------------------------------------------------------------------
-- FPGA Board #2: Display & Input with 3-bit RGB
-- Clock: 20 MHz
-- VGA: 3-bit RGB (R, G, B - 1 bit each) = 8 colors
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga2_top is
    Port (
        clk         : in  std_logic;  -- 20 MHz
        rst         : in  std_logic;
        
        -- PS/2 Keyboard
        ps2_clk     : in  std_logic;
        ps2_data    : in  std_logic;
        
        -- VGA Display (3-bit RGB)
        vga_hsync   : out std_logic;
        vga_vsync   : out std_logic;
        vga_r       : out std_logic;  -- Red (1 bit)
        vga_g       : out std_logic;  -- Green (1 bit)
        vga_b       : out std_logic;  -- Blue (1 bit)
        
        -- Serial Communication (ไป FPGA #1)
        serial_tx_data : out std_logic;
        serial_tx_clk  : out std_logic;
        data_valid     : out std_logic;
        
        -- Serial Communication (จาก FPGA #1)
        serial_rx_data : in  std_logic;
        serial_rx_clk  : in  std_logic;
        acknowledge    : in  std_logic;
        result_valid   : in  std_logic;
        
        -- Game Status
        game_status : in  std_logic_vector(2 downto 0);
        
        -- Debug LED (optional - shows DCM lock)
        led_locked  : out std_logic
    );
end fpga2_top;

architecture Behavioral of fpga2_top is
    
    -- Components
    component clock_generator is
        Port (
            clk_in  : in  std_logic;
            rst     : in  std_logic;
            clk_50  : out std_logic;
            clk_25  : out std_logic;
            locked  : out std_logic
        );
    end component;
    
    component serial_transmitter is
        Generic (DATA_WIDTH : integer := 40);
        Port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            data_in     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            send_start  : in  std_logic;
            serial_data : out std_logic;
            serial_clk  : out std_logic;
            busy        : out std_logic;
            done        : out std_logic
        );
    end component;
    
    component serial_receiver is
        Generic (DATA_WIDTH : integer := 15);
        Port (
            clk         : in  std_logic;
            rst         : in  std_logic;
            serial_data : in  std_logic;
            serial_clk  : in  std_logic;
            data_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
            data_ready  : out std_logic;
            busy        : out std_logic
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
            rgb         : out std_logic_vector(2 downto 0)  -- 3-bit RGB
        );
    end component;
    
    -- Clock signals
    signal clk_50        : std_logic;
    signal clk_25        : std_logic;  -- VGA pixel clock
    signal clk_locked    : std_logic;
    
    -- Keyboard signals
    signal ascii_code    : std_logic_vector(7 downto 0);
    signal key_valid     : std_logic;
    signal key_enter     : std_logic;
    signal key_backspace : std_logic;
    
    -- VGA signals
    signal pixel_x       : unsigned(9 downto 0);
    signal pixel_y       : unsigned(9 downto 0);
    signal video_on      : std_logic;
    signal rgb_signal    : std_logic_vector(2 downto 0);  -- 3-bit RGB
    
    -- Serial signals
    signal word_to_send    : std_logic_vector(39 downto 0);
    signal tx_send_start   : std_logic;
    signal tx_busy         : std_logic;
    signal tx_done         : std_logic;
    signal result_received : std_logic_vector(14 downto 0);
    signal result_ready    : std_logic;
    signal rx_busy         : std_logic;
    
    -- Game grid
    type grid_cell is record
        letter : std_logic_vector(7 downto 0);
        color  : std_logic_vector(2 downto 0);
    end record;
    
    type grid_row is array (0 to 4) of grid_cell;
    type grid_type is array (0 to 5) of grid_row;
    signal game_grid : grid_type;
    
    signal current_row   : unsigned(2 downto 0) := (others => '0');
    signal current_col   : unsigned(2 downto 0) := (others => '0');
    
    type word_buffer_type is array (0 to 4) of std_logic_vector(7 downto 0);
    signal word_buffer   : word_buffer_type;
    signal buffer_index  : unsigned(2 downto 0);
    
    type control_state_type is (INPUT_LETTERS, WAIT_TX, WAIT_ACKNOWLEDGE, RECEIVE_RESULT, GAME_END);
    signal control_state : control_state_type;
    
    signal game_grid_flat : std_logic_vector(1079 downto 0);
    
begin
    
    -- Clock Generator: 20 MHz → 50 MHz → 25 MHz (for VGA)
    clk_gen_inst: clock_generator
        port map (
            clk_in  => clk,
            rst     => rst,
            clk_50  => clk_50,
            clk_25  => clk_25,
            locked  => clk_locked
        );
    
    -- Serial Transmitter
    word_transmitter: serial_transmitter
        generic map (DATA_WIDTH => 40)
        port map (
            clk         => clk,
            rst         => rst,
            data_in     => word_to_send,
            send_start  => tx_send_start,
            serial_data => serial_tx_data,
            serial_clk  => serial_tx_clk,
            busy        => tx_busy,
            done        => tx_done
        );
    
    -- Serial Receiver
    result_receiver: serial_receiver
        generic map (DATA_WIDTH => 15)
        port map (
            clk         => clk,
            rst         => rst,
            serial_data => serial_rx_data,
            serial_clk  => serial_rx_clk,
            data_out    => result_received,
            data_ready  => result_ready,
            busy        => rx_busy
        );
    
    -- PS/2 Keyboard
    keyboard_inst: ps2_keyboard
        port map (
            clk           => clk,
            rst           => rst,
            ps2_clk       => ps2_clk,
            ps2_data      => ps2_data,
            ascii_code    => ascii_code,
            key_valid     => key_valid,
            key_enter     => key_enter,
            key_backspace => key_backspace
        );
    
    -- VGA Controller (uses 25 MHz pixel clock)
    vga_inst: vga_controller
        port map (
            clk      => clk_25,
            rst      => rst,
            h_sync   => vga_hsync,
            v_sync   => vga_vsync,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y,
            video_on => video_on
        );
    
    -- Display Renderer (3-bit RGB, uses 25 MHz pixel clock)
    renderer_inst: display_renderer
        port map (
            clk         => clk_25,
            rst         => rst,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            video_on    => video_on,
            game_grid   => game_grid_flat,
            current_row => current_row,
            current_col => current_col,
            game_status => game_status,
            rgb         => rgb_signal  -- 3-bit RGB
        );
    
    -- แยก RGB ออกเป็น 3 สาย
    vga_r <= rgb_signal(2);  -- Red bit
    vga_g <= rgb_signal(1);  -- Green bit
    vga_b <= rgb_signal(0);  -- Blue bit
    
    -- Debug: DCM lock LED
    led_locked <= clk_locked;
    
    -- Flatten game grid
    process(game_grid)
    begin
        for row in 0 to 5 loop
            for col in 0 to 4 loop
                game_grid_flat((row*5+col)*11+10 downto (row*5+col)*11+3) <= game_grid(row)(col).letter;
                game_grid_flat((row*5+col)*11+2 downto (row*5+col)*11) <= game_grid(row)(col).color;
            end loop;
        end loop;
    end process;
    
    -- Main control FSM (เหมือนเดิม)
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                control_state <= INPUT_LETTERS;
                current_row   <= (others => '0');
                buffer_index  <= (others => '0');
                data_valid    <= '0';
                tx_send_start <= '0';
                
                for row in 0 to 5 loop
                    for col in 0 to 4 loop
                        game_grid(row)(col).letter <= x"00";
                        game_grid(row)(col).color  <= "000";
                    end loop;
                end loop;
                
            else
                data_valid    <= '0';
                tx_send_start <= '0';
                
                case control_state is
                    when INPUT_LETTERS =>
                        if key_valid = '1' then
                            if (unsigned(ascii_code) >= x"41" and unsigned(ascii_code) <= x"5A") or
                               (unsigned(ascii_code) >= x"61" and unsigned(ascii_code) <= x"7A") then
                                
                                if buffer_index < 5 then
                                    if unsigned(ascii_code) >= x"61" then
                                        word_buffer(to_integer(buffer_index)) <= 
                                            std_logic_vector(unsigned(ascii_code) - x"20");
                                    else
                                        word_buffer(to_integer(buffer_index)) <= ascii_code;
                                    end if;
                                    
                                    game_grid(to_integer(current_row))(to_integer(buffer_index)).letter <= 
                                        word_buffer(to_integer(buffer_index));
                                    
                                    buffer_index <= buffer_index + 1;
                                end if;
                            end if;
                        end if;
                        
                        if key_backspace = '1' and buffer_index > 0 then
                            buffer_index <= buffer_index - 1;
                            game_grid(to_integer(current_row))(to_integer(buffer_index-1)).letter <= x"00";
                        end if;
                        
                        if key_enter = '1' and buffer_index = 5 then
                            for i in 0 to 4 loop
                                word_to_send((i+1)*8-1 downto i*8) <= word_buffer(i);
                            end loop;
                            tx_send_start <= '1';
                            control_state <= WAIT_TX;
                        end if;
                    
                    when WAIT_TX =>
                        if tx_done = '1' then
                            data_valid    <= '1';
                            control_state <= WAIT_ACKNOWLEDGE;
                        end if;
                    
                    when WAIT_ACKNOWLEDGE =>
                        if acknowledge = '1' then
                            data_valid    <= '0';
                            control_state <= RECEIVE_RESULT;
                        end if;
                    
                    when RECEIVE_RESULT =>
                        if result_ready = '1' and result_valid = '1' then
                            for col in 0 to 4 loop
                                game_grid(to_integer(current_row))(col).color <= 
                                    result_received(col*3+2 downto col*3);
                            end loop;
                            
                            if game_status = "001" or game_status = "010" then
                                control_state <= GAME_END;
                            else
                                current_row   <= current_row + 1;
                                buffer_index  <= (others => '0');
                                control_state <= INPUT_LETTERS;
                            end if;
                        end if;
                    
                    when GAME_END =>
                        null;
                end case;
            end if;
        end if;
    end process;
    
end Behavioral;