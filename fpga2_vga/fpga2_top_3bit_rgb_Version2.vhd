--------------------------------------------------------------------------------
-- FPGA Board #2: Display & Input with 3-bit RGB
-- Clock: 20 MHz
-- VGA: 3-bit RGB (R, G, B - 1 bit each) = 8 colors
-- (*** แก้ไขแล้ว: เพิ่ม Synchronizer สำหรับ acknowledge และ result_valid ***)
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
        acknowledge    : in  std_logic; -- <--- สัญญาณ Asynchronous
        result_valid   : in  std_logic; -- <--- สัญญาณ Asynchronous
        
        -- Game Status
        game_status : in  std_logic_vector(2 downto 0);
        
        -- Debug LEDs
        led_locked     : out std_logic; -- DCM lock status
        debug_led      : out std_logic_vector(2 downto 0); -- FSM state indicator
        
        -- Debug: TX signals (ตรวจสอบว่า FPGA #2 ส่งจริงหรือไม่)
        debug_tx_clk   : out std_logic; -- Copy of serial_tx_clk
        debug_data_valid : out std_logic   -- Copy of data_valid
    );
end fpga2_top;

architecture Behavioral of fpga2_top is
    
    -- Test Mode: ตั้งเป็น true เพื่อทดสอบโดยไม่ต้องเชื่อม FPGA #1
    constant TEST_MODE : boolean := false;
    
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
            clk      : in  std_logic; -- pixel clock (25 MHz)
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
            pixel_clk   : in  std_logic;
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
    signal clk_25        : std_logic; -- VGA pixel clock
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
    signal rgb_signal    : std_logic_vector(2 downto 0);
    signal pixel_clk     : std_logic; 
    
    -- Serial signals
    signal word_to_send    : std_logic_vector(39 downto 0);
    signal tx_send_start   : std_logic;
    signal tx_busy         : std_logic;
    signal tx_done         : std_logic;
    signal result_received : std_logic_vector(14 downto 0);
    signal result_ready    : std_logic;
    signal rx_busy         : std_logic;
    
    -- Internal signals for outputs
    signal serial_tx_clk_i : std_logic;
    signal data_valid_i    : std_logic;
    
    -- Debug signals
    signal key_valid_latch : std_logic := '0';
    signal key_enter_latch : std_logic := '0';
    signal key_enter_counter : unsigned(23 downto 0) := (others => '0');
    constant LATCH_TIME : unsigned(23 downto 0) := x"1312D0";
    
    -- TX state tracking
    signal tx_was_busy : std_logic := '0';
    
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
    
    type control_state_type is (INPUT_LETTERS, START_TX, WAIT_TX, WAIT_ACKNOWLEDGE, RECEIVE_RESULT, GAME_END);
    signal control_state : control_state_type;
    signal game_grid_flat : std_logic_vector(1079 downto 0);
    
    -- Timeout counter
    signal timeout_counter : unsigned(23 downto 0) := (others => '0');
    constant TIMEOUT_MAX   : unsigned(23 downto 0) := x"4C4B40";
    
    -- *** โค้ดที่เพิ่มใหม่: 2-Stage Synchronizers ***
    signal ack_s1, ack_s2 : std_logic;
    signal res_valid_s1, res_valid_s2 : std_logic;

begin
    
    -- Clock Generator: 20 MHz -> 50 MHz -> 25 MHz (for VGA)
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
            serial_clk  => serial_tx_clk_i,
            busy        => tx_busy,
            done        => tx_done
        );
        
    -- Connect internal signals to output ports
    serial_tx_clk <= serial_tx_clk_i;
    data_valid    <= data_valid_i;
    
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
            pixel_clk   => clk_25,
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
    vga_r <= rgb_signal(2);
    vga_g <= rgb_signal(1);
    vga_b <= rgb_signal(0);
    
    -- Debug: DCM lock LED
    led_locked <= clk_locked;
    
    -- Debug: แสดง control_state, buffer_index และ tx_busy ตามตาราง LED States
    -- L3 = tx_busy OR (buffer_index >= 5 AND state = INPUT_LETTERS/START_TX)
    debug_led(2) <= '1' when (tx_busy = '1' or 
                              (buffer_index >= 5 and 
                               (control_state = INPUT_LETTERS or control_state = START_TX or control_state = WAIT_TX))) else '0';
    
    -- L2 = WAIT_ACKNOWLEDGE OR RECEIVE_RESULT
    debug_led(1) <= '1' when (control_state = WAIT_ACKNOWLEDGE or control_state = RECEIVE_RESULT) else '0';
    
    -- L1 = (buffer_index >= 1 AND state = INPUT_LETTERS) OR START_TX OR WAIT_TX
    debug_led(0) <= '1' when ((buffer_index >= 1 and control_state = INPUT_LETTERS) or 
                              control_state = START_TX or 
                              control_state = WAIT_TX) else '0';
    
    -- Debug outputs: แสดงสัญญาณ TX จริงๆ เพื่อตรวจสอบว่าส่งออกหรือไม่
    debug_tx_clk <= serial_tx_clk_i;
    debug_data_valid <= data_valid_i;
    
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
    
    -- Latch debug signals
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                key_valid_latch <= '0';
                key_enter_latch <= '0';
                key_enter_counter <= (others => '0');
            else
                if buffer_index = 0 then
                    key_valid_latch <= '0';
                elsif key_valid = '1' then
                    key_valid_latch <= '1';
                end if;
                
                if key_enter = '1' then
                    key_enter_latch <= '1';
                    key_enter_counter <= LATCH_TIME;
                elsif key_enter_counter > 0 then
                    key_enter_counter <= key_enter_counter - 1;
                    key_enter_latch <= '1';
                else
                    key_enter_latch <= '0';
                end if;
            end if;
        end if;
    end process;

    -- *** โค้ดที่เพิ่มใหม่: Process สำหรับ Synchronizers ***
    sync_inputs: process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ack_s1 <= '0';
                ack_s2 <= '0';
                res_valid_s1 <= '0';
                res_valid_s2 <= '0';
            else
                -- Synchronize Acknowledge
                ack_s1 <= acknowledge;
                ack_s2 <= ack_s1;
                
                -- Synchronize Result Valid
                res_valid_s1 <= result_valid;
                res_valid_s2 <= res_valid_s1;
            end if;
        end if;
    end process;

    -- Main control FSM
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                control_state <= INPUT_LETTERS;
                current_row   <= (others => '0');
                current_col   <= (others => '0');
                buffer_index  <= (others => '0');
                data_valid_i  <= '0';
                tx_send_start <= '0';
                tx_was_busy   <= '0';
                timeout_counter <= (others => '0');
                for row in 0 to 5 loop
                    for col in 0 to 4 loop
                        game_grid(row)(col).letter <= x"00";
                        game_grid(row)(col).color  <= "000";
                    end loop;
                end loop;
                
            else
                -- Sync current_col with buffer_index
                current_col <= buffer_index;
                
                -- Timeout counter
                if control_state = INPUT_LETTERS or control_state = GAME_END then
                    timeout_counter <= (others => '0');
                else
                    timeout_counter <= timeout_counter + 1;
                end if;
                
                -- Timeout protection
                if timeout_counter >= TIMEOUT_MAX then
                    control_state <= INPUT_LETTERS;
                    timeout_counter <= (others => '0');
                    for col in 0 to 4 loop
                        game_grid(to_integer(current_row))(col).color <= "000";
                    end loop;
                    current_row   <= current_row + 1;
                    current_col   <= (others => '0');
                    buffer_index  <= (others => '0');
                end if;
                
                case control_state is
                    when INPUT_LETTERS =>
                        if key_valid = '1' then
                            if (unsigned(ascii_code) >= x"41" and unsigned(ascii_code) <= x"5A") or
                               (unsigned(ascii_code) >= x"61" and unsigned(ascii_code) <= x"7A") then
                                
                                if buffer_index < 5 then
                                    if unsigned(ascii_code) >= x"61" then
                                        word_buffer(to_integer(buffer_index)) <= std_logic_vector(unsigned(ascii_code) - x"20");
                                        game_grid(to_integer(current_row))(to_integer(buffer_index)).letter <= std_logic_vector(unsigned(ascii_code) - x"20");
                                    else
                                        word_buffer(to_integer(buffer_index)) <= ascii_code;
                                        game_grid(to_integer(current_row))(to_integer(buffer_index)).letter <= ascii_code;
                                    end if;
                                    buffer_index <= buffer_index + 1;
                                end if;
                            end if;
                        end if;
                        
                        if key_backspace = '1' and buffer_index > 0 then
                            buffer_index <= buffer_index - 1;
                            game_grid(to_integer(current_row))(to_integer(buffer_index-1)).letter <= x"00";
                        end if;
                        
                        if key_enter = '1' and buffer_index = 5 then
                            if TEST_MODE then
                                -- Test Mode:
                                for col in 0 to 4 loop
                                    if col = 0 then
                                        game_grid(to_integer(current_row))(col).color <= "010";  -- Green
                                    elsif col = 1 then
                                        game_grid(to_integer(current_row))(col).color <= "110"; -- Yellow
                                    elsif col = 2 then
                                        game_grid(to_integer(current_row))(col).color <= "101"; -- Magenta (Gray)
                                    elsif col = 3 then
                                        game_grid(to_integer(current_row))(col).color <= "111"; -- White (test)
                                    else
                                        game_grid(to_integer(current_row))(col).color <= "011"; -- Cyan (test)
                                    end if;
                                end loop;
                                current_row   <= current_row + 1;
                                current_col   <= (others => '0');
                                buffer_index  <= (others => '0');
                            else
                                -- Normal Mode:
                                for i in 0 to 4 loop
                                    word_to_send((i+1)*8-1 downto i*8) <= word_buffer(i);
                                end loop;
                                tx_was_busy   <= '0';
                                control_state <= START_TX;
                            end if;
                        end if;
                    
                    when START_TX =>
                        tx_send_start <= '1';
                        control_state <= WAIT_TX;
                    
                    when WAIT_TX =>
                        if tx_busy = '1' then
                            tx_send_start <= '0';
                            tx_was_busy   <= '1';
                        end if;
                        if tx_was_busy = '1' and tx_busy = '0' then
                            data_valid_i  <= '1';
                            control_state <= WAIT_ACKNOWLEDGE;
                        end if;
                        
                    when WAIT_ACKNOWLEDGE =>
                        -- *** แก้ไข: อ่านจาก ack_s2 ที่ซิงค์แล้ว ***
                        if ack_s2 = '1' then
                            data_valid_i  <= '0';
                            control_state <= RECEIVE_RESULT;
                        end if;
                    
                    when RECEIVE_RESULT =>
                        -- *** แก้ไข: อ่านจาก res_valid_s2 ที่ซิงค์แล้ว ***
                        if result_ready = '1' and res_valid_s2 = '1' then
                            for col in 0 to 4 loop
                                game_grid(to_integer(current_row))(col).color <= result_received(col*3+2 downto col*3);
                            end loop;
                            
                            if game_status = "001" or game_status = "010" then
                                control_state <= GAME_END;
                            else
                                current_row   <= current_row + 1;
                                current_col   <= (others => '0');
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