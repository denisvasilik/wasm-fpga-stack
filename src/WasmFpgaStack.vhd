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
        Stack_Cyc : out std_logic_vector(0 downto 0);
        Trap : out std_logic
    );
end entity WasmFpgaStack;

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

  signal MaskedAdr : std_logic_vector(23 downto 0);

  signal StackBlk_Ack : std_logic;
  signal StackBlk_DatOut : std_logic_vector(31 downto 0);
  signal StackBlk_Unoccupied_Ack : std_logic;

  signal StackState : std_logic_vector(7 downto 0);
  signal ReturnStackState : std_logic_vector(7 downto 0);

  signal StackAddress : std_logic_vector(23 downto 0);
  signal StackAddress_ToBeRead : std_logic_vector(31 downto 0);
  signal StackAddress_Written : std_logic_vector(31 downto 0);
  signal WRegPulse_StackAddressReg : std_logic;
  signal RestoreStackAddress : std_logic_vector(23 downto 0);
  signal CurrentActivationFrameAddress : std_logic_vector(23 downto 0);
  signal MaxLocals : std_logic_vector(31 downto 0);
  signal MaxResults : std_logic_vector(31 downto 0);
  signal ReturnAddress : std_logic_vector(31 downto 0);

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

  constant StackStateError : std_logic_vector(7 downto 0) := x"FF";

  constant WASMFPGASTORE_ADR_BLK_MASK_StackBlk : std_logic_vector(23 downto 0) := x"00003F";

  constant ModuleInstanceUidSize : std_logic_vector(23 downto 0) := x"000001";
  constant TypeValueOffset : std_logic_vector(23 downto 0) := x"000002";

begin

  Rst <= not nRst;

  Ack <= StackBlk_Ack;
  DatOut <= StackBlk_DatOut;

  MaskedAdr <= Adr and WASMFPGASTORE_ADR_BLK_MASK_StackBlk;

  Stack_Adr <= StackAddress;
  StackAddress_ToBeRead <= x"00" & StackAddress;

  Stack : process (Clk, Rst) is
  begin
    if (Rst = '1') then
      Busy <= '1';
      Trap <= '0';
      Stack_Cyc <= (others => '0');
      Stack_Stb <= '0';
      Stack_Sel <= (others => '1');
      Stack_We <= '0';
      RestoreStackAddress <= (others => '0');
      StackAddress <= (others => '0');
      Stack_DatOut <= (others => '0');
      LowValue_ToBeRead <= (others => '0');
      HighValue_ToBeRead <= (others => '0');
      Type_ToBeRead <= (others => '0');
      SizeValue <= (others => '0');
      CurrentActivationFrameAddress <= (others => '0');
      StackState <= StackStateIdle0;
      ReturnStackState <= (others => '0');
    elsif rising_edge(Clk) then
      if(StackState = StackStateIdle0) then
        Busy <= '0';
        Stack_Cyc <= (others => '0');
        Stack_Stb <= '0';
        Stack_We <= '0';
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
                    ReturnStackState <= StackStatePop32Bit0;
                    StackState <= StackStatePopType0;
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
      --
      -- Local Get
      --
      elsif(StackState = StackStateLocalGet0) then
        -- Local Get TypeValue
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '0';
        RestoreStackAddress <= StackAddress;
        StackAddress <= std_logic_vector(unsigned(CurrentActivationFrameAddress) +
                                         unsigned(ModuleInstanceUidSize) +
                                        (unsigned(LocalIndex(21 downto 0)) & "00") +
                                         unsigned(TypeValueOffset));
        StackState <= StackStateLocalGet1;
      elsif(StackState = StackStateLocalGet1) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          Type_ToBeRead <= Stack_DatIn(2 downto 0);
          StackState <= StackStateLocalGet2;
        end if;
      elsif(StackState = StackStateLocalGet2) then
          -- Local Get HighValue
          Stack_Cyc <= "1";
          Stack_Stb <= '1';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStateLocalGet3;
      elsif(StackState = StackStateLocalGet3) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          HighValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStateLocalGet4;
        end if;
      elsif(StackState = StackStateLocalGet4) then
        -- Local Get LowValue
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
        StackState <= StackStateLocalGet5;
      elsif(StackState = StackStateLocalGet5) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= RestoreStackAddress;
          LowValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStateLocalGet6;
        end if;
      elsif(StackState = StackStateLocalGet6) then
        -- Push LowValue
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        Stack_DatOut <= LowValue_ToBeRead;
        SizeValue <= std_logic_vector(unsigned(SizeValue) + to_unsigned(1, SizeValue'LENGTH));
        StackState <= StackStateLocalGet7;
      elsif(StackState = StackStateLocalGet7) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStateLocalGet8;
        end if;
      elsif(StackState = StackStateLocalGet8) then
        -- Push HighValue
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        Stack_DatOut <= HighValue_ToBeRead;
        StackState <= StackStateLocalGet9;
      elsif(StackState = StackStateLocalGet9) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStateLocalGet10;
        end if;
      elsif(StackState = StackStateLocalGet10) then
          -- Push TypeValue
          Stack_Cyc <= "1";
          Stack_Stb <= '1';
          Stack_We <= '1';
          Stack_DatOut <= (31 downto 3 => '0') & Type_ToBeRead;
          StackState <= StackStateLocalGet11;
      elsif(StackState = StackStateLocalGet11) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= RestoreStackAddress;
          StackState <= StackStateIdle0;
        end if;
      --
      -- Local Set
      --
      elsif(StackState = StackStateLocalSet0) then
        -- Local Get TypeValue
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '0';
        RestoreStackAddress <= StackAddress;
        StackAddress <= std_logic_vector(unsigned(CurrentActivationFrameAddress) +
                                         unsigned(ModuleInstanceUidSize) +
                                        (unsigned(LocalIndex(21 downto 0)) & "00") +
                                         unsigned(TypeValueOffset));
        StackState <= StackStateLocalSet1;
      elsif(StackState = StackStateLocalSet1) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          Type_ToBeRead <= Stack_DatIn(2 downto 0);
          StackState <= StackStateLocalSet2;
        end if;
      elsif(StackState = StackStateLocalSet2) then
        if (Type_ToBeRead = WASMFPGASTACK_VAL_i32 or
            Type_ToBeRead = WASMFPGASTACK_VAL_f32 or
            Type_ToBeRead = WASMFPGASTACK_VAL_Label or
            Type_ToBeRead = WASMFPGASTACK_VAL_Activation) then
              -- Pop 32 Bit (TypeValue, Value)
              StackAddress <= RestoreStackAddress;
              ReturnStackState <= StackStateLocalSet3;
              StackState <= StackStatePopType0;
        elsif(Type_ToBeRead = WASMFPGASTACK_VAL_i64 or
              Type_ToBeRead = WASMFPGASTACK_VAL_f64) then
              -- Pop 32 Bit (TypeValue, Value)
              StackAddress <= RestoreStackAddress;
              ReturnStackState <= StackStateLocalSet4;
              StackState <= StackStatePopType0;
        else
            StackState <= StackStateError;
        end if;
      elsif(StackState = StackStateLocalSet3) then
        -- Pop 32 Bit (Value)
        if (Stack_Ack = '1') then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          LowValue_ToBeRead <= Stack_DatIn;
          HighValue_ToBeRead <= (others => '0');
          StackState <= StackStateLocalSet7;
        end if;
      elsif(StackState = StackStateLocalSet4) then
        -- Pop 64 Bit (Value)
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          HighValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStateLocalSet5;
        end if;
      elsif(StackState = StackStateLocalSet5) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
        StackState <= StackStateLocalSet6;
      elsif(StackState = StackStateLocalSet6) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          LowValue_ToBeRead <= Stack_DatIn;
          StackState <= StackStateLocalSet7;
        end if;
      elsif(StackState = StackStateLocalSet7) then
        -- Write 32 Bit or 64 Bit Value to Local Index
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        RestoreStackAddress <= StackAddress;
        StackAddress <= std_logic_vector(unsigned(CurrentActivationFrameAddress) +
                                         unsigned(ModuleInstanceUidSize) +
                                        (unsigned(LocalIndex(21 downto 0)) & "00"));
        StackState <= StackStateLocalSet8;
      elsif(StackState = StackStateLocalSet8) then
        if (Stack_Ack = '1') then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= RestoreStackAddress;
          StackState <= StackStateIdle0;
        end if;
      --
      -- Local Tee
      --

      --
      -- Push 32 Bit
      --
      elsif(StackState = StackStatePush32Bit0) then
        if (Type_Written = WASMFPGASTACK_VAL_Activation) then
            CurrentActivationFrameAddress <= StackAddress;
        end if;
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        Stack_DatOut <= LowValue_Written;
        SizeValue <= std_logic_vector(unsigned(SizeValue) + to_unsigned(1, SizeValue'LENGTH));
        ReturnStackState <= StackStateIdle0;
        StackState <= StackStatePush32Bit1;
      elsif(StackState = StackStatePush32Bit1) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStatePushType0;
        end if;
      --
      -- Pop 32 Bit
      --
      elsif(StackState = StackStatePop32Bit0) then
        if ( Stack_Ack = '1' ) then
          if (Type_Written = WASMFPGASTACK_VAL_Activation) then
              CurrentActivationFrameAddress <= StackAddress;
          end if;
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          LowValue_ToBeRead <= Stack_DatIn;
          HighValue_ToBeRead <= (others => '0');
          StackState <= StackStateIdle0;
        end if;
      --
      -- Push 64 Bit
      --
      elsif(StackState = StackStatePush64Bit0) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        Stack_DatOut <= LowValue_Written;
        SizeValue <= std_logic_vector(unsigned(SizeValue) + to_unsigned(1, SizeValue'LENGTH));
        ReturnStackState <= StackStateIdle0;
        StackState <= StackStatePush64Bit1;
      elsif(StackState = StackStatePush64Bit1) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStatePush64Bit2;
        end if;
      elsif(StackState = StackStatePush64Bit2) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '1';
        Stack_DatOut <= HighValue_Written;
        StackState <= StackStatePush64Bit3;
      elsif(StackState = StackStatePush64Bit3) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= StackStatePushType0;
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
      --
      -- Push Type Information
      --
      elsif(StackState = StackStatePushType0) then
          Stack_Cyc <= "1";
          Stack_Stb <= '1';
          Stack_We <= '1';
          Stack_DatOut <= (31 downto 3 => '0') & Type_Written;
          StackState <= StackStatePushType1;
      elsif(StackState = StackStatePushType1) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
          StackState <= ReturnStackState;
        end if;
      --
      -- Pop Type Information
      --
      elsif(StackState = StackStatePopType0) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '0';
        StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
        SizeValue <= std_logic_vector(unsigned(SizeValue) - to_unsigned(1, SizeValue'LENGTH));
        StackState <= StackStatePopType1;
      elsif(StackState = StackStatePopType1) then
        if ( Stack_Ack = '1' ) then
          Stack_Cyc <= (others => '0');
          Stack_Stb <= '0';
          Stack_We <= '0';
          Type_ToBeRead <= Stack_DatIn(2 downto 0);
          StackState <= StackStatePopType2;
        end if;
      elsif(StackState = StackStatePopType2) then
        Stack_Cyc <= "1";
        Stack_Stb <= '1';
        Stack_We <= '0';
        StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
        StackState <= ReturnStackState;
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
      ReturnAddress => ReturnAddress
    );

end;
