program PrivProbe;
// PrivProbe <bin> step|jit: loads a flat binary to 0x80000000 and runs it until the test sets
// s11=0x1234, then prints s0 to s10 and a0 to a7. "step" single steps the interpreter (at most
// 200000 steps, the JIT is off), "jit" runs it with Machine.Run and the JIT on until the guest
// powers off via SYSCON (tail.inc does that once s11 is set). Exit code 1 when the test did not
// reach its end marker.
{$mode delphi}

uses cthreads,SysUtils,Classes,Math,PasRISCV;

const Names:array[0..18] of String=('s0','s1','s2','s3','s4','s5','s6','s7','s8','s9','s10','a0','a1','a2','a3','a4','a5','a6','a7');
      Numbers:array[0..18] of Integer=(8,9,18,19,20,21,22,23,24,25,26,10,11,12,13,14,15,16,17);

var C:TPasRISCV.TConfiguration;
    M:TPasRISCV;
    S:TMemoryStream;
    I:TPasRISCVInt32;
    Line:String;
    JIT:Boolean;

begin

 SetExceptionMask([exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);

 JIT:=ParamStr(2)='jit';

 C:=TPasRISCV.TConfiguration.Create;
 C.MemorySize:=16*1024*1024;
 C.NetworkMode:=TPasRISCV.TNetworkMode.Isolated;
 C.JITEnabled:=JIT;

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
  if JIT then begin
   M.Run;
  end else begin
   for I:=1 to 200000 do begin
    M.Step;
    if M.HART.State^.Registers[TPasRISCV.TRegister.S11]=$1234 then begin
     break;
    end;
   end;
  end;

  Line:='';
  for I:=0 to High(Names) do begin
   if I>0 then begin
    Line:=Line+' ';
   end;
   Line:=Line+Names[I]+'='+IntToHex(M.HART.State^.Registers[TPasRISCV.TRegister(Numbers[I])],16);
  end;
  WriteLn(Line);

  if M.HART.State^.Registers[TPasRISCV.TRegister.S11]<>$1234 then begin
   ExitCode:=1;
  end;

 finally
  M.Free;
  C.Free;
 end;

end.
