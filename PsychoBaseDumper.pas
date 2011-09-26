{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit PsychoBaseDumper;

interface

uses
  classes, sysutils, windows, forms, Graphics, PsychoAudioDumper, PsychoTypes, PsychoFileReader,
  PsychoBundleReader, PsychoBundleDumper, PsychoImageDumper, PsychoZLibUtils, freeimage, GR32;

type
  TPsychoBaseDumper = class

  private
    FonProgress: TProgressEvent;
    FonDebug: TDebugEvent;
    TheFile: tpsychofilestream;
    BundleReader: tpsychobundlereader;
    FonDoneLoading: TOnDoneLoading;
    TempFileCreated: boolean;
    ResFileName: string;
    function GetFileNamesArray(Index: integer): string;
    function GetOffsetsArray(Index: integer): integer;
    function GetFileSizesArray(Index: integer): integer;
    function DrawImageExternal(FIF_Image_Type: integer; MemStream: TMemoryStream; OutImage: TBitmap32): boolean;
  public
    constructor Create(ResourceFile: string; Debug: TDebugEvent);
    destructor Destroy; override;
    function IsAudioOgg(FileNo: integer): boolean;
    procedure SaveFile(FileNo: integer; DestDir, FileName: string);
    procedure SaveFiles(DestDir: string);
    procedure ParseFiles;
    procedure DrawDDSImage(Offset, Size: integer; Outimage: tbitmap32; FileName: string);
    procedure SaveDDSFile(FileNo: integer; DestDir, FileName: string);
    procedure ExtractText(Offset, Size: integer; DestStrings: Tstrings);
    procedure SaveAudioFile(FileNo: integer; DestDir, FileName: string);
    procedure SaveAudioFiles(DestDir: string);

    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnDebug: TDebugEvent read FOnDebug write FOnDebug;
    property OnDoneLoading: TOnDoneLoading read FOnDoneLoading write FOnDoneLoading;
    property FileNamesArray[Index: integer]: string read GetFileNamesArray;
    property OffsetsArray[Index: integer]: integer read GetOffsetsArray;
    property FileSizesArray[Index: integer]: integer read GetFileSizesArray;
  end;

implementation

constructor TPsychoBaseDumper.Create(ResourceFile: string; Debug: TDebugEvent);
var
  ZLibHandler: TPsychoZLibUtils;
  tempname: string;
begin
  OnDebug:=Debug;
  ResFileName:=ResourceFile;
  thefile:=tpsychofilestream.Create(ResourceFile);

  ZLibHandler:=TPsychoZLibUtils.Create(thefile, ResourceFile);
  try
    if ZLibHandler.CheckCompressed=true then
    begin
      if assigned(FOnDebug) then
        FOnDebug('File is compressed...decompressing...');
      application.ProcessMessages;
      tempname:=ZLibHandler.DecompressFile;
      thefile.Free;
      thefile:=tpsychofilestream.Create(tempname);
      ResFileName:=tempname;
      TempFileCreated:=true;
    end
    else
      TempFileCreated:=false;
  finally
    ZLibHandler.Free;
  end;

  try
    BundleReader:=tpsychobundlereader.create(thefile, ResourceFile);
  except on E: EInvalidFile do
    raise;
  end;
end;

destructor TPsychoBaseDumper.Destroy;
begin
  thefile.Free;
  BundleReader.free;

  if TempFileCreated then
  begin
    sysutils.deletefile(ResFileName);
    if fileexists(ResFileName) then
      if assigned(FOnDebug) then FOnDebug('Deleting temp file... Failed!')
    else
      if assigned(FOnDebug) then FOnDebug('Deleting temp file... Done!');
  end;
  inherited;
end;

function TPsychoBaseDumper.GetFileNamesArray(Index: integer): string;
begin
  result:=BundleReader.FileNamesArray[Index];
end;

function TPsychoBaseDumper.GetOffsetsArray(Index: integer): integer;
begin
  result:=BundleReader.OffsetsArray[Index];
end;

function TPsychoBaseDumper.GetFileSizesArray(Index: integer): integer;
begin
  result:=BundleReader.FileSizesArray[Index];
end;

procedure TPsychoBaseDumper.ParseFiles;
begin
  if assigned(FOnDoneLoading) then
    BundleReader.OnDoneLoading:=FOnDoneLoading;
  if assigned(FOnDebug) then
    BundleReader.OnDebug:=FOnDebug;

  BundleReader.ParseFiles;
end;

procedure TPsychoBaseDumper.SaveFile(FileNo: integer; DestDir, FileName: string);
var
  Dumper: TPsychoBundleDumper;
begin
  Dumper:=TpsychoBundleDumper.create(TheFile, BundleReader);
  try
    if assigned(FOnDebug) then
      Dumper.OnDebug:=FOnDebug;
    if assigned(FOnProgress) then
      Dumper.OnProgress:=FOnProgress;

    Dumper.SaveFile(FileNo, DestDir, FileName);
  finally
    Dumper.free;
  end;
end;

procedure TPsychoBaseDumper.SaveFiles(DestDir: string);
var
  Dumper: TPsychoBundleDumper;
begin
  Dumper:=TpsychoBundleDumper.create(TheFile, BundleReader);
  try
    if assigned(FOnDebug) then
      Dumper.OnDebug:=FOnDebug;
    if assigned(FOnProgress) then
      Dumper.OnProgress:=FOnProgress;

    Dumper.SaveFiles(DestDir);
  finally
    Dumper.free;
  end;
end;

procedure TPsychoBaseDumper.SaveDDSFile(FileNo: integer; DestDir,
  FileName: string);
var
  SaveFile: tfilestream;
  ImageDumper: TPsychoImageDumper;
  OutStream: TMemoryStream;
  Width, Height, Mipmaps, TextureID, SeekVal: integer;
  IsCubeMap: boolean;
begin
  if extractfileext(resfilename)= '.ppf' then //No DDS Header
  begin
    Outstream:=tmemorystream.Create;
    try
      ImageDumper:=TPsychoImageDumper.Create(OutStream);
      try
        if pos('cubemaps', filename) > 0 then
          IsCubeMap:=true
        else
          IsCubeMap:=false;

        BundleReader.GetDDSFileInfo(BundleReader.OffSetsArray[FileNo], Width, Height, MipMaps, TextureID, SeekVal);
        thefile.Seek(BundleReader.OffSetsArray[FileNo] + SeekVal, sofrombeginning);
        ImageDumper.WriteDDSImage(Width, Height, MipMaps, TextureID, IsCubeMap, thefile, outstream, BundleReader.FileSizesArray[FileNo] - 44);
      finally
        ImageDumper.Free;
      end;
      OutStream.SaveToFile(DestDir + '\' + FileName);
    finally
      Outstream.free;
    end;
  end
  else //Normal DDS
  begin
    SaveFile:=tfilestream.Create(DestDir + '\' + FileName, fmOpenWrite or fmCreate);
    try
      //if assigned(FOnDebug) then FonDebug('Saving DDS file ' + FileName);
      if BundleReader.FileSizesArray[FileNo]=0 then
      else
      begin
        thefile.Seek(BundleReader.OffSetsArray[FileNo], sofrombeginning);
        savefile.CopyFrom(thefile, BundleReader.FileSizesArray[FileNo]);
        //if assigned(FOnProgress) then FOnProgress(BundleReader.FileSizesArray[FileNo] ,savefile.position);
      end;
    finally
      SaveFile.Free;
    end;
  end;
end;

procedure TPsychoBaseDumper.DrawDDSImage(Offset, Size: integer; Outimage: tbitmap32; Filename: string);
var
  ImageDumper: TPsychoImageDumper;
  OutStream: TMemoryStream;
  Width, Height, Mipmaps, TextureID, SeekVal: integer;
  IsCubeMap: boolean;
begin
  if extractfileext(resfilename)= '.ppf' then //no dds header
  begin
    Outstream:=tmemorystream.Create;
    ImageDumper:=TPsychoImageDumper.Create(OutStream);
    if pos('cubemaps', filename) > 0 then
      IsCubeMap:=true
    else
      IsCubeMap:=false;

    BundleReader.GetDDSFileInfo(Offset, Width, Height, MipMaps, TextureID, SeekVal);
    thefile.Seek(offset + SeekVal, sofrombeginning);
    ImageDumper.WriteDDSImage(Width, Height, MipMaps, TextureID, IsCubeMap, thefile, outstream, size-44);

    //Now draw the new dds file
    try
      OutImage.Clear();
      if DrawImageExternal(FIF_DDS, OutStream, OutImage)=false then
      begin
        //if assigned(fondebug) then FOnDebug('DDS decode failed!...trying alternate decoder');
        ImageDumper.DrawDDSImage(0, Size - SeekVal + 128, OutImage);
      end;
    finally
      ImageDumper.Free;
      OutStream.Free;
    end;
  end
  else //normal dds with header
  begin
    OutStream:=TMemoryStream.Create;
    try
      OutImage.Clear();
      TheFile.Position:=offset;
      OutStream.CopyFrom(thefile, Size);
      if DrawImageExternal(FIF_DDS, OutStream, OutImage)=false then
        //if assigned(fondebug) then FOnDebug('DDS decode failed!...trying alternate decoder');
        begin
          ImageDumper:=TPsychoImageDumper.Create(TheFile);
          try
            ImageDumper.DrawDDSImage(Offset, Size, OutImage);
          finally
            ImageDumper.Free;
          end;
        end;
    finally
      Outstream.free;
    end;
  end;
end;

function TPsychoBaseDumper.DrawImageExternal(FIF_Image_Type: integer; MemStream: TMemoryStream; OutImage: TBitmap32): boolean;
var
  dib : PFIBITMAP;
  PBH : PBITMAPINFOHEADER;
  PBI : PBITMAPINFO;
  BM : TBitmap;
  BP : PLONGWORD;
  BPP : longword;
  x, y : integer;
  DC : HDC;
  TempMem: PFIMEMORY;
begin
  MemStream.Position:=0;
    TempMem:=freeimage_openmemory(MemStream.Memory, MemStream.Size);
    try
      dib:=freeimage_loadfrommemory(FIF_Image_Type, TempMem,  0);
    finally
      freeimage_closememory(TempMem);
    end;


    if Dib = nil then
    begin
      result:=false;
      exit;
    end
    else
      result:=true;

    try
      PBH := FreeImage_GetInfoHeader(dib);
      PBI := FreeImage_GetInfo(dib^);
      BPP := FreeImage_GetBPP(dib);

      if BPP = 32 then
      begin
        OutImage.SetSize(FreeImage_GetWidth(dib), FreeImage_GetHeight(dib));

        BP := PLONGWORD(FreeImage_GetBits(dib));
        for y := OutImage.Height - 1 downto 0 do
          for x := 0 to OutImage.Width - 1 do
          begin
            OutImage.Pixel[x, y] := BP^;
            inc(BP);
          end;
      end
      else
      begin
        BM := TBitmap.Create;

        BM.Assign(nil);
        DC := GetDC(bm.Handle);

        BM.handle := CreateDIBitmap(DC,
          PBH^,
          CBM_INIT,
          PChar(FreeImage_GetBits(dib)),
          PBI^,
          DIB_RGB_COLORS);

        OutImage.Assign(BM);

        BM.Free;
        ReleaseDC(bm.Handle, DC);
      end;
    finally
      FreeImage_Unload(dib);
    end;

end;

procedure TPsychoBaseDumper.ExtractText(Offset, Size: integer;
  DestStrings: Tstrings);
var
  Tempstream: tmemorystream;
begin
  thefile.Seek(offset, sofrombeginning);
  Tempstream:=tmemorystream.Create;
  try
    tempstream.CopyFrom(thefile, size);
    tempstream.Position:=0;
    DestStrings.LoadFromStream(tempstream);
  finally
    tempstream.Free;
  end;
end;

procedure TPsychoBaseDumper.SaveAudioFiles(DestDir: string);
var
  Audio: TPsychoAudioDumper;
begin
  Audio:=TPsychoAudioDumper.Create(thefile, BundleReader);
  try
    if assigned(FOnDebug) then
      audio.ondebug:=FOnDebug;

    if assigned(FOnProgress) then
      audio.OnProgress:=FOnProgress;

    audio.SaveAllFiles(DestDir);
  finally
    Audio.Free;
  end;
  
end;

procedure TPsychoBaseDumper.SaveAudioFile(FileNo: integer; DestDir, FileName: string);
var
  Audio: TPsychoAudioDumper;
begin
  Audio:=TPsychoAudioDumper.Create(thefile, BundleReader);
  try
    if assigned(FOnDebug) then
      audio.ondebug:=FOnDebug;

    if assigned(FOnProgress) then
      audio.OnProgress:=FOnProgress;

    audio.SaveFile(FileNo, DestDir, FileName);
  finally
    Audio.Free;
  end;

end;

function TPsychoBaseDumper.IsAudioOgg(FileNo: integer): boolean;
begin
  thefile.Seek(BundleReader.OffSetsArray[FileNo], sofrombeginning);
  if thefile.ReadBlockName='OggS' then
    result:=true
  else
    result:=false;
end;

end.
