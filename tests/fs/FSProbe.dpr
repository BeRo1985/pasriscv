program FSProbe;
// FSProbe <directory>: drives the 9P file system of PasRISCV against a directory that run.sh
// prepared with a regular file "reg", a symbolic link "lnk" to it, a subdirectory "dir" and a
// fifo "fifo", and prints one line per check:
//
//   qidtype reg=<type> lnk=<type> dir=<type>  the qid type of the three entries
//   qidpath ino=<0|1> uniq=<0|1>              whether the qid path is the bare inode number, and
//                                             whether the three paths differ from each other
//   errno long=<code> fifo=<code>             the error of a name that is too long
//                                             (ENAMETOOLONG) and of opening a fifo for writing
//                                             without a reader (ENXIO), which the old mapping
//                                             both turned into EINVAL
{$mode delphi}

uses cthreads,SysUtils,BaseUnix,PasRISCV;

var FileSystem:TPasRISCV9PFileSystemPOSIX;
    RootFile,WalkedFile:TPasRISCV9PFileSystem.TFSFile;
    QID,RegQID,LnkQID,DirQID:TPasRISCV9PFileSystem.TFSQID;
    QIDs:array[0..3] of TPasRISCV9PFileSystem.TFSQID;
    StatData:TStat;
    ErrorLong,ErrorFifo,PlainInode,Unique:TPasRISCVInt32;

function WalkTo(const aName:TPasRISCVRawByteString;out aFile:TPasRISCV9PFileSystem.TFSFile;out aQID:TPasRISCV9PFileSystem.TFSQID):Boolean;
// Walk returns the number of components it walked, so one means the name was found
begin
 FillChar(QIDs,SizeOf(QIDs),#0);
 result:=FileSystem.Walk(aFile,@QIDs,RootFile,1,[aName])=1;
 aQID:=QIDs[0];
end;

function QIDOf(const aName:TPasRISCVRawByteString):TPasRISCV9PFileSystem.TFSQID;
var WalkFile:TPasRISCV9PFileSystem.TFSFile;
begin
 FillChar(result,SizeOf(result),#0);
 WalkFile:=nil;
 WalkTo(aName,WalkFile,result);
 if assigned(WalkFile) then begin
  FileSystem.Delete(WalkFile);
 end;
end;

begin

 if ParamCount<1 then begin
  writeln('usage: FSProbe <directory>');
  halt(2);
 end;

 FileSystem:=TPasRISCV9PFileSystemPOSIX.Create(TPasRISCVRawByteString(ParamStr(1)));
 try

  FillChar(QID,SizeOf(QID),#0);
  if FileSystem.Attach(RootFile,@QID,0,'root','')<>0 then begin
   writeln('attach failed');
   halt(2);
  end;

  // The qid type comes from the file type field, not from a test of single bits
  RegQID:=QIDOf('reg');
  LnkQID:=QIDOf('lnk');
  DirQID:=QIDOf('dir');
  writeln('qidtype reg=',RegQID.Type_,' lnk=',LnkQID.Type_,' dir=',DirQID.Type_);

  // The qid path mixes the device in, so it is not the bare inode number any more
  PlainInode:=0;
  if FpLStat(TPasRISCVRawByteString(ParamStr(1))+'/reg',StatData)=0 then begin
   if RegQID.Path=TPasRISCVUInt64(StatData.st_ino) then begin
    PlainInode:=1;
   end;
  end;
  if (RegQID.Path<>LnkQID.Path) and (RegQID.Path<>DirQID.Path) and (LnkQID.Path<>DirQID.Path) then begin
   Unique:=1;
  end else begin
   Unique:=0;
  end;
  writeln('qidpath ino=',PlainInode,' uniq=',Unique);

  // Error codes that the old mapping turned into EINVAL
  ErrorLong:=-FileSystem.MkDir(@QID,RootFile,TPasRISCVRawByteString(StringOfChar('n',300)),511,0);
  ErrorFifo:=0;
  WalkedFile:=nil;
  if WalkTo('fifo',WalkedFile,QID) then begin
   // P9_O_WRONLY or P9_O_NONBLOCK on a fifo without a reader is ENXIO
   ErrorFifo:=-FileSystem.Open(@QID,WalkedFile,$00000001 or $00000800,nil,nil);
  end;
  if assigned(WalkedFile) then begin
   FileSystem.Delete(WalkedFile);
  end;
  writeln('errno long=',ErrorLong,' fifo=',ErrorFifo);

  FileSystem.Delete(RootFile);

 finally
  FileSystem.Free;
 end;

end.
