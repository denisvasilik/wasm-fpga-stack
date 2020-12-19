

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.WasmFpgaStackWshBn_Package.all;

entity tb_WasmFpgaStackWshBn is
end tb_WasmFpgaStackWshBn;

architecture arch_for_test of tb_WasmFpgaStackWshBn is

    component tbs_WshFileIo is
    generic (
         inp_file  : string;
         outp_file : string
        );
    port(
        clock        : in    std_logic;
        reset        : in    std_logic;
        WshDn        : out   T_WshDn;
        WshUp        : in    T_WshUp
        );
    end component;



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


    signal Clk : std_logic := '0';
    signal Rst : std_logic := '1';



    signal WshDn : T_WshDn;
    signal WshUp : T_WshUp;
    signal Wsh_UnOccpdRcrd : T_Wsh_UnOccpdRcrd;
    signal Wsh_StackBlk : T_Wsh_StackBlk;
    signal StackBlk_Wsh : T_StackBlk_Wsh;



begin


    i_tbs_WshFileIo : tbs_WshFileIo
    generic map (
        inp_file  => "tb_mC_stimuli.txt",
        outp_file => "src/tb_mC_trace.txt")
    port map (
        clock   => Clk,
        reset   => Rst,
        WshDn   => WshDn,
        WshUp   => WshUp
    );



    -- ---------- map wishbone component ----------

    i_WasmFpgaStackWshBn :  WasmFpgaStackWshBn
     port map (
        WshDn => WshDn,
        WshUp => WshUp,
        Wsh_UnOccpdRcrd => Wsh_UnOccpdRcrd,
        Wsh_StackBlk => Wsh_StackBlk,
        StackBlk_Wsh => StackBlk_Wsh
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



    WshDn.Clk <= Clk;
    WshDn.Rst <= Rst;
    -- ---------- drive testbench time --------------------
    Clk   <= TRANSPORT NOT Clk AFTER 12500 ps;  -- 40Mhz
    Rst   <= TRANSPORT '0' AFTER 100 ns;


end architecture;
