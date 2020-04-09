library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.WasmFpgaStackWshBn_Package.all;

entity WasmFpgaStack is
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
end entity WasmFpgaStack;

architecture WasmFpgaStackArchitecture of WasmFpgaStack is

  component StackBlk_WasmFpgaStack is
    port (
      Clk : in std_logic;
      Rst : in std_logic;
      Adr : in std_logic_vector(23 downto 0);
      Sel : in std_logic_vector(3 downto 0);
      DatIn : in std_logic_vector(31 downto 0);
      We : in std_logic;
      Stb : in std_logic;
      Cyc : in  std_logic_vector(0 downto 0);
      StackBlk_DatOut : out std_logic_vector(31 downto 0);
      StackBlk_Ack : out std_logic;
      StackBlk_Unoccupied_Ack : out std_logic;
      Run : out std_logic;
      Action : out std_logic;
      ValueType : out std_logic_vector(2 downto 0);
      Busy : in std_logic;
      HighValue_ToBeRead : in std_logic_vector(31 downto 0);
      HighValue_Written : out std_logic_vector(31 downto 0);
      LowValue_ToBeRead : in std_logic_vector(31 downto 0);
      LowValue_Written : out std_logic_vector(31 downto 0)
    );
  end component;

  component WasmFpgaStackRam is
    port (
      clka : in std_logic;
      ena : in std_logic;
      wea : in std_logic_vector(0 downto 0);
      addra : in std_logic_vector(9 downto 0);
      dina : in std_logic_vector(31 downto 0);
      douta : out std_logic_vector(31 downto 0);
      clkb : in std_logic;
      enb : in std_logic;
      web : in std_logic_vector(0 downto 0);
      addrb : in std_logic_vector(9 downto 0);
      dinb : in std_logic_vector(31 downto 0);
      doutb : out std_logic_vector(31 downto 0)
    );
  end component;

  signal Rst : std_logic;
  signal Run : std_logic;
  signal CurrentRun : std_logic;
  signal PreviousRun : std_logic;
  signal Action : std_logic;
  signal ValueType : std_logic_vector(2 downto 0);
  signal Busy : std_logic;
  signal HighValue_ToBeRead : std_logic_vector(31 downto 0);
  signal HighValue_Written : std_logic_vector(31 downto 0);
  signal LowValue_ToBeRead : std_logic_vector(31 downto 0);
  signal LowValue_Written : std_logic_vector(31 downto 0);

  signal MaskedAdr : std_logic_vector(23 downto 0);

  signal RamEnable : std_logic;
  signal RamWriteEnable : std_logic_vector(0 downto 0);
  signal RamAddress : std_logic_vector(9 downto 0);
  signal RamDataIn : std_logic_vector(31 downto 0);
  signal RamDataOut : std_logic_vector(31 downto 0);

  signal StackBlk_Ack : std_logic;
  signal StackBlk_DatOut : std_logic_vector(31 downto 0);
  signal StackBlk_Unoccupied_Ack : std_logic;

  signal StackState : std_logic_vector(7 downto 0);

  constant StackStateIdle0 : std_logic_vector(7 downto 0) := x"00";
  constant StackStatePush32Bit0 : std_logic_vector(7 downto 0) := x"01";
  constant StackStatePop32Bit0 : std_logic_vector(7 downto 0) := x"02";
  constant StackStatePop32Bit1 : std_logic_vector(7 downto 0) := x"03";
  constant StackStatePop32Bit2 : std_logic_vector(7 downto 0) := x"04";
  constant StackStatePush64Bit0 : std_logic_vector(7 downto 0) := x"05";
  constant StackStatePush64Bit1 : std_logic_vector(7 downto 0) := x"06";
  constant StackStatePush64Bit2 : std_logic_vector(7 downto 0) := x"07";
  constant StackStatePop64Bit0 : std_logic_vector(7 downto 0) := x"08";
  constant StackStatePop64Bit1 : std_logic_vector(7 downto 0) := x"09";
  constant StackStatePop64Bit2 : std_logic_vector(7 downto 0) := x"0A";
  constant StackStatePop64Bit3 : std_logic_vector(7 downto 0) := x"0B";
  constant StackStatePop64Bit4 : std_logic_vector(7 downto 0) := x"0C";
  constant StackStatePop64Bit5 : std_logic_vector(7 downto 0) := x"0D";

  constant WASMFPGASTORE_ADR_BLK_MASK_StackBlk : std_logic_vector(23 downto 0) := x"00000F";

begin

  Rst <= not nRst;

  Ack <= StackBlk_Ack;
  DatOut <= StackBlk_DatOut;

  MaskedAdr <= Adr and WASMFPGASTORE_ADR_BLK_MASK_StackBlk;
  
  process (Clk, Rst) is
  begin
    if (Rst = '1') then
      Run <= '0';
      PreviousRun <= '0';
    elsif rising_edge(Clk) then
      Run <= '0';
      PreviousRun <= CurrentRun;
      if (PreviousRun /= CurrentRun and CurrentRun = '1') then
        Run <= '1';
      end if;
    end if;
  end process;

  Stack : process (Clk, Rst) is
  begin
    if (Rst = '1') then
      Busy <= '1';
      RamEnable <= '0';
      RamWriteEnable <= "0";
      RamDataIn <= (others => '0');
      RamAddress <= (others => '0');
      LowValue_ToBeRead <= (others => '0');
      HighValue_ToBeRead <= (others => '0');
      StackState <= StackStateIdle0;
    elsif rising_edge(Clk) then
      if(StackState = StackStateIdle0) then
        Busy <= '0';
        RamEnable <= '0';
        RamWriteEnable <= "0";
        if (Run = '1' and Action = WASMFPGASTACK_VAL_Push) then
          if (ValueType = WASMFPGASTACK_VAL_i32 or
              ValueType = WASMFPGASTACK_VAL_f32 or 
              ValueType = WASMFPGASTACK_VAL_Label or
              ValueType = WASMFPGASTACK_VAL_Activation) then
            Busy <= '1';
            RamEnable <= '1';
            RamWriteEnable <= "1";
            RamDataIn <= LowValue_Written;
            StackState <= StackStatePush32Bit0;
          elsif(ValueType = WASMFPGASTACK_VAL_i64 or
                ValueType = WASMFPGASTACK_VAL_f64) then
            Busy <= '1';
            RamEnable <= '1';
            RamWriteEnable <= "1";
            RamDataIn <= LowValue_Written;
            StackState <= StackStatePush64Bit0;
          end if;
        elsif(Run = '1' and Action = WASMFPGASTACK_VAL_Pop) then
          if (ValueType = WASMFPGASTACK_VAL_i32 or
              ValueType = WASMFPGASTACK_VAL_f32 or 
              ValueType = WASMFPGASTACK_VAL_Label or
              ValueType = WASMFPGASTACK_VAL_Activation) then
            Busy <= '1';
            RamEnable <= '1';
            RamAddress <= std_logic_vector(unsigned(RamAddress) - to_unsigned(4, RamAddress'LENGTH));
            StackState <= StackStatePop32Bit0;
          elsif(ValueType = WASMFPGASTACK_VAL_i64 or
                ValueType = WASMFPGASTACK_VAL_f64) then
            Busy <= '1';
            RamEnable <= '1';
            RamAddress <= std_logic_vector(unsigned(RamAddress) - to_unsigned(4, RamAddress'LENGTH));
            StackState <= StackStatePop64Bit0;
          end if;
        end if;
      --
      -- Push 32 Bit
      --
      elsif(StackState = StackStatePush32Bit0) then
        RamWriteEnable <= "0";
        RamAddress <= std_logic_vector(unsigned(RamAddress) + to_unsigned(4, RamAddress'LENGTH));
        StackState <= StackStateIdle0;
      --
      -- Push 64 Bit
      --
      elsif(StackState = StackStatePush64Bit0) then
        RamWriteEnable <= "0";
        RamAddress <= std_logic_vector(unsigned(RamAddress) + to_unsigned(4, RamAddress'LENGTH));
        StackState <= StackStatePush64Bit1;
      elsif(StackState = StackStatePush64Bit1) then
        RamWriteEnable <= "1";
        RamDataIn <= HighValue_Written;
        StackState <= StackStatePush64Bit2;
      elsif(StackState = StackStatePush64Bit2) then
        RamWriteEnable <= "0";
        RamAddress <= std_logic_vector(unsigned(RamAddress) + to_unsigned(4, RamAddress'LENGTH));
        StackState <= StackStateIdle0;
      --
      -- Pop 32 Bit
      --
      elsif(StackState = StackStatePop32Bit0) then
        StackState <= StackStatePop32Bit1;
      elsif(StackState = StackStatePop32Bit1) then
        StackState <= StackStatePop32Bit2;
      elsif(StackState = StackStatePop32Bit2) then
        LowValue_ToBeRead <= RamDataOut;
        StackState <= StackStateIdle0;
      --
      -- Pop 64 Bit
      --
      elsif(StackState = StackStatePop64Bit0) then
        StackState <= StackStatePop64Bit1;
      elsif(StackState = StackStatePop64Bit1) then
        StackState <= StackStatePop64Bit2;
      elsif(StackState = StackStatePop64Bit2) then
        HighValue_ToBeRead <= RamDataOut;
        RamAddress <= std_logic_vector(unsigned(RamAddress) - to_unsigned(4, RamAddress'LENGTH));
        StackState <= StackStatePop64Bit3;
      elsif(StackState = StackStatePop64Bit3) then
        StackState <= StackStatePop64Bit4;
      elsif(StackState = StackStatePop64Bit4) then
        StackState <= StackStatePop64Bit5;
      elsif(StackState = StackStatePop64Bit5) then
        LowValue_ToBeRead <= RamDataOut;
        StackState <= StackStateIdle0;
      end if;
    end if;
  end process;

  StackBlk_WasmFpgaStack_i : StackBlk_WasmFpgaStack
    port map (
      Clk => Clk,
      Rst => Rst,
      Adr => MaskedAdr,
      Sel => Sel,
      DatIn => DatIn,
      We => We,
      Stb => Stb,
      Cyc => Cyc,
      StackBlk_DatOut => StackBlk_DatOut,
      StackBlk_Ack => StackBlk_Ack,
      StackBlk_Unoccupied_Ack => StackBlk_Unoccupied_Ack,
      Run => CurrentRun,
      Action => Action,
      ValueType => ValueType,
      Busy => Busy,
      HighValue_ToBeRead => HighValue_ToBeRead,
      HighValue_Written => HighValue_Written,
      LowValue_ToBeRead => LowValue_ToBeRead,
      LowValue_Written => LowValue_Written
    );

    WasmFpgaStackRam_i : WasmFpgaStackRam
      port map (
        clka => Clk,
        ena => RamEnable,
        wea => RamWriteEnable,
        addra => RamAddress,
        dina => RamDataIn,
        douta => RamDataOut,
        clkb => Clk,
        enb => '0',
        web => (others => '0'),
        addrb => (others => '0'),
        dinb => (others => '0'),
        doutb => open
      );

end;