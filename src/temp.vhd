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
                                         unsigned(ActivationFrameSize) +
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