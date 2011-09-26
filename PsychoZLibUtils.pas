{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit PsychoZLibUtils;

interface

uses
  Classes, Zlibex, jclsysinfo, sysutils, PsychoFileReader;

type
  TPsychoZLibUtils = class

  private
    TheFile: TPsychoFileStream;
    ResFileName: string;
  public
    constructor Create(ResourceFile: TPsychoFileStream; FileName: string);
    destructor Destroy; override;
    function CheckCompressed: boolean;
    function DecompressFile: string;
end;

implementation

constructor TPsychoZLibUtils.Create(ResourceFile: TPsychoFileStream; FileName: string);
begin
  TheFile:=ResourceFile;
  ResFileName:=FileName;
end;

destructor TPsychoZLibUtils.Destroy;
begin

  inherited;
end;

function TPsychoZLibUtils.CheckCompressed: boolean;
var
  Header: string;
begin
  thefile.Position:=0;
  header:=thefile.readblockname;
  if header='ZLIB' then
    result:=true
  else
    result:=false;
end;

function TPsychoZLibUtils.DecompressFile: string;
var
  DeCompressionStream: TZDecompressionStream;
  OutputStream: tfilestream;
  UncompressedSize: integer;
begin
  thefile.Seek(8, sofrombeginning);
  UncompressedSize:=thefile.readdword;
  thefile.Seek(16, sofrombeginning);
  DecompressionStream := TZDecompressionStream.Create(thefile);
  Outputstream:=TFileStream.Create(Getwindowstempfolder + '\' + extractfilename(ResFileName), fmOpenWrite or fmCreate);
  try
    Outputstream.CopyFrom(DecompressionStream, UncompressedSize);
  finally
    DeCompressionStream.free;
    Outputstream.Free;
  end;

  result:=Getwindowstempfolder + '\' + extractfilename(ResFileName);
end;

end.
