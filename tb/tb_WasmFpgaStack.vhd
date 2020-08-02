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

    signal WbRam_FileIo : T_WbRam_FileIo;
    signal FileIo_WbRam : T_FileIo_WbRam;

    signal StackArea_Adr : std_logic_vector(23 downto 0);
    signal StackArea_Sel : std_logic_vector(3 downto 0);
    signal StackArea_We : std_logic;
    signal StackArea_Stb : std_logic;
    signal StackArea_DatOut : std_logic_vector(31 downto 0);
    signal StackArea_DatIn: std_logic_vector(31 downto 0);
    signal StackArea_Ack : std_logic;
    signal StackArea_Cyc : std_logic_vector(0 downto 0);

    signal StackMemory_Adr : std_logic_vector(23 downto 0);
    signal StackMemory_Sel : std_logic_vector(3 downto 0);
    signal StackMemory_We : std_logic;
    signal StackMemory_Stb : std_logic;
    signal StackMemory_DatOut : std_logic_vector(31 downto 0);
    signal StackMemory_DatIn: std_logic_vector(31 downto 0);
    signal StackMemory_Ack : std_logic;
    signal StackMemory_Cyc : std_logic_vector(0 downto 0);

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

    tb_FileIo_i : entity work.tb_FileIo
        generic map (
            stimulus_path => stimulus_path,
            stimulus_file => stimulus_file
        )
        port map (
            Clk => Clk100M,
            Rst => Rst,
            WasmFpgaStack_FileIo => WasmFpgaStack_FileIo,
            FileIo_WasmFpgaStack => FileIo_WasmFpgaStack,
            WbRam_FileIo => WbRam_FileIo,
            FileIo_WbRam => FileIo_WbRam
        );

    StackArea_Adr <= FileIo_WbRam.Adr when FileIo_WbRam.Cyc = "1" else StackMemory_Adr;
    StackArea_Sel <= FileIo_WbRam.Sel when FileIo_WbRam.Cyc = "1" else StackMemory_Sel;
    StackArea_DatIn <= FileIo_WbRam.DatIn when FileIo_WbRam.Cyc = "1" else StackMemory_DatIn;
    StackArea_We <= FileIo_WbRam.We when FileIo_WbRam.Cyc = "1" else StackMemory_We;
    StackArea_Stb <= FileIo_WbRam.Stb when FileIo_WbRam.Cyc = "1" else StackMemory_Stb;
    StackArea_Cyc <= FileIo_WbRam.Cyc when FileIo_WbRam.Cyc = "1" else StackMemory_Cyc;

    WbRam_FileIo.DatOut <= StackArea_DatOut;
    WbRam_FileIo.Ack <= StackArea_Ack;

    StackMemory_DatOut <= StackArea_DatOut;
    StackMemory_Ack <= StackArea_Ack;

    WbRam_i : entity work.WbRam
        port map (
            Clk => Clk100M,
            nRst => nRst,
            Adr => StackArea_Adr,
            Sel => StackArea_Sel,
            DatIn => StackArea_DatIn,
            We => StackArea_We,
            Stb => StackArea_Stb,
            Cyc => StackArea_Cyc,
            DatOut => StackArea_DatOut,
            Ack => StackArea_Ack
        );

    WasmFpgaStack_i : entity work.WasmFpgaStack
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
            Ack => WasmFpgaStack_FileIo.Ack,
            Stack_Adr => StackMemory_Adr,
            Stack_Sel => StackMemory_Sel,
            Stack_We => StackMemory_We,
            Stack_Stb => StackMemory_Stb,
            Stack_DatOut => StackMemory_DatIn,
            Stack_DatIn => StackMemory_DatOut,
            Stack_Ack => StackMemory_Ack,
            Stack_Cyc => StackMemory_Cyc
       );

end;
