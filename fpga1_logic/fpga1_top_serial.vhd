--------------------------------------------------------------------------------
-- FPGA Board #1: Game Logic with Serial Communication
-- Clock: 20 MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fpga1_top is
    Port (
        clk         : in  std_logic;  -- 20 MHz
        rst         : in  std_logic;
        
        -- Serial Communication Interface (จาก FPGA #2)
        serial_rx_data : in  std_logic;   -- รับคำทาย
        serial_rx_clk  : in  std_logic;
        data_valid     : in  std_logic;
        
        -- Serial Communication Interface (ไป FPGA #2)
        serial_tx_data : out std_logic;   -- ส่งผลลัพธ์
        serial_tx_clk  : out std_logic;
        acknowledge    : out std_logic;
        result_valid   : out std_logic;
        game_status    : out std_logic_vector(2 downto 0)
    );
end fpga1_top;

architecture Behavioral of fpga1_top is
    
    -- Components
    component serial_receiver is
        Generic (DATA_WIDTH : integer := 40);
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
    
    component serial_transmitter is
        Generic (DATA_WIDTH : integer := 15);
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
    
    component word_comparator is
        Port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            secret_word  : in  std_logic_vector(39 downto 0);
            guess_word   : in  std_logic_vector(39 downto 0);
            start_compare: in  std_logic;
            result       : out std_logic_vector(14 downto 0);
            done         : out std_logic
        );
    end component;
    
    component word_rom is
        Port (
            clk     : in  std_logic;
            address : in  std_logic_vector(3 downto 0);
            data_out: out std_logic_vector(39 downto 0)
        );
    end component;
    
    -- FSM states
    type game_state_type is (IDLE, RECEIVE_WORD, COMPARE, SEND_RESULT, WIN, LOSE);
    signal current_state, next_state : game_state_type;
    
    -- Signals
    signal secret_word      : std_logic_vector(39 downto 0);
    signal input_letters    : std_logic_vector(39 downto 0);
    signal comparison_result: std_logic_vector(14 downto 0);
    signal guess_count      : unsigned(2 downto 0);
    constant MAX_GUESSES    : integer := 6;
    
    -- Serial signals
    signal word_received    : std_logic;
    signal rx_busy          : std_logic;
    signal tx_send_start    : std_logic;
    signal tx_busy          : std_logic;
    signal tx_done          : std_logic;
    
    -- Control signals
    signal rom_address      : std_logic_vector(3 downto 0) := "0000";
    signal compare_start    : std_logic;
    signal compare_done     : std_logic;
    signal all_green        : std_logic;
    signal result_valid_i   : std_logic;
    
    -- Color constants
    constant COLOR_GRAY     : std_logic_vector(2 downto 0) := "000";
    constant COLOR_YELLOW   : std_logic_vector(2 downto 0) := "001";
    constant COLOR_GREEN    : std_logic_vector(2 downto 0) := "010";
    constant STATUS_PLAYING : std_logic_vector(2 downto 0) := "000";
    constant STATUS_WIN     : std_logic_vector(2 downto 0) := "001";
    constant STATUS_LOSE    : std_logic_vector(2 downto 0) := "010";
    
begin
    
    -- Serial Receiver: รับคำทายจาก FPGA #2
    word_receiver: serial_receiver
        generic map (DATA_WIDTH => 40)
        port map (
            clk         => clk,
            rst         => rst,
            serial_data => serial_rx_data,
            serial_clk  => serial_rx_clk,
            data_out    => input_letters,
            data_ready  => word_received,
            busy        => rx_busy
        );
    
    -- Serial Transmitter: ส่งผลลัพธ์ไป FPGA #2
    result_transmitter: serial_transmitter
        generic map (DATA_WIDTH => 15)
        port map (
            clk         => clk,
            rst         => rst,
            data_in     => comparison_result,
            send_start  => tx_send_start,
            serial_data => serial_tx_data,
            serial_clk  => serial_tx_clk,
            busy        => tx_busy,
            done        => tx_done
        );
    
    -- Word ROM
    word_rom_inst: word_rom
        port map (
            clk      => clk,
            address  => rom_address,
            data_out => secret_word
        );
    
    -- Word Comparator
    comparator_inst: word_comparator
        port map (
            clk          => clk,
            rst          => rst,
            secret_word  => secret_word,
            guess_word   => input_letters,
            start_compare=> compare_start,
            result       => comparison_result,
            done         => compare_done
        );
    
    -- FSM: State register
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                current_state <= IDLE;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;
    
    -- FSM: Next state logic
    process(current_state, word_received, compare_done, tx_done, guess_count, all_green)
    begin
        next_state <= current_state;
        
        case current_state is
            when IDLE =>
                if word_received = '1' then
                    next_state <= RECEIVE_WORD;
                end if;
            
            when RECEIVE_WORD =>
                next_state <= COMPARE;
            
            when COMPARE =>
                if compare_done = '1' then
                    if all_green = '1' then
                        next_state <= WIN;
                    elsif guess_count >= MAX_GUESSES then
                        next_state <= LOSE;
                    else
                        next_state <= SEND_RESULT;
                    end if;
                end if;
            
            when SEND_RESULT =>
                if tx_done = '1' then
                    next_state <= IDLE;
                end if;
            
            when WIN | LOSE =>
                if tx_done = '1' then
                    next_state <= current_state;  -- Stay in terminal state
                end if;
        end case;
    end process;
    
    -- FSM: Output logic
    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                guess_count    <= (others => '0');
                acknowledge    <= '0';
                result_valid_i <= '0';
                compare_start  <= '0';
                tx_send_start  <= '0';
                game_status    <= STATUS_PLAYING;
            else
                -- Default values
                acknowledge    <= '0';
                result_valid_i <= '0';
                compare_start  <= '0';
                tx_send_start  <= '0';
                
                case current_state is
                    when IDLE =>
                        null;
                    
                    when RECEIVE_WORD =>
                        acknowledge   <= '1';
                        compare_start <= '1';
                    
                    when COMPARE =>
                        null;
                    
                    when SEND_RESULT =>
                        if tx_busy = '0' and tx_send_start = '0' then
                            tx_send_start  <= '1';
                            result_valid_i <= '1';
                            guess_count    <= guess_count + 1;
                        end if;
                        game_status <= STATUS_PLAYING;
                    
                    when WIN =>
                        if tx_busy = '0' and result_valid_i = '0' then
                            tx_send_start  <= '1';
                            result_valid_i <= '1';
                        end if;
                        game_status <= STATUS_WIN;
                    
                    when LOSE =>
                        if tx_busy = '0' and result_valid_i = '0' then
                            tx_send_start  <= '1';
                            result_valid_i <= '1';
                        end if;
                        game_status <= STATUS_LOSE;
                end case;
            end if;
        end if;
    end process;
    
    -- Check for win condition
    process(comparison_result)
        variable green_count : integer range 0 to 5;
    begin
        green_count := 0;
        for i in 0 to 4 loop
            if comparison_result(i*3+2 downto i*3) = COLOR_GREEN then
                green_count := green_count + 1;
            end if;
        end loop;
        
        if green_count = 5 then
            all_green <= '1';
        else
            all_green <= '0';
        end if;
    end process;
    
    -- Connect internal signal to output port
    result_valid <= result_valid_i;
    
end Behavioral;