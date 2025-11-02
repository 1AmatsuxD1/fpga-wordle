--------------------------------------------------------------------------------
-- Word Comparator: ตัวเปรียบเทียบคำ (หัวใจของ Wordle Logic)
-- อัลกอริทึม:
--   1. หาตัวอักษรที่ตรงทั้งตำแหน่งและตัวอักษร (สีเขียว)
--   2. หาตัวอักษรที่มีในคำตอบแต่ผิดตำแหน่ง (สีเหลือง)
--   3. ตัวอักษรที่ไม่มีเลยในคำตอบ (สีเทา)
-- Clock: 20 MHz
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity word_comparator is
    Port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        secret_word  : in  std_logic_vector(39 downto 0);  -- คำตอบ (5 ตัวอักษร)
        guess_word   : in  std_logic_vector(39 downto 0);  -- คำทาย (5 ตัวอักษร)
        start_compare: in  std_logic;                       -- สัญญาณเริ่มเปรียบเทียบ
        result       : out std_logic_vector(14 downto 0);  -- ผลลัพธ์: 5×3 bits (สีของแต่ละตัว)
        done         : out std_logic                        -- สัญญาณเปรียบเทียบเสร็จ
    );
end word_comparator;

architecture Behavioral of word_comparator is
    
    -- สถานะของการเปรียบเทียบ
    type compare_state_type is (IDLE, EXACT_MATCH, POSITION_MATCH, COMPLETE);
    signal state : compare_state_type;
    
    -- แยกคำออกเป็นตัวอักษรทีละตัว
    type letter_array is array (0 to 4) of std_logic_vector(7 downto 0);  -- 5 ตัวอักษร, แต่ละตัว 8 bits (ASCII)
    signal secret_letters : letter_array;
    signal guess_letters  : letter_array;
    signal color_codes    : std_logic_vector(14 downto 0);  -- เก็บสีของแต่ละตัว
    
    -- Array สำหรับติดตามการใช้งานตัวอักษร
    type bool_array is array (0 to 4) of std_logic;
    signal exact_matched  : bool_array;  -- ตัวไหนที่จับคู่แบบ exact แล้ว (สีเขียว)
    signal used_in_yellow : bool_array;  -- ตัวไหนในคำตอบถูกใช้ไปแล้วสำหรับสีเหลือง
    
    -- รหัสสี
    constant COLOR_GRAY   : std_logic_vector(2 downto 0) := "000";
    constant COLOR_YELLOW : std_logic_vector(2 downto 0) := "001";
    constant COLOR_GREEN  : std_logic_vector(2 downto 0) := "010";
    
begin
    
    -- แปลงคำ (40 bits) เป็นตัวอักษรทีละตัว (5 × 8 bits)
    process(secret_word, guess_word)
    begin
        for i in 0 to 4 loop
            secret_letters(i) <= secret_word((i+1)*8-1 downto i*8);
            guess_letters(i)  <= guess_word((i+1)*8-1 downto i*8);
        end loop;
    end process;
    
    -- State Machine สำหรับการเปรียบเทียบ
    process(clk)
        variable temp_exact   : bool_array;
        variable temp_used    : bool_array;
        variable found_yellow : std_logic;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state  <= IDLE;
                done   <= '0';
                result <= (others => '0');
            else
                case state is
                    when IDLE =>
                        done <= '0';
                        if start_compare = '1' then
                            state <= EXACT_MATCH;
                            -- เริ่มต้น array ติดตาม
                            for i in 0 to 4 loop
                                temp_exact(i) := '0';
                                temp_used(i)  := '0';
                            end loop;
                            exact_matched  <= temp_exact;
                            used_in_yellow <= temp_used;
                        end if;
                    
                    when EXACT_MATCH =>
                        -- เฟส 1: หาตัวอักษรที่ตรงทั้งตำแหน่งและตัวอักษร (สีเขียว)
                        temp_exact := exact_matched;
                        for i in 0 to 4 loop
                            if guess_letters(i) = secret_letters(i) then
                                -- ตัวอักษรตำแหน่ง i ตรงกัน = สีเขียว
                                color_codes(i*3+2 downto i*3) <= COLOR_GREEN;
                                temp_exact(i) := '1';  -- ทำเครื่องหมายว่าใช้ไปแล้ว
                            else
                                -- ยังไม่รู้ ตั้งเป็นสีเทาไว้ก่อน
                                color_codes(i*3+2 downto i*3) <= COLOR_GRAY;
                            end if;
                        end loop;
                        exact_matched <= temp_exact;
                        state <= POSITION_MATCH;
                    
                    when POSITION_MATCH =>
                        -- เฟส 2: หาตัวอักษรที่มีในคำตอบแต่ผิดตำแหน่ง (สีเหลือง)
                        temp_used := used_in_yellow;
                        
                        for i in 0 to 4 loop
                            -- ถ้าตัวอักษรนี้ไม่ได้เป็นสีเขียวแล้ว
                            if exact_matched(i) = '0' then
                                found_yellow := '0';
                                
                                -- ค้นหาในคำตอบว่ามีตัวนี้หรือไม่
                                for j in 0 to 4 loop
                                    if guess_letters(i) = secret_letters(j) and
                                       exact_matched(j) = '0' and           -- ตำแหน่ง j ยังไม่เป็นสีเขียว
                                       temp_used(j) = '0' then              -- และยังไม่ถูกใช้ไปแล้ว
                                        -- เจอแล้ว! = สีเหลือง
                                        color_codes(i*3+2 downto i*3) <= COLOR_YELLOW;
                                        temp_used(j) := '1';  -- ทำเครื่องหมายว่าใช้ไปแล้ว
                                        found_yellow := '1';
                                        exit;  -- ออกจาก loop (ใช้แค่ครั้งเดียว)
                                    end if;
                                end loop;
                                
                                -- ถ้าไม่เจอเลย ให้เป็นสีเทา
                                if found_yellow = '0' then
                                    color_codes(i*3+2 downto i*3) <= COLOR_GRAY;
                                end if;
                            end if;
                        end loop;
                        
                        used_in_yellow <= temp_used;
                        state <= COMPLETE;
                    
                    when COMPLETE =>
                        -- เสร็จแล้ว ส่งผลลัพธ์ออกไป
                        result <= color_codes;
                        done   <= '1';
                        state  <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
end Behavioral;