library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity project_reti_logiche is
    Port ( i_clk : in STD_LOGIC;
           i_start : in STD_LOGIC;
           i_rst : in STD_LOGIC;
           i_data : in STD_LOGIC_VECTOR(7 downto 0);
           o_address : out STD_LOGIC_VECTOR(15 downto 0);
           o_done : out STD_LOGIC;
           o_en : out STD_LOGIC;
           o_we : out STD_LOGIC;
           o_data : out STD_LOGIC_VECTOR(7 downto 0));
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is

type state is ( START_WAIT, MASK_READ_REQ,
                MASK_READ, CEN_READ_X_REQ,
                CEN_READ_X, CEN_READ_Y_REQ,
                CEN_READ_Y, MASK_CHECK,
                TMP_COUNT_INC, COUNT_INC,
                ADDR_CALC, TMP_CEN_READ_X_REQ,
                TMP_CEN_READ_X, TMP_CEN_READ_Y_REQ,
                TMP_CEN_READ_Y, DST_CALC,
                DST_CHECK, DST_UPDATE,
                MASK_RST, MASK_UPDATE,
                MASK_WRITE, SET_DONE,
                LOW_START_WAIT );

signal state_next : state;
signal state_curr : state;
signal mask : STD_LOGIC_VECTOR(7 downto 0);
signal tmp_mask : STD_LOGIC_VECTOR(7 downto 0);
signal cen_x : STD_LOGIC_VECTOR(7 downto 0);
signal cen_y : STD_LOGIC_VECTOR(7 downto 0);
signal tmp_cen_x : STD_LOGIC_VECTOR(7 downto 0);
signal tmp_cen_y : STD_LOGIC_VECTOR(7 downto 0);
signal addr_x : STD_LOGIC_VECTOR(15 downto 0);
signal addr_y : STD_LOGIC_VECTOR(15 downto 0);
signal count : INTEGER;
signal tmp_count : INTEGER;
signal dst : INTEGER;
signal tmp_dst : INTEGER;

begin

process(i_clk)
begin
    if(i_clk'event and i_clk = '1')then
        if(i_rst = '1')then
            state_curr <= START_WAIT;
        else
            state_curr <= state_next;
        end if;
    
        case state_curr is
            when START_WAIT =>  tmp_mask <= "00000000";
                                count <= 1;
                                dst <= 512;
                                o_done <= '0';
                                if(i_start = '1')then
                                    state_next <= MASK_READ_REQ;
                                else
                                    state_next <= START_WAIT;
                                end if;
            when MASK_READ_REQ =>   o_en <= '1';
                                    o_we <= '0';
                                    o_address <= "0000000000000000";
                                    state_next <= MASK_READ;
            when MASK_READ =>   mask <= i_data;
                                state_next <= CEN_READ_X_REQ;
            when CEN_READ_X_REQ =>  o_en <= '1';
                                    o_we <= '0';
                                    o_address <= "0000000000010001";
                                    state_next <= CEN_READ_X;
            when CEN_READ_X =>  cen_x <= i_data;
                                state_next <= CEN_READ_Y_REQ;
            when CEN_READ_Y_REQ =>  o_en <= '1';
                                    o_we <= '0';
                                    o_address <= "0000000000010010";
                                    state_next <= CEN_READ_Y;
            when CEN_READ_Y =>  cen_y <= i_data;
                                state_next <= MASK_CHECK;
            when MASK_CHECK =>  if(count > 8)then
                                    state_next <= MASK_WRITE;
                                else
                                    if(mask(count - 1) = '1')then
                                        state_next <= ADDR_CALC;
                                    else
                                        state_next <= TMP_COUNT_INC;
                                    end if;
                                end if;
            when TMP_COUNT_INC =>   tmp_count <= count + 1;
                                    state_next <= COUNT_INC;
            when COUNT_INC =>   count <= tmp_count;
                                state_next <= MASK_CHECK;
            when ADDR_CALC =>   addr_x <= std_logic_vector(to_unsigned(2 * count - 1,16));
                                addr_y <= std_logic_vector(to_unsigned(2 * count,16));
                                state_next <= TMP_CEN_READ_X_REQ;
            when TMP_CEN_READ_X_REQ =>  o_en <= '1';
                                        o_we <= '0';
                                        o_address <= addr_x;
                                        state_next <= TMP_CEN_READ_X;
            when TMP_CEN_READ_X =>  tmp_cen_x <= i_data;
                                    state_next <= TMP_CEN_READ_Y_REQ;
            when TMP_CEN_READ_Y_REQ =>  o_en <= '1';
                                        o_we <= '0';
                                        o_address <= addr_y;
                                        state_next <= TMP_CEN_READ_Y;
            when TMP_CEN_READ_Y =>  tmp_cen_y <= i_data;
                                    state_next <= DST_CALC;
            when DST_CALC =>    if(cen_x >= tmp_cen_x and cen_y >= tmp_cen_y)then
                                    tmp_dst <= (to_integer(unsigned(cen_x)) - to_integer(unsigned(tmp_cen_x))) + (to_integer(unsigned(cen_y))-to_integer(unsigned(tmp_cen_y)));
                                elsif(cen_x >= tmp_cen_x and cen_y <= tmp_cen_y)then
                                    tmp_dst <= (to_integer(unsigned(cen_x)) - to_integer(unsigned(tmp_cen_x))) + (to_integer(unsigned(tmp_cen_y))-to_integer(unsigned(cen_y)));
                                elsif(cen_x <= tmp_cen_x and cen_y >= tmp_cen_y)then
                                    tmp_dst <= (to_integer(unsigned(tmp_cen_x)) - to_integer(unsigned(cen_x))) + (to_integer(unsigned(cen_y))-to_integer(unsigned(tmp_cen_y)));
                                else
                                    tmp_dst <= (to_integer(unsigned(tmp_cen_x)) - to_integer(unsigned(cen_x))) + (to_integer(unsigned(tmp_cen_y))-to_integer(unsigned(cen_y)));
                                end if;
                                state_next <= DST_CHECK;
            when DST_CHECK =>   if(tmp_dst < dst)then
                                    state_next <= DST_UPDATE;
                                elsif(tmp_dst = dst)then
                                    state_next <= MASK_UPDATE;
                                else
                                    state_next <= TMP_COUNT_INC;
                                end if;
            when DST_UPDATE =>  dst <= tmp_dst;
                                state_next <= MASK_RST;
            when MASK_RST =>    tmp_mask <= "00000000";
                                state_next <= MASK_UPDATE;
            when MASK_UPDATE => tmp_mask(count - 1) <= '1';
                                state_next <= TMP_COUNT_INC;
            when MASK_WRITE =>  o_en <= '1';
                                    o_we <= '1';
                                    o_address <= "0000000000010011";
                                    o_data <= tmp_mask;
                                    state_next <= SET_DONE;
            when SET_DONE =>    o_done <= '1';
                                state_next <= LOW_START_WAIT;
            when LOW_START_WAIT =>  if(i_start = '0')then
                                        state_next <= START_WAIT;
                                    else
                                        state_next <= LOW_START_WAIT;
                                    end if;
        end case;
    end if;
end process;

end Behavioral;
