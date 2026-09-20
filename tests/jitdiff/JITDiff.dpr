program JITDiff;
// JITDiff <bin> <jit 0|1> [<strictfpu 0|1> [nofeatures]]: loads a flat binary to 0x80000000, runs it with
// Machine.Run (not single step, which would bypass the JIT) until the guest powers off via
// SYSCON, and prints the signature: "count N" and then N dwords from 0x80800000, where N is
// read from 0x807ffff8. With "nofeatures" the JIT sees a host CPU without LZCNT, BMI1, POPCNT and
// F16C, so the intrinsics that need them decline and the interpreter runs those instructions.
{$mode delphi}

uses cthreads,SysUtils,Classes,Math,PasRISCV;

var C:TPasRISCV.TConfiguration;
    M:TPasRISCV;
    S:TMemoryStream;
    I,N:TPasRISCVUInt64;

begin

 SetExceptionMask([exInvalidOp,exDenormalized,exZeroDivide,exOverflow,exUnderflow,exPrecision]);

 C:=TPasRISCV.TConfiguration.Create;
 C.MemorySize:=16*1024*1024;
 C.NetworkMode:=TPasRISCV.TNetworkMode.Isolated;
 C.JITEnabled:=ParamStr(2)='1';
 if ParamCount>=3 then begin
  C.StrictCompliantFPU:=ParamStr(3)='1';
 end;

 if ParamStr(4)='nofeatures' then begin
  CPUFeatures:=CPUFeatures and not (CPUFeatures_X86_LZCNT_Mask or CPUFeatures_X86_BMI1_Mask or CPUFeatures_X86_POPCNT_Mask or CPUFeatures_X86_F16C_Mask);
 end;

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
  M.Run;

  N:=PPasRISCVUInt64(Pointer(TPasRISCVPtrUInt(M.MemoryDevice.Data)+$7ffff8))^;
  WriteLn('count ',N);
  for I:=0 to N-1 do begin
   WriteLn(IntToHex(PPasRISCVUInt64(Pointer(TPasRISCVPtrUInt(M.MemoryDevice.Data)+$800000+(I*8)))^,16));
  end;

 finally
  M.Free;
  C.Free;
 end;

end.
