library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.WasmFpgaStackPackage.all;
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
        Stack_Cyc : out std_logic_vector(0 downto 0);
        Trap : out std_logic
    );
end;

architecture WasmFpgaStackArchitecture of WasmFpgaStack is

  signal Rst : std_logic;
  signal Run : std_logic;
  signal WRegPulse_ControlReg : std_logic;
  signal Action : std_logic_vector(2 downto 0);
  signal Busy : std_logic;
  signal SizeValue : std_logic_vector(31 downto 0);
  signal HighValue_ToBeRead : std_logic_vector(31 downto 0);
  signal HighValue_Written : std_logic_vector(31 downto 0);
  signal LowValue_ToBeRead : std_logic_vector(31 downto 0);
  signal LowValue_Written : std_logic_vector(31 downto 0);
  signal Type_ToBeRead : std_logic_vector(2 downto 0);
  signal Type_Written : std_logic_vector(2 downto 0);
  signal LocalIndex : std_logic_vector(31 downto 0);
  signal ModuleInstanceUid : std_logic_vector(31 downto 0);

  signal MaskedAdr : std_logic_vector(23 downto 0);

  signal StackBlk_Ack : std_logic;
  signal StackBlk_DatOut : std_logic_vector(31 downto 0);
  signal StackBlk_Unoccupied_Ack : std_logic;

  signal StackState : std_logic_vector(7 downto 0);
  signal ReturnStackState : std_logic_vector(7 downto 0);

  signal StackAddress : std_logic_vector(23 downto 0);
  signal StackLowValue : std_logic_vector(31 downto 0);
  signal StackType : std_logic_vector(31 downto 0);
  signal StackAddress_ToBeRead : std_logic_vector(31 downto 0);
  signal StackAddress_Written : std_logic_vector(31 downto 0);
  signal WRegPulse_StackAddressReg : std_logic;
  signal RestoreStackAddress : std_logic_vector(23 downto 0);
  signal CurrentActivationFrameAddress : std_logic_vector(23 downto 0);
  signal MaxLocals : std_logic_vector(31 downto 0);
  signal MaxResults : std_logic_vector(31 downto 0);
  signal ReturnAddress : std_logic_vector(31 downto 0);

  constant WASMFPGASTORE_ADR_BLK_MASK_StackBlk : std_logic_vector(23 downto 0) := x"00003F";

  constant ActivationFrameSize : std_logic_vector(23 downto 0) := x"000004";
  constant TypeValueOffset : std_logic_vector(23 downto 0) := x"000002";

  signal ActivationFrameState : std_logic_vector(15 downto 0);
  signal PushToStackState : std_logic_vector(15 downto 0);
  signal PopFromStackState : std_logic_vector(15 downto 0);

  signal ToStackMemory : T_ToWishbone;
  signal FromStackMemory : T_FromWishbone;

begin

  Rst <= not nRst;

  Ack <= StackBlk_Ack;
  DatOut <= StackBlk_DatOut;

  MaskedAdr <= Adr and WASMFPGASTORE_ADR_BLK_MASK_StackBlk;

  StackAddress_ToBeRead <= x"00" & StackAddress;

  Stack_Adr <= StackAddress;
  Stack_Sel <= ToStackMemory.Sel;
  Stack_DatOut <= ToStackMemory.DatIn;
  Stack_We <= ToStackMemory.We;
  Stack_Stb <= ToStackMemory.Stb;
  Stack_Cyc <= ToStackMemory.Cyc;

  FromStackMemory.DatOut <= Stack_DatIn;
  FromStackMemory.Ack <= Stack_Ack;

  Stack : process (Clk, Rst) is
    constant StackStateIdle0 : std_logic_vector(7 downto 0) := x"00";
    constant StackStatePush32Bit0 : std_logic_vector(7 downto 0) := x"01";
    constant StackStatePush32Bit1 : std_logic_vector(7 downto 0) := x"02";
    constant StackStatePop32Bit0 : std_logic_vector(7 downto 0) := x"03";
    constant StackStatePop32Bit1 : std_logic_vector(7 downto 0) := x"04";
    constant StackStatePush64Bit0 : std_logic_vector(7 downto 0) := x"05";
    constant StackStatePush64Bit1 : std_logic_vector(7 downto 0) := x"06";
    constant StackStatePush64Bit2 : std_logic_vector(7 downto 0) := x"07";
    constant StackStatePush64Bit3 : std_logic_vector(7 downto 0) := x"08";
    constant StackStatePop64Bit0 : std_logic_vector(7 downto 0) := x"09";
    constant StackStatePop64Bit1 : std_logic_vector(7 downto 0) := x"0A";
    constant StackStatePop64Bit2 : std_logic_vector(7 downto 0) := x"0B";
    constant StackStatePop64Bit3 : std_logic_vector(7 downto 0) := x"0C";
    constant StackStatePushType0 : std_logic_vector(7 downto 0) := x"0D";
    constant StackStatePushType1 : std_logic_vector(7 downto 0) := x"0E";
    constant StackStatePushType2 : std_logic_vector(7 downto 0) := x"0F";
    constant StackStatePopType0 : std_logic_vector(7 downto 0) := x"10";
    constant StackStatePopType1 : std_logic_vector(7 downto 0) := x"11";
    constant StackStatePopType2 : std_logic_vector(7 downto 0) := x"12";
    constant StackStateLocalGet0 : std_logic_vector(7 downto 0) := x"13";
    constant StackStateLocalGet1 : std_logic_vector(7 downto 0) := x"14";
    constant StackStateLocalGet2 : std_logic_vector(7 downto 0) := x"15";
    constant StackStateLocalGet3 : std_logic_vector(7 downto 0) := x"16";
    constant StackStateLocalGet4 : std_logic_vector(7 downto 0) := x"17";
    constant StackStateLocalGet5 : std_logic_vector(7 downto 0) := x"18";
    constant StackStateLocalGet6 : std_logic_vector(7 downto 0) := x"19";
    constant StackStateLocalGet7 : std_logic_vector(7 downto 0) := x"1A";
    constant StackStateLocalGet8 : std_logic_vector(7 downto 0) := x"1B";
    constant StackStateLocalGet9 : std_logic_vector(7 downto 0) := x"1C";
    constant StackStateLocalGet10 : std_logic_vector(7 downto 0) := x"1D";
    constant StackStateLocalGet11 : std_logic_vector(7 downto 0) := x"1E";
    constant StackStateLocalSet0 : std_logic_vector(7 downto 0) := x"20";
    constant StackStateLocalSet1 : std_logic_vector(7 downto 0) := x"21";
    constant StackStateLocalSet2 : std_logic_vector(7 downto 0) := x"22";
    constant StackStateLocalSet3 : std_logic_vector(7 downto 0) := x"23";
    constant StackStateLocalSet4 : std_logic_vector(7 downto 0) := x"24";
    constant StackStateLocalSet5 : std_logic_vector(7 downto 0) := x"25";
    constant StackStateLocalSet6 : std_logic_vector(7 downto 0) := x"26";
    constant StackStateLocalSet7 : std_logic_vector(7 downto 0) := x"27";
    constant StackStateLocalSet8 : std_logic_vector(7 downto 0) := x"28";
    constant StackStateActivationFrame0 : std_logic_vector(7 downto 0) := x"29";
    constant StackStateActivationFrame1 : std_logic_vector(7 downto 0) := x"2A";
    constant StackStateActivationFrame2 : std_logic_vector(7 downto 0) := x"2B";
    constant StackStateActivationFrame3 : std_logic_vector(7 downto 0) := x"2C";
    constant StackStateActivationFrame4 : std_logic_vector(7 downto 0) := x"2D";
    constant StackStateActivationFrame5 : std_logic_vector(7 downto 0) := x"2E";
    constant StackStateActivationFrame6 : std_logic_vector(7 downto 0) := x"2F";
    constant StackStateActivationFrame7 : std_logic_vector(7 downto 0) := x"30";
    constant StackStateError : std_logic_vector(7 downto 0) := x"FF";
  begin
    if (Rst = '1') then
      Busy <= '1';
      Trap <= '0';
      ToStackMemory <= (
          Adr => (others => '0'),
          Sel => (others => '1'),
          DatIn => (others => '0'),
          We => '0',
          Stb => '0',
          Cyc => (others => '0')
      );
      StackLowValue <= (others => '0');
      StackType <= (others => '0');
      RestoreStackAddress <= (others => '0');
      StackAddress <= (others => '0');
      LowValue_ToBeRead <= (others => '0');
      HighValue_ToBeRead <= (others => '0');
      Type_ToBeRead <= (others => '0');
      SizeValue <= (others => '0');
      CurrentActivationFrameAddress <= (others => '0');
      ActivationFrameState <= StateIdle;
      PushToStackState <= StateIdle;
      PopFromStackState <= StateIdle;
      StackState <= StackStateIdle0;
      ReturnStackState <= StackStateIdle0;
    elsif rising_edge(Clk) then
      if(StackState = StackStateIdle0) then
        Busy <= '0';
        ToStackMemory.Cyc <= (others => '0');
        ToStackMemory.Stb <= '0';
        ToStackMemory.We <= '0';
        if (WRegPulse_StackAddressReg = '1') then
            StackAddress <= StackAddress_Written(23 downto 0);
        end if;
        if (WRegPulse_ControlReg = '1' and Run = '1') then
            Busy <= '1';
            if (Action = WASMFPGASTACK_VAL_Push) then
                if (Type_Written = WASMFPGASTACK_VAL_i32 or
                    Type_Written = WASMFPGASTACK_VAL_f32 or
                    Type_Written = WASMFPGASTACK_VAL_Label or
                    Type_Written = WASMFPGASTACK_VAL_Activation) then
                    StackState <= StackStatePush32Bit0;
                elsif(Type_Written = WASMFPGASTACK_VAL_i64 or
                      Type_Written = WASMFPGASTACK_VAL_f64) then
                    StackState <= StackStatePush64Bit0;
                else
                    StackState <= StackStateError;
                end if;
            elsif(Action = WASMFPGASTACK_VAL_Pop) then
                if (Type_Written = WASMFPGASTACK_VAL_i32 or
                    Type_Written = WASMFPGASTACK_VAL_f32 or
                    Type_Written = WASMFPGASTACK_VAL_Label or
                    Type_Written = WASMFPGASTACK_VAL_Activation) then
                    StackState <= StackStatePop32Bit0;
                elsif(Type_Written = WASMFPGASTACK_VAL_i64 or
                      Type_Written = WASMFPGASTACK_VAL_f64) then
                    ReturnStackState <= StackStatePop64Bit0;
                    StackState <= StackStatePopType0;
                else
                    StackState <= StackStateError;
                end if;
            elsif(Action = WASMFPGASTACK_VAL_LocalGet) then
                StackState <= StackStateLocalGet0;
            elsif(Action = WASMFPGASTACK_VAL_LocalSet) then
                StackState <= StackStateLocalSet0;
            elsif(Action = WASMFPGASTACK_VAL_CreateActivationFrame) then
                StackState <= StackStateActivationFrame0;
            end if;
        end if;
      --
      -- Activation Frame:
      --
      --  local 0
      --  local 1
      --  local 2
      --  module instance id (type: activation frame)
      --  max locals (type: activation frame)
      --  max results (type: activation frame)
      --  return address (type: activation frame)
      --
      elsif(StackState = StackStateActivationFrame0) then
        -- Push ModuleInstanceID
        CreateActivationFrame(ActivationFrameState,
                              PushToStackState,
                              ToStackMemory,
                              FromStackMemory,
                              StackAddress,
                              ModuleInstanceUid,
                              MaxLocals,
                              MaxResults,
                              ReturnAddress);
        if (ActivationFrameState = StateEnd) then
            SizeValue <= std_logic_vector(
                unsigned(SizeValue) + to_unsigned(1, SizeValue'LENGTH)
            );
            StackState <= StackStateIdle0;
        end if;
      --
      -- Remove Activation Frame
      --
      -- TODO: Set CurrentActivationFrameAddress
      --
      -- if (Type_Written = WASMFPGASTACK_VAL_Activation) then
      --    CurrentActivationFrameAddress <= StackAddress;
      -- end if;
      --
      -- Pop 32 Bit
      --
      elsif(StackState = StackStatePop32Bit0) then
        PopFromStack32(PopFromStackState,
                       FromStackMemory,
                       ToStackMemory,
                       StackAddress,
                       StackLowValue,
                       StackType);
        if (PopFromStackState = StateEnd) then
            LowValue_ToBeRead <= StackLowValue;
            HighValue_ToBeRead <= (others => '0');
            Type_ToBeRead <= StackType(2 downto 0);
            StackState <= StackStateIdle0;
        end if;
      elsif(StackState = StackStateError) then
        Trap <= '1';
      end if;
    end if;
  end process;

  StackBlk_WasmFpgaStack_i : entity work.StackBlk_WasmFpgaStack
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
      Run => Run,
      Action => Action,
      WRegPulse_ControlReg => WRegPulse_ControlReg,
      Busy => Busy,
      SizeValue => SizeValue,
      HighValue_ToBeRead => HighValue_ToBeRead,
      HighValue_Written => HighValue_Written,
      LowValue_ToBeRead => LowValue_ToBeRead,
      LowValue_Written => LowValue_Written,
      Type_ToBeRead => Type_ToBeRead,
      Type_Written => Type_Written,
      LocalIndex => LocalIndex,
      StackAddress_ToBeRead => StackAddress_ToBeRead,
      StackAddress_Written => StackAddress_Written,
      WRegPulse_StackAddressReg => WRegPulse_StackAddressReg,
      MaxLocals => MaxLocals,
      MaxResults => MaxResults,
      ReturnAddress => ReturnAddress,
      ModuleInstanceUid => ModuleInstanceUid
    );

end;
