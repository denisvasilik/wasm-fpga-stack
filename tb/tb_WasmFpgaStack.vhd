library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;

library work;
use work.tb_types.all;

entity tb_WasmFpgaStack is
    generic (
        stimulus_path : string := "../../../../../simstm/";
        stimulus_file : string := "WasmFpgaStack.stm"
    );
end;

architecture behavioural of tb_WasmFpgaStack is

    constant CLK100M_PERIOD : time := 10 ns;

    signal Clk100M : std_logic := '0';
    signal Rst : std_logic := '1';
    signal nRst : std_logic := '0';

    signal WasmFpgaStack_FileIo : T_WasmFpgaStack_FileIo;
    signal FileIo_WasmFpgaStack : T_FileIo_WasmFpgaStack;

    component WbRam is
        port ( 
            Clk : in std_logic;
            nRst : in std_logic;
            Adr : in std_logic_vector(23 downto 0);
            Sel : in std_logic_vector(3 downto 0);
            DatIn : in std_logic_vector(31 downto 0); 
            We : in std_logic;
            Stb : in std_logic; 
            Cyc : in std_logic_vector(0 downto 0);
            DatOut : out std_logic_vector(31 downto 0);
            Ack : out std_logic
        );
    end component;

    component tb_FileIo is
        generic (
            stimulus_path: in string;
            stimulus_file: in string
        );
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            WasmFpgaStack_FileIo : in T_WasmFpgaStack_FileIo;
            FileIo_WasmFpgaStack : out T_FileIo_WasmFpgaStack
        );
    end component;

    component WasmFpgaStack
        port (
            Clk : in std_logic;
            nRst : in std_logic;
            Adr : in std_logic_vector(23 downto 0);
            Sel : in std_logic_vector(3 downto 0);
            DatIn : in std_logic_vector(31 downto 0); 
            We : in std_logic;
            Stb : in std_logic; 
            Cyc : in std_logic_vector(0 downto 0);
            DatOut : out std_logic_vector(31 downto 0);
            Ack : out std_logic
		);
    end component;

begin

	nRst <= not Rst;

    Clk100MGen : process is
    begin
        Clk100M <= not Clk100M;
        wait for CLK100M_PERIOD / 2;
    end process;

    RstGen : process is
    begin
        Rst <= '1';
        wait for 100ns;
        Rst <= '0';
        wait;
    end process;

    tb_FileIo_i : tb_FileIo
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file
        )
        port map (
            Clk => Clk100M,
            Rst => Rst,
            WasmFpgaStack_FileIo => WasmFpgaStack_FileIo,
            FileIo_WasmFpgaStack => FileIo_WasmFpgaStack
        );

    WasmFpgaStack_i : WasmFpgaStack
        port map (
            Clk => Clk100M,
            nRst => nRst,
            Adr => FileIo_WasmFpgaStack.Adr,
            Sel => FileIo_WasmFpgaStack.Sel,
            DatIn => FileIo_WasmFpgaStack.DatIn,
            We => FileIo_WasmFpgaStack.We,
            Stb => FileIo_WasmFpgaStack.Stb,
            Cyc => FileIo_WasmFpgaStack.Cyc,
            DatOut => WasmFpgaStack_FileIo.DatOut,
            Ack => WasmFpgaStack_FileIo.Ack
       );

end;
