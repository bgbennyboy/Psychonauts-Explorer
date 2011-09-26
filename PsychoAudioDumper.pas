{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}*

unit PsychoAudioDumper;

interface

uses
  SysUtils, Classes, forms, jclstrings, jclfileutils, PsychoTypes, PsychoFileReader,
  PsychoBundleReader, uXboxAdpcmDecoder, uWaveWriter;

type
  TPsychoAudioDumper = class

  private
    FonProgress: TProgressEvent;
    AudioFile: TPsychofilestream;
    FileType: string;
    FonDebug: TDebugEvent;
    BundleReader: TPsychoBundleReader;
    Channels, Formats: array of integer;
    Values: array of cardinal;
    procedure ReadHeader;
    procedure ParsePcFiles(DestDir: string);
    procedure ParsePcFile(FileNo: integer; Destdir, FileName: string);
    procedure SavePcFile(filename, destdir: string; blocksize: integer; IsOgg, IsPcm, ModifyFileName: boolean; PcChannels, SampleRate: integer);
    procedure SaveXboxFiles(DestDir: string);
    procedure SaveXBoxFile(FileNo: integer; DestDir, FileName: string);
    procedure ParseXbox;
    procedure DumpXBoxFile(FileName, DestDir: string; FileOffset, FileSize, NoChannels, Format, MagicValue: cardinal);
    function GetXboxSamplerate(Format, MagicValue, Channels: cardinal): integer;
    function RepairXboxChannels(Format, MagicValue, Channels: cardinal): integer;
  public
    constructor Create(ResourceFile: TPsychoFileStream; PsychoBundleReader: TpsychoBundleReader);
    destructor Destroy; override;
    procedure SaveFile(FileNo: integer; DestDir, FileName: string);
    procedure SaveAllFiles(DestDir: string);
    property OnDebug: TDebugEvent read FOnDebug write FOnDebug;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
  end;

implementation

constructor TPsychoAudioDumper.Create(ResourceFile: TPsychoFileStream; PsychoBundleReader: TpsychoBundleReader);
begin
  AudioFile:=ResourceFile;
  BundleReader:=PsychoBundleReader;
  ReadHeader;
  if FileType='unknown' then
    raise EInvalidFile.Create('Not a valid Psychonauts audio file');
end;

destructor TPsychoAudioDumper.Destroy;
begin
  Channels:=nil;
  Formats:=nil;
  Values:=nil;
end;

procedure TPsychoAudioDumper.ReadHeader;
var
  Header, temp: string;
begin
  Audiofile.Position:=0;
  header:=Audiofile.ReadBlockName;
  if header='WBND' then FileType:=header
  else
  if header='RIFF' then
  begin
    Audiofile.Seek(4, sofromcurrent);
    temp:=Audiofile.ReadBlockName;
    if temp='isbf' then
      FileType:=header
    else
      FileType:='unknown';
  end
  else
    FileType:='unknown';
end;

procedure TPsychoAudioDumper.SaveFile(FileNo: integer; DestDir, FileName: string);
begin
  if filetype='WBND' then
    SaveXBoxFile(FileNo, DestDir, FileName)
  else
  if filetype='RIFF' then
    ParsePcFile(FileNo, DestDir, FileName);
end;

procedure TPsychoAudioDumper.SaveAllFiles(DestDir: string);
begin
  if filetype='WBND' then
    SaveXboxFiles(DestDir)
  else
  if filetype='RIFF' then
    ParsePcFiles(DestDir);
end;

procedure TPsychoAudioDumper.ParsePcFile(FileNo: integer; Destdir, FileName: string);
var
  IsOgg, IsPcm: boolean;
  PcChannels, samplerate, i, blocksize, counter: integer;
  BlockName, TempString: string;
begin
  IsPcm:=false;
  PcChannels:=0;
  SampleRate:=0;
  Counter:=-1;

  AudioFile.Position:=0;
  AudioFile.Seek(16, sofromcurrent);

  blocksize:=Audiofile.ReadDWord; //text block
  AudioFile.Seek(blocksize, sofromcurrent); //seek past


  while AudioFile.Position <> BundleReader.OffsetsArray[FileNo] + BundleReader.FileSizesArray[FileNo] do
  begin
    if assigned(FOnProgress) then FOnProgress(audiofile.Size, audiofile.Position);
    blockname:=Audiofile.ReadBlockName;

    if blockname='LIST' then
    begin
      AudioFile.Seek(4, sofromcurrent); //list block size
      AudioFile.Seek(8, sofromcurrent); //Seek past ''isbftitl'' bytes
      blocksize:=Audiofile.ReadDWord;

      TempString:='';
      //filename:='';
      for I := 0 to blocksize - 1 do
      begin
        TempString:=chr(Audiofile.ReadByte);
        if TempString=#0 then
        else
          //filename:=filename + TempString;
      end;
      continue;
    end;

    if blockname='sinf' then
    begin
      AudioFile.Seek(12, sofromcurrent);
      samplerate:=Audiofile.ReadDWord;
      AudioFile.Seek(8, sofromcurrent);
      continue;
    end;

    if blockname='chnk' then
    begin
      AudioFile.Seek(4, sofromcurrent);
      PCchannels:=Audiofile.ReadDWord;
      continue;
    end;

    if blockname='cmpi' then
    begin
      AudioFile.Seek(24, sofromcurrent);
      if Audiofile.ReadDWord=1053609165 then
        IsPCM:=true
      else
        IsPCM:=false;
      continue;
    end;

    if blockname='data' then
    begin
      inc(Counter);
      blocksize:=Audiofile.ReadDWord;
      if blocksize mod 2 <> 0 then
        blocksize:=blocksize+1;

      if Audiofile.ReadBlockName='OggS' then
        IsOgg:=true
      else
        IsOgg:=false;

      AudioFile.Seek(-4, sofromcurrent);

      if Counter=FileNo then
      begin
        SavePcFile(filename, destdir, blocksize, IsOgg, IsPcm, False, PcChannels, SampleRate);
        application.processmessages;
        continue;
      end
      else
      begin
        Audiofile.Seek(blocksize, sofromcurrent);
        application.processmessages;
        continue;
      end;
    end;

    blocksize:=Audiofile.ReadDWord;
    AudioFile.Seek(blocksize, sofromcurrent);
  end;

end;

procedure TPsychoAudioDumper.ParsePcFiles(DestDir: string);
var
  I, blocksize: Integer;
  BlockName, FileName, TempString: string;
  IsOgg, IsPcm: boolean;
  PcChannels, samplerate: integer;
begin
  IsPcm:=false;
  PcChannels:=0;
  SampleRate:=0;

  AudioFile.Position:=0;
  AudioFile.Seek(16, sofromcurrent);

  blocksize:=Audiofile.ReadDWord; //text block
  AudioFile.Seek(blocksize, sofromcurrent); //seek past


  while AudioFile.Position <> AudioFile.Size do
  begin
    if assigned(FOnProgress) then FOnProgress(audiofile.Size, audiofile.Position);
    blockname:=Audiofile.ReadBlockName;

    if blockname='LIST' then
    begin
      AudioFile.Seek(4, sofromcurrent); //list block size
      AudioFile.Seek(8, sofromcurrent); //Seek past ''isbftitl'' bytes
      blocksize:=Audiofile.ReadDWord;

      TempString:='';
      filename:='';
      for I := 0 to blocksize - 1 do
      begin
        TempString:=chr(Audiofile.ReadByte);
        if TempString=#0 then
        else
          filename:=filename + TempString;
      end;
      continue;
    end;

    if blockname='sinf' then
    begin
      AudioFile.Seek(12, sofromcurrent);
      samplerate:=Audiofile.ReadDWord;
      AudioFile.Seek(8, sofromcurrent);
      continue;
    end;

    if blockname='chnk' then
    begin
      AudioFile.Seek(4, sofromcurrent);
      PCchannels:=Audiofile.ReadDWord;
      continue;
    end;

    if blockname='cmpi' then
    begin
      AudioFile.Seek(24, sofromcurrent);
      if Audiofile.ReadDWord=1053609165 then
        IsPCM:=true
      else
        IsPCM:=false;
      continue;
    end;

    if blockname='data' then
    begin
      blocksize:=Audiofile.ReadDWord;
      if blocksize mod 2 <> 0 then
        blocksize:=blocksize+1;

      if Audiofile.ReadBlockName='OggS' then
        IsOgg:=true
      else
        IsOgg:=false;

      AudioFile.Seek(-4, sofromcurrent);

      SavePcFile(filename, destdir, blocksize, IsOgg, IsPcm, True, PcChannels, SampleRate);
      application.processmessages;
      continue;
    end;

    blocksize:=Audiofile.ReadDWord;
    AudioFile.Seek(blocksize, sofromcurrent);
  end;

end;


procedure TPsychoAudioDumper.SavePcFile(filename, destdir: string; blocksize: integer;  IsOgg, IsPcm, ModifyFileName: boolean; PcChannels, SampleRate: integer);
var
  SaveFile: tfilestream;
  Path, FileExt: string;
  WS: TWaveStream;
  XboxAdpcmDecoder: TXboxAdpcmDecoder;
  NewPos: integer;
begin
  if ModifyFileName=true then
  begin
    if IsOgg=true then
      FileExt:='.ogg'
    else
      FileExt:='.wav';

    if stripos('loop', extractfileext(filename)) > 0 then //It has 'loop' in the file extension.
      filename:=pathextractfilenamenoext(filename)+ 'Loop' + '.blah'; //File extension will be removed, so add 'loop' to filename

    Path:=destdir + '\' + pathextractfilenamenoext(filename) + fileext;
  end
  else
    Path:=destdir + '\' + filename;

  if IsPcm=true then
  begin
    {audiofile.Seek(blocksize, sofromcurrent);
    exit;}
    SaveFile:=tfilestream.Create(Path, fmOpenWrite or fmCreate);
    WS := TWaveStream.Create(SaveFile, PcChannels, 16, Samplerate);
    try
      SaveFile.CopyFrom(audiofile, blocksize);
    finally
      WS.Free;
      savefile.Free;
    end;
  end
  else
  if IsOgg=true then
  begin
    SaveFile:=tfilestream.Create(Path, fmOpenWrite or fmCreate);
    try
      SaveFile.CopyFrom(audiofile, blocksize);
    finally
      SaveFile.Free;
    end;
  end
  else
  begin
    SaveFile:=tfilestream.Create(Path, fmOpenWrite or fmCreate);
    WS := TWaveStream.Create(SaveFile, PcChannels, 16, Samplerate);
    try
      XboxAdpcmDecoder := TXboxAdpcmDecoder.Create(PcChannels);
      try      //audiofile.Seek(blocksize, sofromcurrent);
        NewPos:=audiofile.Position + blocksize;
        XboxAdpcmDecoder.Decode(audiofile, WS, audiofile.Position, blocksize);
        if audiofile.Position <> NewPos then
          audioFile.Seek(NewPos, sofrombeginning);
      finally
        XboxAdpcmDecoder.Free;
      end;
    finally
      WS.Free;
      savefile.Free;
    end;
  end;

end;

procedure TPsychoAudioDumper.SaveXBoxFile(FileNo: integer; DestDir, FileName: string);
begin
  ParseXBox;
  DumpXBoxFile(FileName, DestDir, BundleReader.OffsetsArray[FileNo], BundleReader.FileSizesArray[FileNo], Channels[FileNo], Formats[FileNo], Values[FileNo]);
end;

procedure TPsychoAudioDumper.SaveXboxFiles(DestDir: string);
var
  i: integer;
begin
  ParseXBox;

  for I := 0 to BundleReader.FileNamesCount - 1 do
  begin
    DumpXBoxFile(BundleReader.FileNamesArray[i], DestDir, BundleReader.OffsetsArray[i], BundleReader.FileSizesArray[i], Channels[i], Formats[i], Values[i]);
    if assigned(FOnProgress) then
      FOnProgress(BundleReader.FileNamesCount - 1, i);
    application.ProcessMessages;
  end;
end;

procedure TPsychoAudioDumper.ParseXbox;
var
  BlockName: string;
  i, NoEntries: integer;
begin
  AudioFile.Position:=0;
  blockname:=AudioFile.readblockname;
  if blockname <> 'WBND' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid file!...Aborting');
    exit;
  end;
  {else
    if assigned(FOnDebug) then
      FOnDebug('Filecheck ok...scanning for sound files');}


  AudioFile.Seek(40, sofromcurrent); //past wave bank header
  NoEntries:=AudioFile.ReadDWord;
  AudioFile.Seek(32, sofromcurrent);

  Setlength(Channels, noentries);
  Setlength(Formats, noentries);
  Setlength(Values, noentries);

  for I := 0 to noentries - 1 do
  begin
    Channels[i]:=AudioFile.ReadWord;
    Formats[i]:=AudioFile.ReadWord;
    Values[i]:=AudioFile.ReadDWord;
    Audiofile.seek(16, sofromcurrent);
  end;
end;

procedure TPsychoAudioDumper.DumpXBoxFile(FileName, DestDir: string; FileOffset, FileSize, NoChannels, Format, MagicValue: cardinal);
var
  Path: string;
  SaveFile: tfilestream;
  WS: TWaveStream;
  XboxAdpcmDecoder: TXboxAdpcmDecoder;
  NewPos, Samplerate, FixedChannels: integer;
begin
  Path:=DestDir + '\' + filename;

  AudioFile.Seek(FileOffset, sofrombeginning);

  FixedChannels:=RepairXboxChannels(Format, MagicValue, NoChannels);
  Samplerate:=GetXboxSamplerate(Format, Magicvalue, FixedChannels);

  //New check - assume that all other format tags=pcm.
  //I've only seen format tag 2 used though (in CommonFX.xwb: CommonFX17 + CommonFX27)
  //XWB extractor sees tag 2 as tag 0 (pcm)
  //if Format =2 then Format:=0;

  if Format=0 then //Normal Pcm
  begin
    SaveFile:=tfilestream.Create(Path, fmOpenWrite or fmCreate);
    WS := TWaveStream.Create(SaveFile, FixedChannels, 16, Samplerate);
    try
      SaveFile.CopyFrom(audiofile, filesize);
    finally
      WS.Free;
      savefile.Free;
    end;
  end
  else
  if format=1 then //Xbox ADPCM
  begin
    SaveFile:=tfilestream.Create(Path, fmOpenWrite or fmCreate);
    WS := TWaveStream.Create(SaveFile, FixedChannels, 16, Samplerate);
    try
      XboxAdpcmDecoder := TXboxAdpcmDecoder.Create(FixedChannels);
      try
        NewPos:=audiofile.Position + filesize;
        XboxAdpcmDecoder.Decode(audiofile, WS, audiofile.Position, filesize);
        if audiofile.Position <> NewPos then
          audioFile.Seek(NewPos, sofrombeginning);
      finally
        XboxAdpcmDecoder.Free;
      end;
    finally
      WS.Free;
      savefile.Free;
    end;
  end
  else
  begin
  if Assigned(FOnDebug) then
    FOnDebug('Unknown audio format! = ' + inttostr(format) + ' Please report this. Its file ' + filename + ' Skipping file...');
  end;

end;


function TPsychoAudioDumper.RepairXboxChannels(Format, MagicValue,
  Channels: cardinal): integer;
var
  Temp: integer;
begin
  if format=0 then //Pcm
  begin
    Temp:=(MagicValue - 4) mod 32;
    if Temp=0 then
      Result:=1
    else
      Result:=2;
  end
  else
  if format=1 then //Adpcm
  begin
    Temp:=(MagicValue - 5) mod 32;
    if Temp=0 then
      Result:=1
    else
      Result:=2;
  end
  else
    Result:=1;
end;


function TPsychoAudioDumper.GetXboxSamplerate(Format, MagicValue,
  Channels: cardinal): integer;
begin
  if format=0 then //Pcm
  begin
    if Channels=1 then
    begin
      if MagicValue=2148894852 then //1 channel
        result:=44100
      else
      if MagicValue=2148507652 then //1 channel
        result:=32000
      else
      if MagicValue=2148189252 then //1 channel
        result:=22050
      else
      if MagicValue=705604 then //1 channel
        result:=22050
      else
      if MagicValue=352804 then //1 channel
        result:=11025
      else
      if MagicValue=256004 then //1 channel
        result:=8000
      else
        begin
        result:=0;
        if Assigned(FOnDebug) then
        FOnDebug('Unknown magic value! = ' + inttostr(magicvalue));
        end
    end
    else //2 channels
    begin
      if MagicValue=2148894856 then //2 channel
        result:=44100
      else
      if MagicValue=2148507656 then //2 channel
        result:=32000
      else
      if MagicValue=2148189256 then //2 channel
        result:=22050
      else
        begin
        result:=0;
        if Assigned(FOnDebug) then
        FOnDebug('Unknown magic value! = ' + inttostr(magicvalue));
        end
    end;
  end
  else
  if format=1 then //Adpcm
  begin
    Result:=(MagicValue - (1 + (Channels * 4))) div 32;
  end
  else
    Result:=0;
end;

end.
