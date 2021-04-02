
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
                                         unsigned(ActivationFrameSize) +
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
                                         unsigned(ActivationFrameSize) +
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
