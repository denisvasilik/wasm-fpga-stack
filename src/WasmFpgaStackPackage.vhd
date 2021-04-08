library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library work;
  use work.WasmFpgaStackWshBn_Package.all;

package WasmFpgaStackPackage is

    constant StateIdle : std_logic_vector(15 downto 0) := x"0000";
    constant State0 : std_logic_vector(15 downto 0) := x"0001";
    constant State1 : std_logic_vector(15 downto 0) := x"0002";
    constant State2 : std_logic_vector(15 downto 0) := x"0003";
    constant State3 : std_logic_vector(15 downto 0) := x"0004";
    constant State4 : std_logic_vector(15 downto 0) := x"0005";
    constant State5 : std_logic_vector(15 downto 0) := x"0006";
    constant State6 : std_logic_vector(15 downto 0) := x"0007";
    constant State7 : std_logic_vector(15 downto 0) := x"0008";
    constant State8 : std_logic_vector(15 downto 0) := x"0009";
    constant State9 : std_logic_vector(15 downto 0) := x"000A";
    constant State10 : std_logic_vector(15 downto 0) := x"000B";
    constant State11 : std_logic_vector(15 downto 0) := x"000C";
    constant State12 : std_logic_vector(15 downto 0) := x"000D";
    constant StateEnd : std_logic_vector(15 downto 0) := x"00FE";
    constant StateError : std_logic_vector(15 downto 0) := x"00FF";

    type T_FromWishbone is
    record
        DatOut : std_logic_vector(31 downto 0);
        Ack : std_logic;
    end record;

    type T_ToWishbone is
    record
        Adr : std_logic_vector(23 downto 0);
        Sel : std_logic_vector(3 downto 0);
        DatIn : std_logic_vector(31 downto 0);
        We : std_logic;
        Stb : std_logic;
        Cyc : std_logic_vector(0 downto 0);
    end record;

    procedure CreateActivationFrame(signal State : inout std_logic_vector;
                                    signal PushToStackState : inout std_logic_vector;
                                    signal ToStackMemory : inout T_ToWishbone;
                                    signal FromStackMemory : in T_FromWishbone;
                                    signal StackAddress : inout std_logic_vector;
                                    signal ModuleInstanceUid : in std_logic_vector;
                                    signal MaxLocals : in std_logic_vector;
                                    signal MaxResults : in std_logic_vector;
                                    signal ReturnAddress : in std_logic_vector);

    procedure LocalSet(signal State: inout std_logic_vector;
                       signal PopFromStackState : inout std_logic_vector;
                       signal ToStackMemory : out T_ToWishbone;
                       signal FromStackMemory : in T_FromWishbone;
                       signal ActivationFrameAddress : in std_logic_vector;
                       signal StackAddress : inout std_logic_vector;
                       signal LocalIndex : in std_logic_vector;
                       signal HighValue : inout std_logic_vector(31 downto 0);
                       signal LowValue : inout std_logic_vector(31 downto 0);
                       signal TypeValue : inout std_logic_vector(2 downto 0);
                       signal MaxLocals : inout std_logic_vector;
                       signal ActivationFramePtr : inout std_logic_vector;
                       signal CurrentLocalIndex : inout std_logic_vector);

    procedure LocalGet(signal State: inout std_logic_vector;
                       signal PushToStackState : inout std_logic_vector;
                       signal ToStackMemory : out T_ToWishbone;
                       signal FromStackMemory : in T_FromWishbone;
                       signal ActivationFrameAddress : in std_logic_vector;
                       signal StackAddress : inout std_logic_vector;
                       signal LocalIndex : in std_logic_vector;
                       signal HighValue : inout std_logic_vector(31 downto 0);
                       signal LowValue : inout std_logic_vector(31 downto 0);
                       signal TypeValue : inout std_logic_vector(2 downto 0);
                       signal MaxLocals : inout std_logic_vector;
                       signal ActivationFramePtr : inout std_logic_vector;
                       signal CurrentLocalIndex : inout std_logic_vector);

    procedure PushToStack64(signal State : inout std_logic_vector;
                            signal ToStackMemory : out T_ToWishbone;
                            signal FromStackMemory : in T_FromWishbone;
                            signal StackAddress : inout std_logic_vector;
                            signal StackLowValue : in std_logic_vector;
                            signal StackHighValue : in std_logic_vector;
                            constant StackType : in std_logic_vector);

    procedure PopFromStack64(signal State: inout std_logic_vector;
                             signal ToStackMemory: out T_ToWishbone;
                             signal FromStackMemory: in T_FromWishbone;
                             signal StackAddress: inout std_logic_vector;
                             signal StackLowValue: out std_logic_vector;
                             signal StackHighValue: out std_logic_vector;
                             signal StackType: out std_logic_vector);

end;

package body WasmFpgaStackPackage is

    --
    -- Activation Frame Creation
    --
    -- Pop number of arguments from stack and push them back on stack as local
    -- using a specific memory size for indexed access.
    --
    --
    -- local 0 (64 Bit value, 32 Bit type)
    -- local 1 (64 Bit value, 32 Bit type)
    -- local 2 (64 Bit value, 32 Bit type)
    -- low value: module instance id, high value: return address, type: activation frame
    -- low value: max locals, high value: max results, type: activation frame
    --
    procedure CreateActivationFrame(signal State : inout std_logic_vector;
                                    signal PushToStackState : inout std_logic_vector;
                                    signal ToStackMemory : inout T_ToWishbone;
                                    signal FromStackMemory : in T_FromWishbone;
                                    signal StackAddress : inout std_logic_vector;
                                    signal ModuleInstanceUid : in std_logic_vector;
                                    signal MaxLocals : in std_logic_vector;
                                    signal MaxResults : in std_logic_vector;
                                    signal ReturnAddress : in std_logic_vector) is
    begin
        if (State = StateIdle) then
            State <= State0;
        elsif (State = State0) then
            -- Push ModuleInstanceID
            PushToStack64(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          ModuleInstanceUid,
                          ReturnAddress,
                          WASMFPGASTACK_VAL_Activation);
            if (PushToStackState = StateEnd) then
                State <= State1;
            end if;
        elsif(State = State1) then
            -- Push Max. Locals and Max Results
            PushToStack64(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          MaxLocals,
                          MaxResults,
                          WASMFPGASTACK_VAL_Activation);
            if (PushToStackState = StateEnd) then
                State <= StateEnd;
            end if;
        elsif (State = StateEnd) then
            State <= StateIdle;
        else
            State <= StateError;
        end if;
    end;

    procedure LocalSet(signal State: inout std_logic_vector;
                       signal PopFromStackState : inout std_logic_vector;
                       signal ToStackMemory : out T_ToWishbone;
                       signal FromStackMemory : in T_FromWishbone;
                       signal ActivationFrameAddress : in std_logic_vector;
                       signal StackAddress : inout std_logic_vector;
                       signal LocalIndex : in std_logic_vector;
                       signal HighValue : inout std_logic_vector(31 downto 0);
                       signal LowValue : inout std_logic_vector(31 downto 0);
                       signal TypeValue : inout std_logic_vector(2 downto 0);
                       signal MaxLocals : inout std_logic_vector;
                       signal ActivationFramePtr : inout std_logic_vector;
                       signal CurrentLocalIndex : inout std_logic_vector) is
    begin
        if (State = StateIdle) then
            State <= State0;
        elsif (State = State0) then
        elsif (State = StateEnd) then
            State <= StateIdle;
        else
            State <= StateError;
        end if;
    end;

    --
    -- TODO: + Lower number of parameters by using record types
    --       + Do not write stack signals directly, use the stack procedure instead
    --
    procedure LocalGet(signal State: inout std_logic_vector;
                       signal PushToStackState : inout std_logic_vector;
                       signal ToStackMemory : out T_ToWishbone;
                       signal FromStackMemory : in T_FromWishbone;
                       signal ActivationFrameAddress : in std_logic_vector;
                       signal StackAddress : inout std_logic_vector;
                       signal LocalIndex : in std_logic_vector;
                       signal HighValue : inout std_logic_vector(31 downto 0);
                       signal LowValue : inout std_logic_vector(31 downto 0);
                       signal TypeValue : inout std_logic_vector(2 downto 0);
                       signal MaxLocals : inout std_logic_vector;
                       signal ActivationFramePtr : inout std_logic_vector;
                       signal CurrentLocalIndex : inout std_logic_vector) is
    begin
        if (State = StateIdle) then
            MaxLocals <= (others => '0');
            CurrentLocalIndex <= (others => '0');
            ActivationFramePtr <= std_logic_vector(
                unsigned(ActivationFrameAddress) +
                to_unsigned(1, ActivationFramePtr'LENGTH)
            );
            State <= State0;
        elsif (State = State0) then
            -- Get Max Locals from Activation Frame
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            ToStackMemory.Adr <= ActivationFramePtr;
            State <= State1;
        elsif(State = State1) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                MaxLocals <= FromStackMemory.DatOut;
                CurrentLocalIndex <= FromStackMemory.DatOut;
                ActivationFramePtr <= ActivationFrameAddress;
                State <= State2;
            end if;
        elsif(State = State2) then
            if (CurrentLocalIndex = std_logic_vector(unsigned(MaxLocals) - unsigned(LocalIndex) - 1))then
                State <= State6;
            else
                CurrentLocalIndex <= std_logic_vector(unsigned(CurrentLocalIndex) - 1);
                ActivationFramePtr <= std_logic_vector(unsigned(ActivationFramePtr) - 1);
                State <= State3;
            end if;
        elsif(State = State3) then
            -- Get Type Value
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            ToStackMemory.Adr <= ActivationFramePtr;
            State <= State4;
        elsif(State = State4) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                TypeValue <= FromStackMemory.DatOut(2 downto 0);
                State <= State5;
            end if;
        elsif(State = State5) then
            if (TypeValue = WASMFPGASTACK_VAL_i32 or
                TypeValue = WASMFPGASTACK_VAL_f32) then
                ActivationFramePtr <= std_logic_vector(unsigned(ActivationFramePtr) - 1);
            else
                ActivationFramePtr <= std_logic_vector(unsigned(ActivationFramePtr) - 2);
            end if;
            State <= State2;
        elsif(State = State6) then
            -- Local Get HighValue
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            ToStackMemory.Adr <= ActivationFramePtr;
            State <= State7;
        elsif(State = State7) then
            if (FromStackMemory.Ack = '1' ) then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                LowValue <= FromStackMemory.DatOut;
                State <= State8;
            end if;
        elsif(State = State8) then
            -- Local Get LowValue
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            ToStackMemory.Adr <= std_logic_vector(unsigned(ActivationFramePtr) + 1);
            State <= State9;
        elsif(State = State9) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                if (TypeValue = WASMFPGASTACK_VAL_i32 or
                    TypeValue = WASMFPGASTACK_VAL_f32) then
                    TypeValue <= FromStackMemory.DatOut(2 downto 0);
                    State <= State12;
                else
                    HighValue <= FromStackMemory.DatOut;
                    State <= State10;
                end if;
            end if;
        elsif(State = State10) then
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            ToStackMemory.Adr <= std_logic_vector(unsigned(ActivationFramePtr) + 1);
            State <= State11;
        elsif(State = State11) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                TypeValue <= FromStackMemory.DatOut(2 downto 0);
                State <= State12;
            end if;
        elsif(State = State12) then
            PushToStack64(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          LowValue,
                          HighValue,
                          TypeValue);
            if (PushToStackState = StateEnd) then
                State <= StateEnd;
            end if;
        elsif (State = StateEnd) then
            State <= StateIdle;
        else
            State <= StateError;
        end if;
    end;

    procedure PushToStack64(signal State : inout std_logic_vector;
                            signal ToStackMemory : out T_ToWishbone;
                            signal FromStackMemory : in T_FromWishbone;
                            signal StackAddress : inout std_logic_vector;
                            signal StackLowValue : in std_logic_vector;
                            signal StackHighValue : in std_logic_vector;
                            constant StackType : in std_logic_vector) is
    begin
        if (State = StateIdle) then
            State <= State0;
        elsif (State = State0) then
            -- Push low value to stack
            ToStackMemory.DatIn <= StackLowValue;
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '1';
            State <= State1;
        elsif (State = State1) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackAddress <= std_logic_vector(
                    unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH)
                );
                State <= State2;
            end if;
        elsif(State = State2) then
            -- Push high value to stack
            ToStackMemory.DatIn <= StackHighValue;
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '1';
            State <= State3;
        elsif(State = State3) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackAddress <= std_logic_vector(
                    unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH)
                );
                State <= State4;
            end if;
        elsif(State = State4) then
            -- Push high value to stack
            ToStackMemory.DatIn <= (31 downto 3 => '0') & StackType;
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '1';
            State <= State5;
        elsif(State = State5) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackAddress <= std_logic_vector(
                    unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH)
                );
                State <= StateEnd;
            end if;
        elsif (State = StateEnd) then
            State <= StateIdle;
        else
            State <= StateError;
        end if;
    end;

    procedure PopFromStack64(signal State: inout std_logic_vector;
                             signal ToStackMemory: out T_ToWishbone;
                             signal FromStackMemory: in T_FromWishbone;
                             signal StackAddress: inout std_logic_vector;
                             signal StackLowValue: out std_logic_vector;
                             signal StackHighValue: out std_logic_vector;
                             signal StackType: out std_logic_vector) is
    begin
        if (State = StateIdle) then
            StackAddress <= std_logic_vector(unsigned(StackAddress) - 1);
            State <= State0;
        elsif (State = State0) then
            -- Pop type from stack
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';

            State <= State1;
        elsif(State = State1) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackType <= FromStackMemory.DatOut(2 downto 0);
                StackAddress <= std_logic_vector(unsigned(StackAddress) - 1);
                State <= State2;
            end if;
        elsif(State = State2) then
            -- Pop high value from stack
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            State <= State3;
        elsif (State = State3) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackHighValue <= FromStackMemory.DatOut;
                StackAddress <= std_logic_vector(unsigned(StackAddress) - 1);
                State <= State4;
            end if;
        elsif(State = State4) then
            -- Pop low value from stack
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            State <= State5;
        elsif (State = State5) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackLowValue <= FromStackMemory.DatOut;
                State <= StateEnd;
            end if;
        elsif (State = StateEnd) then
            State <= StateIdle;
        else
            State <= StateError;
        end if;
    end;

end;