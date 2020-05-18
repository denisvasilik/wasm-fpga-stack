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
        Ack : out std_logic;
        Stack_Adr : out std_logic_vector(23 downto 0);
        Stack_Sel : out std_logic_vector(3 downto 0);
        Stack_We : out std_logic;
        Stack_Stb : out std_logic;
        Stack_DatOut : out std_logic_vector(31 downto 0);
        Stack_DatIn: in std_logic_vector(31 downto 0);
        Stack_Ack : in std_logic;
        Stack_Cyc : out std_logic_vector(0 downto 0)
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
      Action : out std_logic_vector(1 downto 0);
      ValueType : out std_logic_vector(2 downto 0);
      Busy : in std_logic;
      SizeValue : in std_logic_vector(31 downto 0);
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
  signal Action : std_logic_vector(1 downto 0);
  signal ValueType : std_logic_vector(2 downto 0);
  signal Busy : std_logic;
  signal SizeValue : std_logic_vector(31 downto 0);
  signal HighValue_ToBeRead : std_logic_vector(31 downto 0);
  signal HighValue_Written : std_logic_vector(31 downto 0);
  signal LowValue_ToBeRead : std_logic_vector(31 downto 0);
  signal LowValue_Written : std_logic_vector(31 downto 0);

  signal MaskedAdr : std_logic_vector(23 downto 0);

  signal StackBlk_Ack : std_logic;
  signal StackBlk_DatOut : std_logic_vector(31 downto 0);
  signal StackBlk_Unoccupied_Ack : std_logic;

  signal StackState : std_logic_vector(7 downto 0);

  signal StackAddress : std_logic_vector(23 downto 0);

  constant StackStateIdle0 : std_logic_vector(7 downto 0) := x"00";
  constant StackStatePush32Bit0 : std_logic_vector(7 downto 0) := x"01";
  constant StackStatePop32Bit0 : std_logic_vector(7 downto 0) := x"02";
  constant StackStatePush64Bit0 : std_logic_vector(7 downto 0) := x"05";
  constant StackStatePush64Bit1 : std_logic_vector(7 downto 0) := x"06";
  constant StackStatePush64Bit2 : std_logic_vector(7 downto 0) := x"07";
  constant StackStatePop64Bit0 : std_logic_vector(7 downto 0) := x"08";
  constant StackStatePop64Bit1 : std_logic_vector(7 downto 0) := x"09";
  constant StackStatePop64Bit2 : std_logic_vector(7 downto 0) := x"0A";


  constant WASMFPGASTORE_ADR_BLK_MASK_StackBlk : std_logic_vector(23 downto 0) := x"00003F";

begin

  Rst <= not nRst;

  Ack <= StackBlk_Ack;
  DatOut <= StackBlk_DatOut;

  MaskedAdr <= Adr and WASMFPGASTORE_ADR_BLK_MASK_StackBlk;

  Stack_Adr <= StackAddress;

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
      Stack_Cyc <= (others => '0');
      Stack_Stb <= '0';
      Stack_Sel <= (others => '1');
      Stack_We <= '0';
      StackAddress <= (others => '0');
      Stack_DatOut <= (others => '0');
      LowValue_ToBeRead <= (others => '0');
      HighValue_ToBeRead <= (others => '0');
      SizeValue <= (others => '0');
      StackState <= StackStateIdle0;
    elsif rising_edge(Clk) then
      if(StackState = StackStateIdle0) then
        Busy <= '0';
        Stack_Cyc <= (others => '0');
        Stack_Stb <= '0';
        Stack_We <= '0';
        if (Run = '1' and Action = WASMFPGASTACK_VAL_Clear) then
            StackState <= StackStateIdle0;
        elsif (Run = '1' and Action = WASMFPGASTACK_VAL_Push) then
          if (ValueType = WASMFPGASTACK_VAL_i32 or
              ValueType = WASMFPGASTACK_VAL_f32 or
              ValueType = WASMFPGASTACK_VAL_Label or
              ValueType = WASMFPGASTACK_VAL_Activation) then
            Busy <= '1';
            Stack_Cyc <= "1";
            Stack_Stb <= '1';
            Stack_We <= '1';
            Stack_DatOut <= LowValue_Written;
            SizeValue <= std_logic_vector(unsigned(SizeValue) + to_unsigned(1, SizeValue'LENGTH));
            StackState <= StackStatePush32Bit0;
          elsif(ValueType = WASMFPGASTACK_VAL_i64 or
                ValueType = WASMFPGASTACK_VAL_f64) then
            Busy <= '1';
            Stack_Cyc <= "1";
            Stack_Stb <= '1';
            Stack_We <= '1';
            Stack_DatOut <= LowValue_Written;
            SizeValue <= std_logic_vector(unsigned(SizeValue) + to_unsigned(1, SizeValue'LENGTH));
            StackState <= StackStatePush64Bit0;
          end if;
        elsif(Run = '1' and Action = WASMFPGASTACK_VAL_Pop) then
          if (ValueType = WASMFPGASTACK_VAL_i32 or
              ValueType = WASMFPGASTACK_VAL_f32 or
              ValueType = WASMFPGASTACK_VAL_Label or
              ValueType = WASMFPGASTACK_VAL_Activation) then
            Busy <= '1';
            Stack_Cyc <= "1";
            Stack_Stb <= '1';
            Stack_We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
            SizeValue <= std_logic_vector(unsigned(SizeValue) - to_unsigned(1, SizeValue'LENGTH));
            StackState <= StackStatePop32Bit0;
          elsif(ValueType = WASMFPGASTACK_VAL_i64 or
                ValueType = WASMFPGASTACK_VAL_f64) then
            Busy <= '1';
            Stack_Cyc <= "1";
            Stack_Stb <= '1';
            Stack_We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
            SizeValue <= std_logic_vector(unsigned(SizeValue) - to_unsigned(1, SizeValue'LENGTH));
            StackState <= StackStatePop64Bit0;
          end if;
        end if;
      --
      -- Push 32 Bit
      --
      elsif(StackState = StackStatePush32Bit0) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStateIdle0;
        end if;
      --
      -- Push 64 Bit
      --
      elsif(StackState = StackStatePush64Bit0) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStatePush64Bit1;
        end if;
      elsif(StackState = StackStatePush64Bit1) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        Stack_DatOut <= HighValue_Written;
        StackState <= StackStatePush64Bit2;
      elsif(StackState = StackStatePush64Bit2) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStateIdle0;
        end if;
      --
      -- Pop 32 Bit
      --
      elsif(StackState = StackStatePop32Bit0) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          LowValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStateIdle0;
        end if;
      --
      -- Pop 64 Bit
      --
      elsif(StackState = StackStatePop64Bit0) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          HighValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStatePop64Bit1;
        end if;
      elsif(StackState = StackStatePop64Bit1) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
        StackState <= StackStatePop64Bit2;
      elsif(StackState = StackStatePop64Bit2) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          LowValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStateIdle0;
        end if;
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
      SizeValue => SizeValue,
      HighValue_ToBeRead => HighValue_ToBeRead,
      HighValue_Written => HighValue_Written,
      LowValue_ToBeRead => LowValue_ToBeRead,
      LowValue_Written => LowValue_Written
    );

end;