program PMPProbe;
// PMPProbe <bin>: loads a flat binary to 0x80000000, single steps it in the interpreter until
// s11=0x1234 (at most 2000 steps) and prints s0, s1, s2 and s4 (the trap cause). Exit code 1
// when the test did not reach its end marker.
{$mode delphi}

uses cthreads,SysUtils,Classes,Math,PasRISCV;

var C:TPasRISCV.TConfiguration;
    M:TPasRISCV;
    S:TMemoryStream;
    I:TPasRISCVInt32;

begin

 SetExceptionMask([exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);

 C:=TPasRISCV.TConfiguration.Create;
 C.MemorySize:=16*1024*1024;
 C.NetworkMode:=TPasRISCV.TNetworkMode.Isolated;
 C.JITEnabled:=false;

 M:=TPasRISCV.Create(C);
 try

  M.Reset;
  FillChar(M.MemoryDevice.Data^,M.MemoryDevice.Size,0);

  S:=TMemoryStream.Create;
  try
   S.LoadFromFile(ParamStr(1));
   Move(S.Memory^,M.MemoryDevice.Data^,S.Size);
  finally
   S.Free;
  end;

  M.HART.State^.PC:=$80000000;
  for I:=1 to 2000 do begin
   M.Step;
   if M.HART.State^.Registers[TPasRISCV.TRegister.S11]=$1234 then begin
    break;
   end;
  end;

  WriteLn('s0=',IntToHex(M.HART.State^.Registers[TPasRISCV.TRegister.S0],16),
          ' s1=',IntToHex(M.HART.State^.Registers[TPasRISCV.TRegister.S1],16),
          ' s2=',IntToHex(M.HART.State^.Registers[TPasRISCV.TRegister.S2],16),
          ' cause=',IntToHex(M.HART.State^.Registers[TPasRISCV.TRegister.S4],16));

  if M.HART.State^.Registers[TPasRISCV.TRegister.S11]<>$1234 then begin
   ExitCode:=1;
  end;

 finally
  M.Free;
  C.Free;
 end;

end.
