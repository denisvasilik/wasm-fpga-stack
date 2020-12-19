

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

library work;
use work.WasmFpgaStackWshBn_Package.all;

entity tb_WshBnWasmFpgaStack_Top is
generic (
       stimulus_file: string := "src_hdl_tb/stimuli_FileIo/init.stm"
      );
end tb_WshBnWasmFpgaStack_Top;

architecture arch_for_test of tb_WshBnWasmFpgaStack_Top is

    component tb_WshBn_FileIo is
        generic (
         		stimulus_file: string;
                tb_clk_freq_period_half : time;
                tb_num_dflt_clk_ack_timeout : natural;
                tb_address_width : natural;
                tb_cyc_width : natural
        );
        port (
            WshBnRst     : in   std_logic;
            WshBnClk     : in   std_logic;
            WshBnAdr     : out   std_logic_vector(tb_address_width-1 downto 0);
            WshBnSel     : out   std_logic_vector(3 downto 0);
            WshBnDatIn   : out   std_logic_vector(31 downto 0);
            WshBnWe      : out   std_logic;
            WshBnStb     : out   std_logic;
            WshBnCyc     : out   std_logic_vector(tb_cyc_width-1 downto 0);
            WshBnDatOut  : in    std_logic_vector(31 downto 0);
            WshBnAck     : in    std_logic
        );
    end component;

    component tb_WshBnClkRstGen is
       generic (
            OscPeriod : time;
            NumOfClksRstInitialActive : natural
        );
       port (
            Rst : out std_logic;
            Clk : out std_logic
       );
    end component;

    constant tb_clk_freq_period_half : time := 5 ns;
    constant tb_num_dflt_clk_ack_timeout : natural := 16;
    constant tb_address_width : natural := 24;
    constant tb_cyc_width : natural := 1;

    signal Rst          : std_logic := '0';
    signal Clk          : std_logic := '0';
    signal WshBnAdr     : std_logic_vector(tb_address_width-1 downto 0);
    signal WshBnDatIn   : std_logic_vector(31 downto 0);
    signal WshBnWe      : std_logic;
    signal WshBnStb     : std_logic;
    signal WshBnCyc     : std_logic_vector(tb_cyc_width-1 downto 0);
    signal WshBnDatOut  : std_logic_vector(31 downto 0);
    signal WshBnAck     : std_logic;


    component WasmFpgaStackWshBn is
        port (
            Clk : in std_logic;
            Rst : in std_logic;
            WasmFpgaStackWshBnDn : in T_WasmFpgaStackWshBnDn;
            WasmFpgaStackWshBnUp : out T_WasmFpgaStackWshBnUp;
            WasmFpgaStackWshBn_UnOccpdRcrd : out T_WasmFpgaStackWshBn_UnOccpdRcrd;
            WasmFpgaStackWshBn_StackBlk : out T_WasmFpgaStackWshBn_StackBlk;
            StackBlk_WasmFpgaStackWshBn : in T_StackBlk_WasmFpgaStackWshBn
         );
    end component;


    signal WshDn : T_WasmFpgaStackWshBnDn;
    signal WshUp : T_WasmFpgaStackWshBnUp;
    signal Wsh_UnOccpdRcrd : T_WasmFpgaStackWshBn_UnOccpdRcrd;
    signal Wsh_StackBlk : T_WasmFpgaStackWshBn_StackBlk;
    signal StackBlk_Wsh : T_StackBlk_WasmFpgaStackWshBn;



begin


    -- connect wishbone to testbench
    WshDn.Adr   <=  WshBnAdr  ;
    WshDn.DatIn <=  WshBnDatIn;
    WshDn.We    <=  WshBnWe   ;
    WshDn.Stb   <=  WshBnStb  ;
    WshDn.Cyc        <= WshBnCyc;
    WshBnDatOut  <= WshUp.DatOut;
    WshBnAck     <= WshUp.Ack   ;

    -- ---------- map clock and reset generator component ----------
    i_tb_WshBnClkRstGen : tb_WshBnClkRstGen
    generic map(
        OscPeriod => tb_clk_freq_period_half * 2,
        NumOfClksRstInitialActive => 16
    )
    port map (
        Rst => Rst,
        Clk => Clk
    );

    -- ---------- map wishbone fileio component ----------
    i_tb_WshBn_FileIo : tb_WshBn_FileIo
    generic map(
    	stimulus_file => stimulus_file,
        tb_clk_freq_period_half => tb_clk_freq_period_half,
        tb_num_dflt_clk_ack_timeout => tb_num_dflt_clk_ack_timeout,
        tb_address_width => tb_address_width,
        tb_cyc_width => tb_cyc_width
    )
    port map (
        WshBnRst        => Rst,
        WshBnClk        => Clk,
        WshBnAdr        => WshBnAdr,
        WshBnDatIn      => WshBnDatIn,
        WshBnWe         => WshBnWe,
        WshBnStb        => WshBnStb,
        WshBnCyc        => WshBnCyc,
        WshBnDatOut     => WshBnDatOut,
        WshBnAck        => WshBnAck
    );

    -- ---------- map wishbone component ----------


    -- ---------- map wishbone component ----------

    i_WasmFpgaStackWshBn :  WasmFpgaStackWshBn
     port map (
        Rst => Rst,
        Clk => Clk,
        WasmFpgaStackWshBnDn => WshDn,
        WasmFpgaStackWshBnUp => WshUp,
        WasmFpgaStackWshBN_UnOccpdRcrd => Wsh_UnOccpdRcrd,
        WasmFpgaStackWshBn_StackBlk => Wsh_StackBlk,
        StackBlk_WasmFpgaStackWshBn => StackBlk_Wsh
        );

    -- ---------- assign defaults to all wishbone inputs ----------

    -- ------------------- general additional signals -------------------

    -- ------------------- StackBlk -------------------
    -- ControlReg
    -- StatusReg
    StackBlk_Wsh.Busy <= '0';
    -- SizeReg
    StackBlk_Wsh.SizeValue <= (others => '0');
    -- HighValueReg
    StackBlk_Wsh.HighValue_ToBeRead <= (others => '0');
    -- LowValueReg
    StackBlk_Wsh.LowValue_ToBeRead <= (others => '0');
    -- TypeReg
    StackBlk_Wsh.Type_ToBeRead <= (others => '0');
    -- LocalIndexReg
    -- StackAddressReg
    StackBlk_Wsh.StackAddress_ToBeRead <= (others => '0');



end architecture;
