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

    procedure PushToStack32(signal State : inout std_logic_vector;
                            signal ToStackMemory : out T_ToWishbone;
                            signal FromStackMemory : in T_FromWishbone;
                            signal StackAddress : inout std_logic_vector;
                            signal StackValue : in std_logic_vector;
                            constant StackType : in std_logic_vector);

    procedure PushToStack64(signal State : inout std_logic_vector;
                            signal ToStackMemory : out T_ToWishbone;
                            signal FromStackMemory : in T_FromWishbone;
                            signal StackAddress : inout std_logic_vector;
                            signal StackLowValue : in std_logic_vector;
                            signal StackHighValue : in std_logic_vector;
                            constant StackType : in std_logic_vector);

    procedure PopFromStack32(signal State: inout std_logic_vector;
                             signal ToStackMemory: out T_ToWishbone;
                             signal FromStackMemory: in T_FromWishbone;
                             signal StackAddress: inout std_logic_vector;
                             signal StackValue: out std_logic_vector;
                             signal StackType: out std_logic_vector);

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
            PushToStack32(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          ModuleInstanceUid,
                          WASMFPGASTACK_VAL_Activation);
            if (PushToStackState = StateEnd) then
                State <= State1;
            end if;
        elsif(State = State1) then
            -- Push Max. Locals
            PushToStack32(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          MaxLocals,
                          WASMFPGASTACK_VAL_Activation);
            if (PushToStackState = StateEnd) then
                State <= State2;
            end if;
        elsif(State = State2) then
            -- Push Max. Results
            PushToStack32(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          MaxResults,
                          WASMFPGASTACK_VAL_Activation);
            if (PushToStackState = StateEnd) then
                State <= State3;
            end if;
        elsif(State = State3) then
            -- Push Return Address
            PushToStack32(PushToStackState,
                          ToStackMemory,
                          FromStackMemory,
                          StackAddress,
                          ReturnAddress,
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

    procedure PushToStack32(signal State : inout std_logic_vector;
                            signal ToStackMemory : out T_ToWishbone;
                            signal FromStackMemory : in T_FromWishbone;
                            signal StackAddress : inout std_logic_vector;
                            signal StackValue : in std_logic_vector;
                            constant StackType : in std_logic_vector) is
    begin
        if (State = StateIdle) then
            State <= State0;
        elsif (State = State0) then
            ToStackMemory.DatIn <= StackValue;
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
            ToStackMemory.DatIn <= (31 downto 3 => '0') & StackType;
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
                StackAddress <= std_logic_vector(unsigned(StackAddress) + to_unsigned(1, StackAddress'LENGTH));
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

    procedure PopFromStack32(signal State: inout std_logic_vector;
                             signal ToStackMemory: out T_ToWishbone;
                             signal FromStackMemory: in T_FromWishbone;
                             signal StackAddress: inout std_logic_vector;
                             signal StackValue: out std_logic_vector;
                             signal StackType: out std_logic_vector) is
    begin
        if (State = StateIdle) then
            State <= State0;
        elsif (State = State0) then
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
            State <= State1;
        elsif(State = State1) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackType <= FromStackMemory.DatOut(2 downto 0);
                State <= State2;
            end if;
        elsif(State = State2) then
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
            State <= State3;
        elsif (State = State3) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackValue <= FromStackMemory.DatOut;
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
            State <= State0;
        elsif (State = State0) then
            -- Pop type from stack
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
            State <= State1;
        elsif(State = State1) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackType <= FromStackMemory.DatOut(2 downto 0);
                State <= State2;
            end if;
        elsif(State = State2) then
            -- Pop high value from stack
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
            State <= State3;
        elsif (State = State3) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= "0";
                ToStackMemory.Stb <= '0';
                ToStackMemory.We <= '0';
                StackHighValue <= FromStackMemory.DatOut;
                State <= State4;
            end if;
        elsif(State = State4) then
            -- Pop low value from stack
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '0';
            StackAddress <= std_logic_vector(unsigned(StackAddress) - to_unsigned(1, StackAddress'LENGTH));
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