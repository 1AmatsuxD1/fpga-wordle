--------------------------------------------------------------------------------
-- Word ROM: เก็บคำตอบที่ซ่อนไว้ (5 ตัวอักษร)
-- ตัวอย่าง: "HELLO" = 0x48 45 4C 4C 4F (ASCII code)
-- สามารถเก็บได้ถึง 16 คำ (address 0-15)
--------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity word_rom is
    Port (
        clk     : in  std_logic;
        address : in  std_logic_vector(3 downto 0);  -- เลือกคำที่ 0-15
        data_out: out std_logic_vector(39 downto 0)  -- คำที่เลือก (40 bits = 5 ตัวอักษร)
    );
end word_rom;

architecture Behavioral of word_rom is
    
    -- ประเภทข้อมูล: array ของคำ (แต่ละคำ 40 bits)
    type rom_type is array (0 to 15) of std_logic_vector(39 downto 0);
    
    -- คำศัพท์ที่เก็บไว้ (เข้ารหัส ASCII แบบ Hexadecimal)
    -- แต่ละคำ = 5 ตัวอักษร × 8 bits = 40 bits
    constant ROM : rom_type := (
        0  => x"48454C4C4F",  -- HELLO (H=48, E=45, L=4C, L=4C, O=4F)
        1  => x"574F524C44",  -- WORLD (W=57, O=4F, R=52, L=4C, D=44)
        2  => x"424F415244",  -- BOARD (B=42, O=4F, A=41, R=52, D=44)
        3  => x"4C4F474943",  -- LOGIC (L=4C, O=4F, G=47, I=49, C=43)
        4  => x"434C4F434B",  -- CLOCK (C=43, L=4C, O=4F, C=43, K=4B)
        5  => x"5354415445",  -- STATE (S=53, T=54, A=41, T=54, E=45)
        6  => x"494D414745",  -- IMAGE (I=49, M=4D, A=41, G=47, E=45)
        7  => x"4D4F555345",  -- MOUSE (M=4D, O=4F, U=55, S=53, E=45)
        8  => x"5441424C45",  -- TABLE (T=54, A=41, B=42, L=4C, E=45)
        9  => x"4348414952",  -- CHAIR (C=43, H=48, A=41, I=49, R=52)
        10 => x"504C414E54",  -- PLANT (P=50, L=4C, A=41, N=4E, T=54)
        11 => x"4D55534943",  -- MUSIC (M=4D, U=55, S=53, I=49, C=43)
        12 => x"445245414D",  -- DREAM (D=44, R=52, E=45, A=41, M=4D)
        13 => x"4252454144",  -- BREAD (B=42, R=52, E=45, A=41, D=44)
        14 => x"5350454544",  -- SPEED (S=53, P=50, E=45, E=45, D=44)
        15 => x"5448414E4B",  -- THANK (T=54, H=48, A=41, N=4E, K=4B)
        others => x"48454C4C4F"  -- ค่าเริ่มต้น: HELLO
    );
    
begin
    
    -- อ่านคำจาก ROM ตาม address
    process(clk)
    begin
        if rising_edge(clk) then
            data_out <= ROM(to_integer(unsigned(address)));
        end if;
    end process;
    
end Behavioral;