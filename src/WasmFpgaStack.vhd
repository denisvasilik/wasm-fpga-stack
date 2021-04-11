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
  signal StackSize : unsigned(31 downto 0);
  signal HighValue_ToBeRead : std_logic_vector(31 downto 0);
  signal HighValue_Written : std_logic_vector(31 downto 0);
  signal LowValue_ToBeRead : std_logic_vector(31 downto 0);
  signal LowValue_Written : std_logic_vector(31 downto 0);
  signal Type_ToBeRead : std_logic_vector(2 downto 0);
  signal Type_Written : std_logic_vector(2 downto 0);
  signal LocalIndex : std_logic_vector(31 downto 0);

  signal HighValue : std_logic_vector(31 downto 0);
  signal LowValue : std_logic_vector(31 downto 0);
  signal TypeValue : std_logic_vector(2 downto 0);

  signal MaxLocals_ToBeRead : std_logic_vector(31 downto 0);
  signal MaxLocals_Written : std_logic_vector(31 downto 0);
  signal MaxResults_ToBeRead : std_logic_vector(31 downto 0);
  signal MaxResults_Written : std_logic_vector(31 downto 0);
  signal ReturnAddress_ToBeRead : std_logic_vector(31 downto 0);
  signal ReturnAddress_Written : std_logic_vector(31 downto 0);
  signal ModuleInstanceUid_ToBeRead : std_logic_vector(31 downto 0);
  signal ModuleInstanceUid_Written : std_logic_vector(31 downto 0);

  signal MaskedAdr : std_logic_vector(23 downto 0);

  signal StackBlk_Ack : std_logic;
  signal StackBlk_DatOut : std_logic_vector(31 downto 0);
  signal StackBlk_Unoccupied_Ack : std_logic;

  signal StackState : std_logic_vector(7 downto 0);

  signal StackAddress : std_logic_vector(31 downto 0);
  signal StackAddress_ToBeRead : std_logic_vector(31 downto 0);
  signal StackAddress_Written : std_logic_vector(31 downto 0);
  signal WRegPulse_StackAddressReg : std_logic;
  signal ActivationFrameAddress : std_logic_vector(31 downto 0);

  constant WASMFPGASTORE_ADR_BLK_MASK_StackBlk : std_logic_vector(23 downto 0) := x"00003F";

  signal ActivationFrameState : std_logic_vector(15 downto 0);
  signal PushToStackState : std_logic_vector(15 downto 0);
  signal PopFromStackState : std_logic_vector(15 downto 0);
  signal LocalGetState : std_logic_vector(15 downto 0);
  signal LocalSetState : std_logic_vector(15 downto 0);

  signal ToStackMemory : T_ToWishbone;
  signal FromStackMemory : T_FromWishbone;

  signal ActivationFramePtr : std_logic_vector(23 downto 0);

  signal ActivationFrameAddress_ToBeRead : std_logic_vector(31 downto 0);
  signal ActivationFrameAddress_Written : std_logic_vector(31 downto 0);
  signal WRegPulse_ActivationFrameAddressReg : std_logic;

  signal Zero : std_logic_vector(31 downto 0) := x"00000000";

begin

  Rst <= not nRst;

  Ack <= StackBlk_Ack;
  DatOut <= StackBlk_DatOut;

  MaskedAdr <= Adr and WASMFPGASTORE_ADR_BLK_MASK_StackBlk;

  StackAddress_ToBeRead <= StackAddress;

  ActivationFrameAddress_ToBeRead <= ActivationFrameAddress;

  Stack_Adr <= ToStackMemory.Adr;
  Stack_Sel <= ToStackMemory.Sel;
  Stack_DatOut <= ToStackMemory.DatIn;
  Stack_We <= ToStackMemory.We;
  Stack_Stb <= ToStackMemory.Stb;
  Stack_Cyc <= ToStackMemory.Cyc;

  FromStackMemory.DatOut <= Stack_DatIn;
  FromStackMemory.Ack <= Stack_Ack;

  Stack : process (Clk, Rst) is
    constant StackStateIdle : std_logic_vector(7 downto 0) := x"00";
    constant StackStatePush32Bit0 : std_logic_vector(7 downto 0) := x"01";
    constant StackStatePop32Bit0 : std_logic_vector(7 downto 0) := x"02";
    constant StackStatePush64Bit0 : std_logic_vector(7 downto 0) := x"03";
    constant StackStatePop64Bit0 : std_logic_vector(7 downto 0) := x"04";
    constant StackStateLocalGet0 : std_logic_vector(7 downto 0) := x"05";
    constant StackStateLocalSet0 : std_logic_vector(7 downto 0) := x"06";
    constant StackStateCreateActivationFrame0 : std_logic_vector(7 downto 0) := x"07";
    constant StackStateRemoveActivationFrame0 : std_logic_vector(7 downto 0) := x"08";
    constant StackStateError : std_logic_vector(7 downto 0) := x"FF";
  begin
    if (Rst = '1') then
      Busy <= '1';
      Trap <= '0';
      Zero <= (others => '0');
      MaxLocals_ToBeRead <= (others => '0');
      MaxResults_ToBeRead <= (others => '0');
      ReturnAddress_ToBeRead <= (others => '0');
      ModuleInstanceUid_ToBeRead <= (others => '0');
      ToStackMemory <= (
          Adr => (others => '0'),
          Sel => (others => '1'),
          DatIn => (others => '0'),
          We => '0',
          Stb => '0',
          Cyc => (others => '0')
      );
      ActivationFramePtr <= (others => '0');
      LowValue <= (others => '0');
      HighValue <= (others => '0');
      TypeValue <= (others => '0');
      StackAddress <= (others => '0');
      LowValue_ToBeRead <= (others => '0');
      HighValue_ToBeRead <= (others => '0');
      Type_ToBeRead <= (others => '0');
      StackSize <= (others => '0');
      ActivationFrameAddress <= (others => '0');
      ActivationFrameState <= StateIdle;
      LocalGetState <= StateIdle;
      LocalSetState <= StateIdle;
      PushToStackState <= StateIdle;
      PopFromStackState <= StateIdle;
      StackState <= StackStateIdle;
    elsif rising_edge(Clk) then
      if(StackState = StackStateIdle) then
        Busy <= '0';
        ToStackMemory.Cyc <= (others => '0');
        ToStackMemory.Stb <= '0';
        ToStackMemory.We <= '0';
        if (WRegPulse_StackAddressReg = '1') then
            StackAddress <= StackAddress_Written;
        end if;
        if (WRegPulse_ActivationFrameAddressReg = '1') then
            ActivationFrameAddress <= ActivationFrameAddress_Written;
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
                    StackState <= StackStatePop64Bit0;
                else
                    StackState <= StackStateError;
                end if;
            elsif(Action = WASMFPGASTACK_VAL_LocalGet) then
                StackState <= StackStateLocalGet0;
            elsif(Action = WASMFPGASTACK_VAL_LocalSet) then
                StackState <= StackStateLocalSet0;
            elsif(Action = WASMFPGASTACK_VAL_CreateActivationFrame) then
                StackState <= StackStateCreateActivationFrame0;
            elsif(Action = WASMFPGASTACK_VAL_RemoveActivationFrame) then
                StackAddress <= std_logic_vector(
                    unsigned(ActivationFrameAddress) + ActivationFrameSize);
                StackState <= StackStateRemoveActivationFrame0;
            end if;
        end if;
      --
      -- Create Activation Frame
      --
      elsif(StackState = StackStateCreateActivationFrame0) then
        CreateActivationFrame(ActivationFrameState,
                              PushToStackState,
                              ToStackMemory,
                              FromStackMemory,
                              StackAddress,
                              ModuleInstanceUid_Written,
                              MaxLocals_Written,
                              MaxResults_Written,
                              ReturnAddress_Written);
        if (ActivationFrameState = StateEnd) then
            StackSize <= StackSize + 1;
            ActivationFrameAddress <= std_logic_vector(
                unsigned(StackAddress) - ActivationFrameSize
            );
            StackState <= StackStateIdle;
        end if;
      --
      -- Remove Activation Frame
      --
      elsif(StackState = StackStateRemoveActivationFrame0) then
        RemoveActivationFrame(ActivationFrameState,
                              PopFromStackState,
                              PushToStackState,
                              ToStackMemory,
                              FromStackMemory,
                              StackAddress,
                              ModuleInstanceUid_ToBeRead,
                              MaxLocals_ToBeRead,
                              MaxResults_ToBeRead,
                              ReturnAddress_ToBeRead,
                              HighValue,
                              LowValue,
                              TypeValue,
                              ActivationFrameAddress);
        if (ActivationFrameState = StateEnd) then
            StackSize <= StackSize - 1;
            LowValue_ToBeRead <= LowValue;
            HighValue_ToBeRead <= HighValue;
            Type_ToBeRead <= TypeValue;
            StackState <= StackStateIdle;
        end if;
      --
      -- Local Set
      --
      elsif(StackState = StackStateLocalSet0) then
        LocalSet(LocalSetState,
                 PopFromStackState,
                 ToStackMemory,
                 FromStackMemory,
                 ActivationFrameAddress,
                 StackAddress,
                 LocalIndex,
                 HighValue,
                 LowValue,
                 TypeValue,
                 ActivationFramePtr);
        if (LocalSetState = StateEnd) then
            StackSize <= StackSize - 1;
            LowValue_ToBeRead <= LowValue;
            HighValue_ToBeRead <= HighValue;
            Type_ToBeRead <= TypeValue;
            StackState <= StackStateIdle;
        end if;
      --
      -- Local Get
      --
      elsif(StackState = StackStateLocalGet0) then
        LocalGet(LocalGetState,
                 PushToStackState,
                 ToStackMemory,
                 FromStackMemory,
                 ActivationFrameAddress,
                 StackAddress,
                 LocalIndex,
                 HighValue,
                 LowValue,
                 TypeValue,
                 ActivationFramePtr);
        if (LocalGetState = StateEnd) then
            StackSize <= StackSize + 1;
            LowValue_ToBeRead <= LowValue;
            HighValue_ToBeRead <= HighValue;
            Type_ToBeRead <= TypeValue;
            StackState <= StackStateIdle;
        end if;
      --
      -- Push 64 Bit
      --
      elsif(StackState = StackStatePush64Bit0) then
        PushToStack64(PushToStackState,
                      ToStackMemory,
                      FromStackMemory,
                      StackAddress,
                      LowValue_Written,
                      HighValue_Written,
                      Type_Written);
        if (PushToStackState = StateEnd) then
            StackSize <= StackSize + 1;
            StackState <= StackStateIdle;
        end if;
      --
      -- Pop 64 Bit
      --
      elsif(StackState = StackStatePop64Bit0) then
        PopFromStack64(PopFromStackState,
                       ToStackMemory,
                       FromStackMemory,
                       StackAddress,
                       LowValue_ToBeRead,
                       HighValue_ToBeRead,
                       Type_ToBeRead);
        if (PopFromStackState = StateEnd) then
            StackSize <= StackSize - 1;
            StackState <= StackStateIdle;
        end if;
      --
      -- Push 32 Bit
      --
      elsif(StackState = StackStatePush32Bit0) then
        PushToStack64(PushToStackState,
                      ToStackMemory,
                      FromStackMemory,
                      StackAddress,
                      LowValue_Written,
                      Zero,
                      Type_Written);
        if (PushToStackState = StateEnd) then
            StackSize <= StackSize + 1;
            StackState <= StackStateIdle;
        end if;
      --
      -- Pop 32 Bit
      --
      elsif(StackState = StackStatePop32Bit0) then
        PopFromStack64(PopFromStackState,
                       ToStackMemory,
                       FromStackMemory,
                       StackAddress,
                       LowValue_ToBeRead,
                       HighValue_ToBeRead,
                       Type_ToBeRead);
        if (PopFromStackState = StateEnd) then
            HighValue_ToBeRead <= (others => '0');
            StackSize <= StackSize - 1;
            StackState <= StackStateIdle;
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
      SizeValue => std_logic_vector(StackSize),
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
      MaxLocals_ToBeRead => MaxLocals_ToBeRead,
      MaxLocals_Written => MaxLocals_Written,
      MaxResults_ToBeRead => MaxResults_ToBeRead,
      MaxResults_Written => MaxResults_Written,
      ReturnAddress_ToBeRead => ReturnAddress_ToBeRead,
      ReturnAddress_Written => ReturnAddress_Written,
      ModuleInstanceUid_ToBeRead => ModuleInstanceUid_ToBeRead,
      ModuleInstanceUid_Written => ModuleInstanceUid_Written,
      ActivationFrameAddress_ToBeRead => ActivationFrameAddress_ToBeRead,
      ActivationFrameAddress_Written => ActivationFrameAddress_Written,
      WRegPulse_ActivationFrameAddressReg => WRegPulse_ActivationFrameAddressReg
    );

end;
