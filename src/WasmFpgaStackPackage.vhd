library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

package WasmFpgaStackPackage is

    --
    -- States
    --
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

    procedure PushToStack(signal State : inout std_logic_vector;
                          signal ToStackMemory : out T_ToWishbone;
                          signal FromStackMemory : in T_FromWishbone;
                          signal StackAddress : inout std_logic_vector);

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
            ToStackMemory.DatIn <= ModuleInstanceUid;
            PushToStack(PushToStackState,
                        ToStackMemory,
                        FromStackMemory,
                        StackAddress);
            if (PushToStackState = StateEnd) then
                State <= State1;
            end if;
        elsif(State = State1) then
            -- Push Max. Locals
            ToStackMemory.DatIn <= MaxLocals;
            PushToStack(PushToStackState,
                        ToStackMemory,
                        FromStackMemory,
                        StackAddress);
            if (PushToStackState = StateEnd) then
                State <= State2;
            end if;
        elsif(State = State2) then
            -- Push Max. Results
            ToStackMemory.DatIn <= MaxResults;
            PushToStack(PushToStackState,
                        ToStackMemory,
                        FromStackMemory,
                        StackAddress);
            if (PushToStackState = StateEnd) then
                State <= State3;
            end if;
        elsif(State = State3) then
            -- Push Return Address
            ToStackMemory.DatIn <= ReturnAddress;
            PushToStack(PushToStackState,
                        ToStackMemory,
                        FromStackMemory,
                        StackAddress);
            if (PushToStackState = StateEnd) then
                State <= StateEnd;
            end if;
        elsif (State = StateEnd) then
            State <= StateIdle;
        else
            State <= StateError;
        end if;
    end;

    procedure PushToStack(signal State : inout std_logic_vector;
                          signal ToStackMemory : out T_ToWishbone;
                          signal FromStackMemory : in T_FromWishbone;
                          signal StackAddress : inout std_logic_vector) is
    begin
        if (State = StateIdle) then
            State <= State0;
        elsif (State = State0) then
            ToStackMemory.Adr <= StackAddress;
            ToStackMemory.Cyc <= "1";
            ToStackMemory.Stb <= '1';
            ToStackMemory.We <= '1';
            State <= State1;
        elsif (State = State1) then
            if (FromStackMemory.Ack = '1') then
                ToStackMemory.Cyc <= (others => '0');
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

end;