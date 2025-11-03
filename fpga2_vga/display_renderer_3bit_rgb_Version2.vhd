--------------------------------------------------------------------------------
-- Display Renderer with 3-bit RGB (8 colors)
-- สีม่วง (Magenta) ใช้แทนสีเทา
-- Clock: 20 MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_renderer is
    Port (
        pixel_clk   : in  std_logic;  -- pixel clock (use same clock as vga_controller)
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
end display_renderer;

architecture Behavioral of display_renderer is
    
    -- Component: Character ROM
    component char_rom is
        Port (
            pixel_clk : in  std_logic;
            char_code : in  std_logic_vector(7 downto 0);
            row       : in  unsigned(2 downto 0);
            col       : in  unsigned(2 downto 0);
            pixel     : out std_logic
        );
    end component;
    
    -- ค่าคงที่: ขนาดและตำแหน่งตาราง
    constant GRID_START_X : integer := 160;
    constant GRID_START_Y : integer := 60;
    constant CELL_WIDTH   : integer := 60;
    constant CELL_HEIGHT  : integer := 60;
    constant CELL_SPACING : integer := 10;
    constant CELL_BORDER  : integer := 2;
    
    constant CHAR_WIDTH   : integer := 40;
    constant CHAR_HEIGHT  : integer := 40;
    constant CHAR_SCALE   : integer := 5;
    
    -- สีต่างๆ (3 bits: R G B)
    constant COLOR_BLACK      : std_logic_vector(2 downto 0) := "000";  -- ⚫ ดำ
    constant COLOR_WHITE      : std_logic_vector(2 downto 0) := "111";  -- ⚪ ขาว
    constant COLOR_GREEN      : std_logic_vector(2 downto 0) := "010";  -- 🟢 เขียว
    constant COLOR_YELLOW     : std_logic_vector(2 downto 0) := "110";  -- 🟡 เหลือง
    constant COLOR_MAGENTA    : std_logic_vector(2 downto 0) := "101";  -- 🟣 ม่วง (แทนเทา)
    constant COLOR_DARK_GRAY  : std_logic_vector(2 downto 0) := "101";  -- ม่วง (empty cell)
    constant COLOR_BORDER     : std_logic_vector(2 downto 0) := "111";  -- ขาว
    
    -- สัญญาณตำแหน่งเซลล์
    signal cell_row    : integer range 0 to 6;
    signal cell_col    : integer range 0 to 5;
    signal in_cell     : std_logic;
    signal in_border   : std_logic;
    
    signal cell_letter : std_logic_vector(7 downto 0);
    signal cell_color  : std_logic_vector(2 downto 0);
    
    signal rel_x       : integer range 0 to 79;
    signal rel_y       : integer range 0 to 79;
    
    signal in_char_area : std_logic;
    signal char_pixel_x : integer range 0 to 49;
    signal char_pixel_y : integer range 0 to 49;
    signal char_rom_row : unsigned(2 downto 0);
    signal char_rom_col : unsigned(2 downto 0);
    signal char_pixel   : std_logic;
    
    signal bg_color     : std_logic_vector(2 downto 0);
    
begin
    
    -- Instantiate Character ROM
    char_rom_inst: char_rom
        port map (
            pixel_clk => pixel_clk,
            char_code => cell_letter,
            row       => char_rom_row,
            col       => char_rom_col,
            pixel     => char_pixel
        );
    
    -- หาว่าพิกเซลปัจจุบันอยู่ในเซลล์ไหน
    process(pixel_x, pixel_y)
        variable temp_x, temp_y : integer;
    begin
        in_cell  <= '0';
        cell_row <= 0;
        cell_col <= 0;
        rel_x    <= 0;
        rel_y    <= 0;
        
        temp_y := to_integer(pixel_y) - GRID_START_Y;
        temp_x := to_integer(pixel_x) - GRID_START_X;
        
        if temp_y >= 0 and temp_x >= 0 then
            for row in 0 to 5 loop
                for col in 0 to 4 loop
                    if temp_y >= row * (CELL_HEIGHT + CELL_SPACING) and
                       temp_y < row * (CELL_HEIGHT + CELL_SPACING) + CELL_HEIGHT and
                       temp_x >= col * (CELL_WIDTH + CELL_SPACING) and
                       temp_x < col * (CELL_WIDTH + CELL_SPACING) + CELL_WIDTH then
                        
                        in_cell  <= '1';
                        cell_row <= row;
                        cell_col <= col;
                        
                        rel_x <= temp_x - col * (CELL_WIDTH + CELL_SPACING);
                        rel_y <= temp_y - row * (CELL_HEIGHT + CELL_SPACING);
                    end if;
                end loop;
            end loop;
        end if;
    end process;
    
    -- ตรวจสอบว่าอยู่ในขอบเซลล์หรือไม่
    process(rel_x, rel_y)
    begin
        if rel_x < CELL_BORDER or rel_x >= CELL_WIDTH - CELL_BORDER or
           rel_y < CELL_BORDER or rel_y >= CELL_HEIGHT - CELL_BORDER then
            in_border <= '1';
        else
            in_border <= '0';
        end if;
    end process;
    
    -- อ่านข้อมูลเซลล์จาก game_grid
    process(cell_row, cell_col, game_grid)
        variable index : integer;
    begin
        index := cell_row * 5 + cell_col;
        if index >= 0 and index < 30 then
            cell_letter <= game_grid(index*11+10 downto index*11+3);
            cell_color  <= game_grid(index*11+2 downto index*11);
        else
            cell_letter <= x"00";
            cell_color  <= "000";
        end if;
    end process;
    
    -- คำนวณตำแหน่งตัวอักษร
    process(rel_x, rel_y, cell_letter)
        variable char_start_x, char_start_y : integer;
        variable temp_pixel_x, temp_pixel_y : integer;
    begin
        in_char_area <= '0';
        char_pixel_x <= 0;
        char_pixel_y <= 0;
        char_rom_row <= (others => '0');
        char_rom_col <= (others => '0');
        
        char_start_x := (CELL_WIDTH - CHAR_WIDTH) / 2;
        char_start_y := (CELL_HEIGHT - CHAR_HEIGHT) / 2;
        
        if cell_letter /= x"00" and
           rel_x >= char_start_x and rel_x < char_start_x + CHAR_WIDTH and
           rel_y >= char_start_y and rel_y < char_start_y + CHAR_HEIGHT then
            
            in_char_area <= '1';
            
            temp_pixel_x := (rel_x - char_start_x) / CHAR_SCALE;
            temp_pixel_y := (rel_y - char_start_y) / CHAR_SCALE;
            
            char_pixel_x <= temp_pixel_x;
            char_pixel_y <= temp_pixel_y;
            
            if temp_pixel_x >= 0 and temp_pixel_x < 8 then
                char_rom_col <= to_unsigned(temp_pixel_x, 3);
            end if;
            
            if temp_pixel_y >= 0 and temp_pixel_y < 8 then
                char_rom_row <= to_unsigned(temp_pixel_y, 3);
            end if;
        end if;
    end process;
    
    -- กำหนดสีพื้นหลังตามสถานะเซลล์
    process(cell_color)
    begin
        case cell_color is
            when "000" => bg_color <= COLOR_MAGENTA;  -- Gray → Magenta (ม่วง)
            when "001" => bg_color <= COLOR_YELLOW;   -- Yellow
            when "010" => bg_color <= COLOR_GREEN;    -- Green
            when others => bg_color <= COLOR_BLACK;
        end case;
    end process;
    
    -- วาดพิกเซล (synchronous to pixel clock)
    process(pixel_clk)
    begin
        if rising_edge(pixel_clk) then
            if rst = '1' or video_on = '0' then
                rgb <= COLOR_BLACK;
            else
                rgb <= COLOR_BLACK;

                if in_cell = '1' then
                    if in_border = '1' then
                        rgb <= COLOR_BORDER;
                    elsif in_char_area = '1' then
                        if char_pixel = '1' then
                            rgb <= COLOR_WHITE;  -- ตัวอักษรสีขาว
                        else
                            rgb <= bg_color;     -- พื้นหลังตามสี
                        end if;
                    else
                        rgb <= bg_color;
                    end if;
                end if;

                -- Status bar
                if pixel_y > 450 then
                    if game_status = "001" then
                        rgb <= COLOR_GREEN;   -- WIN: เขียว
                    elsif game_status = "010" then
                        rgb <= COLOR_YELLOW;  -- LOSE: เหลือง (ไม่มีแดง ใช้เหลืองแทน)
                    end if;
                end if;
            end if;
        end if;
    end process;
    
end Behavioral;