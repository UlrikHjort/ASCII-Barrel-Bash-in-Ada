-- ***************************************************************************
--                         Barrel Bash
--
--           Copyright (C) 2026 By Ulrik Hørlyk Hjort
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ***************************************************************************
with Ada.Text_IO;
with Ada.Calendar;
with Ada.Numerics.Float_Random;

procedure Barrel_Bash is
   use Ada.Text_IO;
   use Ada.Calendar;
   
   package Random_Gen renames Ada.Numerics.Float_Random;
   Random : Random_Gen.Generator;
   
   Screen_Width  : constant := 80;
   Screen_Height : constant := 24;
   
   type Position is record
      X : Integer;
      Y : Integer;
   end record;
   
   type Barrel is record
      Pos    : Position;
      Active : Boolean;
      DX     : Integer;
   end record;
   
   Max_Barrels : constant := 10;
   type Barrel_Array is array (1 .. Max_Barrels) of Barrel;
   
   Player_Pos       : Position := (10, 20);
   Player_On_Ground : Boolean := False;
   Player_On_Ladder : Boolean := False;
   Player_VY        : Integer := 0;
   Player_Jumping   : Boolean := False;
   Player_Lives     : Natural := 3;
   
   Start_Pos        : constant Position := (10, 20);
   
   Barrels         : Barrel_Array;
   Barrel_Count    : Natural := 0;
   Last_Spawn_Time : Time := Clock;
   
   Game_Over       : Boolean := False;
   Player_Won      : Boolean := False;
   Score           : Natural := 0;
   
   procedure Clear_Screen is
   begin
      Put (ASCII.ESC & "[2J");
      Put (ASCII.ESC & "[H");
   end Clear_Screen;
   
   procedure Set_Cursor (X, Y : Integer) is
      X_Str : constant String := Integer'Image(X);
      Y_Str : constant String := Integer'Image(Y);
   begin
      Put (ASCII.ESC & "[" & Y_Str(2 .. Y_Str'Last) & ";" & X_Str(2 .. X_Str'Last) & "H");
   end Set_Cursor;
   
   function Is_Platform (X, Y : Integer) return Boolean is
   begin
      if Y = 21 then
         return True;
      elsif Y = 17 and (X >= 10 and X <= 70) then
         return True;
      elsif Y = 13 and ((X >= 1 and X <= 30) or (X >= 50 and X <= 80)) then
         return True;
      elsif Y = 9 and (X >= 10 and X <= 70) then
         return True;
      elsif Y = 5 and ((X >= 1 and X <= 35) or (X >= 45 and X <= 80)) then
         return True;
      end if;
      return False;
   end Is_Platform;
   
   function Is_Ladder (X, Y : Integer) return Boolean is
   begin
      if X = 15 and (Y >= 17 and Y <= 20) then
         return True;
      elsif X = 65 and (Y >= 17 and Y <= 20) then
         return True;
      elsif X = 25 and (Y >= 13 and Y <= 16) then
         return True;
      elsif X = 55 and (Y >= 13 and Y <= 16) then
         return True;
      elsif X = 15 and (Y >= 9 and Y <= 12) then
         return True;
      elsif X = 65 and (Y >= 9 and Y <= 12) then
         return True;
      elsif X = 30 and (Y >= 5 and Y <= 8) then
         return True;
      elsif X = 50 and (Y >= 5 and Y <= 8) then
         return True;
      end if;
      return False;
   end Is_Ladder;
   
   procedure Draw_Screen is
   begin
      Clear_Screen;
      
      for Y in 1 .. Screen_Height loop
         Set_Cursor (1, Y);
         for X in 1 .. Screen_Width loop
            if Y = 4 and X > 10 and X < 70 then
               Put ('*');
            elsif Is_Platform (X, Y) then
               Put ('=');
            elsif Is_Ladder (X, Y) then
               Put ('H');
            else
               Put (' ');
            end if;
         end loop;
      end loop;
      
      for I in 1 .. Barrel_Count loop
         if Barrels(I).Active then
            Set_Cursor (Barrels(I).Pos.X, Barrels(I).Pos.Y);
            Put ('O');
         end if;
      end loop;
      
      Set_Cursor (Player_Pos.X, Player_Pos.Y);
      Put ('@');
      
      Set_Cursor (1, 1);
      Put ("BARREL BASH | Lives:" & Natural'Image(Player_Lives) & " | Score:" & Natural'Image(Score) & " | Arrows/WASD J/Space=Jump Q=Quit");
      
      if Player_Won then
         Set_Cursor (25, 12);
         Put ("*** YOU WIN! Press Q to exit ***");
      elsif Game_Over then
         Set_Cursor (25, 12);
         Put ("*** GAME OVER! Press Q to exit ***");
      end if;
   end Draw_Screen;
   
   procedure Spawn_Barrel is
   begin
      if Barrel_Count < Max_Barrels then
         Barrel_Count := Barrel_Count + 1;
         Barrels(Barrel_Count).Pos := (40, 5);
         Barrels(Barrel_Count).DX := (if Random_Gen.Random(Random) > 0.5 then 1 else -1);
         Barrels(Barrel_Count).Active := True;
      end if;
   end Spawn_Barrel;
   
   procedure Update_Barrels is
      New_X : Integer;
      On_Platform, Below_Is_Platform : Boolean;
   begin
      for I in 1 .. Barrel_Count loop
         if Barrels(I).Active then
            On_Platform := Is_Platform(Barrels(I).Pos.X, Barrels(I).Pos.Y + 1);
            
            if On_Platform then
               New_X := Barrels(I).Pos.X + Barrels(I).DX;
               Below_Is_Platform := Is_Platform(New_X, Barrels(I).Pos.Y + 1);
               
               if New_X < 1 or New_X > Screen_Width then
                  Barrels(I).DX := -Barrels(I).DX;
               elsif not Below_Is_Platform then
                  Barrels(I).Pos.Y := Barrels(I).Pos.Y + 1;
               else
                  Barrels(I).Pos.X := New_X;
               end if;
            else
               Barrels(I).Pos.Y := Barrels(I).Pos.Y + 1;
            end if;
            
            if Barrels(I).Pos.Y > Screen_Height then
               Barrels(I).Active := False;
            end if;
            
            if abs(Barrels(I).Pos.X - Player_Pos.X) <= 1 and
               abs(Barrels(I).Pos.Y - Player_Pos.Y) <= 1 then
               Player_Lives := Player_Lives - 1;
               if Player_Lives = 0 then
                  Game_Over := True;
               else
                  Player_Pos := Start_Pos;
                  Player_VY := 0;
                  Player_Jumping := False;
                  Barrels(I).Active := False;
               end if;
            end if;
         end if;
      end loop;
   end Update_Barrels;
   
   procedure Handle_Input (C : Character) is
      New_X, New_Y : Integer;
      C2, C3 : Character;
      Available : Boolean;
   begin
      if C = ASCII.ESC then
         Get_Immediate (C2, Available);
         if Available and then C2 = '[' then
            Get_Immediate (C3, Available);
            if Available then
               case C3 is
                  when 'A' =>
                     if Is_Ladder(Player_Pos.X, Player_Pos.Y) or Is_Ladder(Player_Pos.X, Player_Pos.Y + 1) then
                        New_Y := Player_Pos.Y - 1;
                        if New_Y >= 1 then
                           Player_Pos.Y := New_Y;
                           Player_VY := 0;
                           Player_Jumping := False;
                        end if;
                     end if;
                  when 'B' =>
                     if Is_Ladder(Player_Pos.X, Player_Pos.Y) or Is_Ladder(Player_Pos.X, Player_Pos.Y + 1) then
                        New_Y := Player_Pos.Y + 1;
                        if New_Y < Screen_Height and not Is_Platform(Player_Pos.X, New_Y + 1) then
                           Player_Pos.Y := New_Y;
                           Player_VY := 0;
                           Player_Jumping := False;
                        elsif New_Y < Screen_Height and Is_Platform(Player_Pos.X, New_Y + 1) and Is_Ladder(Player_Pos.X, New_Y + 1) then
                           Player_Pos.Y := New_Y;
                           Player_VY := 0;
                           Player_Jumping := False;
                        end if;
                     end if;
                  when 'D' =>
                     New_X := Player_Pos.X - 1;
                     if New_X >= 1 then
                        Player_Pos.X := New_X;
                     end if;
                  when 'C' =>
                     New_X := Player_Pos.X + 1;
                     if New_X <= Screen_Width then
                        Player_Pos.X := New_X;
                     end if;
                  when others =>
                     null;
               end case;
            end if;
         end if;
      else
         case C is
            when 'w' | 'W' =>
               if Is_Ladder(Player_Pos.X, Player_Pos.Y) or Is_Ladder(Player_Pos.X, Player_Pos.Y + 1) then
                  New_Y := Player_Pos.Y - 1;
                  if New_Y >= 1 then
                     Player_Pos.Y := New_Y;
                     Player_VY := 0;
                     Player_Jumping := False;
                  end if;
               end if;
            when 's' | 'S' =>
               if Is_Ladder(Player_Pos.X, Player_Pos.Y) or Is_Ladder(Player_Pos.X, Player_Pos.Y + 1) then
                  New_Y := Player_Pos.Y + 1;
                  if New_Y < Screen_Height and not Is_Platform(Player_Pos.X, New_Y + 1) then
                     Player_Pos.Y := New_Y;
                     Player_VY := 0;
                     Player_Jumping := False;
                  elsif New_Y < Screen_Height and Is_Platform(Player_Pos.X, New_Y + 1) and Is_Ladder(Player_Pos.X, New_Y + 1) then
                     Player_Pos.Y := New_Y;
                     Player_VY := 0;
                     Player_Jumping := False;
                  end if;
               end if;
            when 'a' | 'A' =>
               New_X := Player_Pos.X - 1;
               if New_X >= 1 then
                  Player_Pos.X := New_X;
               end if;
            when 'd' | 'D' =>
               New_X := Player_Pos.X + 1;
               if New_X <= Screen_Width then
                  Player_Pos.X := New_X;
               end if;
            when ' ' | 'j' | 'J' =>
               if Is_Platform(Player_Pos.X, Player_Pos.Y + 1) then
                  Player_VY := -2;
                  Player_Jumping := True;
               end if;
            when 'q' | 'Q' =>
               Game_Over := True;
            when others =>
               null;
         end case;
      end if;
   end Handle_Input;
   
   procedure Apply_Gravity is
      New_Y : Integer;
   begin
      if Is_Ladder(Player_Pos.X, Player_Pos.Y) or Is_Ladder(Player_Pos.X, Player_Pos.Y + 1) then
         return;
      end if;
      
      if not Is_Platform(Player_Pos.X, Player_Pos.Y + 1) then
         Player_VY := Player_VY + 1;
         if Player_VY > 2 then
            Player_VY := 2;
         end if;
      elsif Player_VY > 0 then
         Player_VY := 0;
         Player_Jumping := False;
      end if;
      
      if Player_VY /= 0 then
         New_Y := Player_Pos.Y + Player_VY;
         
         if New_Y < 1 then
            Player_Pos.Y := 1;
            Player_VY := 0;
         elsif New_Y > 20 then
            Player_Pos.Y := 20;
            Player_VY := 0;
         else
            if Player_VY < 0 then
               Player_Pos.Y := New_Y;
            else
               if Is_Platform(Player_Pos.X, New_Y + 1) then
                  Player_Pos.Y := New_Y;
                  Player_VY := 0;
                  Player_Jumping := False;
               elsif Is_Platform(Player_Pos.X, New_Y) then
                  Player_Pos.Y := New_Y - 1;
                  Player_VY := 0;
                  Player_Jumping := False;
               else
                  Player_Pos.Y := New_Y;
               end if;
            end if;
         end if;
      end if;
   end Apply_Gravity;
   
   C : Character;
   Available : Boolean;
   Last_Update : Time := Clock;
   Frame_Time : constant Duration := 0.1;
   
begin
   Random_Gen.Reset(Random);
   
   Clear_Screen;
   Put_Line ("=== BARREL BASH ===");
   Put_Line ("Climb to the top (*) and avoid the barrels!");
   Put_Line ("Arrow keys or WASD to move, J or SPACE to jump, Q to quit");
   Put_Line ("Press any key to start...");
   Get_Immediate (C);
   
   while not Game_Over and not Player_Won loop
      Get_Immediate (C, Available);
      if Available then
         Handle_Input (C);
      end if;
      
      if Clock - Last_Update >= Frame_Time then
         Apply_Gravity;
         Update_Barrels;
         
         if Clock - Last_Spawn_Time >= 2.0 then
            Spawn_Barrel;
            Last_Spawn_Time := Clock;
            Score := Score + 10;
         end if;
         
         if Player_Pos.Y <= 4 then
            Player_Won := True;
         end if;
         
         Draw_Screen;
         Last_Update := Clock;
      end if;
      
      delay 0.01;
   end loop;
   
   Draw_Screen;
   delay 2.0;
   Clear_Screen;
   
   if Player_Won then
      Put_Line ("Congratulations! You reached the top!");
   else
      Put_Line ("Game Over! Better luck next time!");
   end if;
   Put_Line ("Final Score:" & Natural'Image(Score));
   loop
	null;
   end loop;
end Barrel_Bash;
