{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit PsychoBundleDumper;

interface

uses
  Classes, sysutils, forms, jclfileutils, PsychoBundleReader, PsychoFileReader,
  PsychoTypes;

type
  TPsychoBundleDumper = class

  private
    FonProgress: TProgressEvent;
    FonDebug: TDebugEvent;
    TheFile: TPsychoFileStream;
    BundleReader: TPsychoBundleReader;
    FileType: string;
    SavedFileList: TStringList;
    function CheckDuplicateFiles(FileName: string): string;
    procedure SavePPAKFiles(DestDir: string);
    procedure SaveZPKGFiles(DestDir: string);
    procedure SavePS2Files(DestDir: string);
    procedure MakePKGFolders(DestDir: string);
    procedure SavePcAudioFiles(DestDir: string);
    procedure SaveXboxAudioFiles(DestDir: string);
    procedure SavePPAKFile(FileNo: integer; DestDir, FileName: string);
    procedure SaveZPKGFile(FileNo: integer; DestDir, FileName: string);
    procedure SavePS2File(FileNo: integer; DestDir, FileName: string);
    procedure SavePcAudioFile(FileNo: integer; DestDir, FileName: string);
    procedure SaveXboxAudioFile(FileNo: integer; DestDir, FileName: string);
  public
    constructor Create(ResourceFile: TPsychoFileStream; PsychoBundleReader: TpsychoBundleReader);
    destructor Destroy; override;
    procedure SaveFiles(DestDir: string);
    procedure SaveFile(FileNo: integer; DestDir, FileName: string);
    property OnDebug: TDebugEvent read FOnDebug write FOnDebug;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
end;

implementation


{ TPsychoBundleDumper }

constructor TPsychoBundleDumper.Create(ResourceFile: TPsychoFileStream;
  PsychoBundleReader: TpsychoBundleReader);
begin
  TheFile:=ResourceFile;
  BundleReader:=PsychoBundleReader;
  FileType:=BundleReader.ResFileType;
end;

destructor TPsychoBundleDumper.Destroy;
begin

  inherited;
end;

procedure TPsychoBundleDumper.SaveFile(FileNo: integer; DestDir, FileName: string);
begin
  if FileType='PPAK' then
    SavePPAKFile(FileNo, DestDir, FileName)
  else
  if FileType='ZPKG' then
    SaveZPKGFile(FileNo, DestDir, FileName)
  else
  if FileType='RIFF' then
    SavePcAudioFile(FileNo, DestDir, FileName)
  else
  if FileType='WBND' then
    SaveXboxAudioFile(FileNo, DestDir, FileName)
  else
  if FileType='PS2FILE' then
    SavePS2File(FileNo, DestDir, FileName)
  else
end;

procedure TPsychoBundleDumper.SaveFiles(DestDir: string);
begin
  if assigned(FOnDebug) then FOnDebug('Dumping all files - any existing files with the same name will be replaced.');
  SavedFileList:=tstringlist.create;
  try
    if FileType='PPAK' then
      SavePPAKFiles(DestDir)
    else
    if FileType='ZPKG' then
      SaveZPKGFiles(DestDir)
    else
    if FileType='RIFF' then
      SavePcAudioFiles(DestDir)
    else
    if FileType='WBND' then
      SaveXboxAudioFiles(DestDir)
    else
    if FileType='PS2FILE' then
      SavePS2Files(DestDir)
    else
  finally
    SavedFileList.free;
  end;
end;

function TPsychoBundleDumper.CheckDuplicateFiles(FileName: string): string;
var
  i, FileNo: integer;
  stop, foundit: boolean;
  tempname: string;
begin
  stop:=false;
  FileNo:=-1;
  TempName:=FileName;
  while stop=false do
  begin
    FoundIt:=false;
    for i:=0 to SavedFileList.Count -1 do
    begin                                  
      if UpperCase(TempName)=UpperCase(SavedFileList[i]) then //already exists
      begin
        FoundIt:=true;
        break;
      end
      else

    end;

    if FoundIt=false then
      stop:=true
    else
    begin
      inc(FileNo);
      tempname:=extractfilepath(filename) +  extractfilename(inttostr(FileNo) + '_' + filename);
    end;
  end;

  if TempName <> FileName then
    if assigned(FOnDebug) then FOnDebug('Duplicate file detected:  ("' + FileName + '") saved as "' + TempName + '"');

  SavedFileList.Add(TempName);
  Result:=TempName;
end;

procedure TPsychoBundleDumper.SavePPAKFiles(DestDir: string);
var
  SaveFile: tfilestream;
  i: integer;
  NewName: string;
begin
  for i:=0 to BundleReader.FileNamesCount -1 do
  begin
    forcedirectories(extractfilepath(destdir + '\' + BundleReader.FileNamesArray[i]));
    NewName:=CheckDuplicateFiles(BundleReader.FileNamesArray[i]);
    //CheckDuplicateFiles() handles files with a path, but it returns the full path+name string
    //so dump as below. Use extractfilepath to place the file in the dir made with forcedirectories()
    SaveFile:=tfilestream.Create(DestDir + '\' + extractfilepath(BundleReader.FileNamesArray[i]) + extractfilename(newname), fmOpenWrite or fmCreate);
    try
      thefile.Seek(BundleReader.OffsetsArray[i], sofrombeginning);
      {if assigned(FOnDebug) then
        FonDebug('Dumping file ' + newname);}
      if BundleReader.FileSizesArray[i]=0 then
      else
        savefile.CopyFrom(thefile, BundleReader.FileSizesArray[i]);
    finally
      SaveFile.free;
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileNamesCount -1 ,i);
      application.processmessages;
    end;
  end;

  if assigned(FOnDebug) then FOnDebug('Duplicate file messages: Often, the archives contain files with the same name. So in order to avoid overwriting files, some of the files are renamed.');
end;

procedure TPsychoBundleDumper.SavePS2Files(DestDir: string);
var
  SaveFile: tfilestream;
  i: integer;
  NewName: string;
begin
  for i:=0 to BundleReader.FileNamesCount -1 do
  begin
    forcedirectories(extractfilepath(destdir + '\' + BundleReader.FileNamesArray[i]));
    NewName:=CheckDuplicateFiles(BundleReader.FileNamesArray[i]);
    //CheckDuplicateFiles() handles files with a path, but it returns the full path+name string
    //so dump as below. Use extractfilepath to place the file in the dir made with forcedirectories()
    SaveFile:=tfilestream.Create(DestDir + '\' + extractfilepath(BundleReader.FileNamesArray[i]) + '\' + extractfilename(newname), fmOpenWrite or fmCreate);
    try
      thefile.Seek(BundleReader.OffsetsArray[i], sofrombeginning);
      {if assigned(FOnDebug) then
        FonDebug('Dumping file ' + newname);}
      if BundleReader.FileSizesArray[i]=0 then
      else
        savefile.CopyFrom(thefile, BundleReader.FileSizesArray[i]);
    finally
      SaveFile.free;
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileNamesCount -1 ,i);
      application.processmessages;
    end;
  end;

  if assigned(FOnDebug) then FOnDebug('Duplicate file messages: Often, the archives contain files with the same name. So in order to avoid overwriting files, some of the files are renamed.');
end;

procedure TPsychoBundleDumper.SaveZPKGFiles(DestDir: string);
var
  SaveFile: tfilestream;
  i: integer;
  newname: string;
begin
  MakePKGFolders(DestDir);

  for i:=0 to BundleReader.FileNamesCount -1 do
  begin
    newname:=CheckDuplicateFiles(Bundlereader.FileNamesArray[i]);
    
    SaveFile:=tfilestream.Create(DestDir + '\'  + BundleReader.FileExtensionsArray[i] + '\' + newname{filenames[i]}, fmOpenWrite or fmCreate);
    try
      thefile.Seek(BundleReader.OffsetsArray[i], sofrombeginning);
      {if assigned(FOnDebug) then
        FonDebug('Dumping file ' + filenames[i]);}
      if BundleReader.FileSizesArray[i]=0 then
      else
        savefile.CopyFrom(thefile, BundleReader.FileSizesArray[i]);
    finally
      Savefile.Free;
        if assigned(FOnProgress) then
          FOnProgress(BundleReader.FileNamesCount -1 ,i);
      application.processmessages;
    end;
  end;

  if assigned(FOnDebug) then FOnDebug('Duplicate file messages: Often, the archives contain files with the same name. So in order to avoid overwriting files, some of the files are renamed.');
end;

procedure TPsychoBundleDumper.MakePKGFolders(DestDir: string);
var
  FileTypesOfs, NameDirEnd: integer;
  Tempbyte, FileExtension: string;
begin
  thefile.seek(8, sofrombeginning);
  NameDirEnd:=thefile.ReadDWord;
  thefile.seek(16, sofromcurrent);
  FileTypesOfs:=thefile.ReadDWord;
  if assigned(FOnDebug) then
    FOnDebug('Creating filetype folders...');
  thefile.seek(FileTypesOfs + 1 , sofrombeginning); //+1 for blank
  while thefile.Position < NameDirEnd do
  begin
    tempbyte:=chr(thefile.readbyte);
    if tempbyte=#0 then
    begin
      if fileextension='' then //hack for pc demo
      else
      begin
        createdir(DestDir + '\' + fileextension);
        if assigned(FOnDebug) then
          FOnDebug('.' + fileextension);
      end;
      fileextension:='';
    end
    else
      fileextension:=fileextension + tempbyte;
  end;
  //createdir(DestDir + '\' + 'lpf'); //hack for pc demo - .lpf isnt in the file ext dir
end;

procedure TPsychoBundleDumper.SavePcAudioFiles(DestDir: string);
var
  SaveFile: tfilestream;
  i: integer;
  NewName: string;
begin
  for i:=0 to BundleReader.FileNamesCount -1 do
  begin
    forcedirectories(extractfilepath(destdir + '\' + BundleReader.FileNamesArray[i]));
    NewName:=CheckDuplicateFiles(BundleReader.FileNamesArray[i]);
    SaveFile:=tfilestream.Create(DestDir + '\' + newname, fmOpenWrite or fmCreate);
    try
      thefile.Seek(BundleReader.OffsetsArray[i], sofrombeginning);
      {if assigned(FOnDebug) then
        FonDebug('Dumping file ' + filenames[i]);}
      if BundleReader.FileSizesArray[i]=0 then
      else
        savefile.CopyFrom(thefile, BundleReader.FileSizesArray[i]);
    finally
      SaveFile.free;
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileNamesCount -1 ,i);
      application.processmessages;
    end;
  end;
end;

procedure TPsychoBundleDumper.SaveXboxAudioFiles(DestDir: string);
var
  SaveFile: tfilestream;
  i: integer;
  NewName: string;
begin
  for i:=0 to BundleReader.FileNamesCount -1 do
  begin
    forcedirectories(extractfilepath(destdir + '\' + BundleReader.FileNamesArray[i]));
    NewName:=CheckDuplicateFiles(BundleReader.FileNamesArray[i]);
    SaveFile:=tfilestream.Create(DestDir + '\' + newname, fmOpenWrite or fmCreate);
    try
      thefile.Seek(BundleReader.OffsetsArray[i], sofrombeginning);
      {if assigned(FOnDebug) then
        FonDebug('Dumping file ' + filenames[i]);}
      if BundleReader.FileSizesArray[i]=0 then
      else
        savefile.CopyFrom(thefile, BundleReader.FileSizesArray[i]);
    finally
      SaveFile.free;
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileNamesCount -1 ,i);
      application.processmessages;
    end;
  end;

end;

procedure TPsychoBundleDumper.SavePPAKFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: tfilestream;
begin
  SaveFile:=tfilestream.Create(DestDir + '\' + FileName{extractfilename(filenames[FileNo])}, fmOpenWrite or fmCreate);
  try
    thefile.Seek(BundleReader.OffsetsArray[FileNo], sofrombeginning);
    if assigned(FOnDebug) then
      FonDebug('Dumping file ' + FileName);
    if BundleReader.FileSizesArray[FileNo]=0 then
    else
    begin
      savefile.CopyFrom(thefile, BundleReader.FileSizesArray[FileNo]);
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileSizesArray[FileNo] ,savefile.position);
    end;
  finally
    Savefile.Free;
    application.processmessages;
  end;
end;

procedure TPsychoBundleDumper.SavePS2File(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: tfilestream;
begin
  SaveFile:=tfilestream.Create(DestDir + '\' + Filename{extractfilename(filenames[FileNo])}, fmOpenWrite or fmCreate);
  try
    thefile.Seek(BundleReader.OffsetsArray[FileNo], sofrombeginning);
    if assigned(FOnDebug) then
      FonDebug('Dumping file ' + FileName);
    if BundleReader.FileSizesArray[FileNo]=0 then
    else
    begin
      savefile.CopyFrom(thefile, BundleReader.FileSizesArray[FileNo]);
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileSizesArray[FileNo] ,savefile.position);
    end;
  finally
    Savefile.Free;
    application.processmessages;
  end;
end;

procedure TPsychoBundleDumper.SaveZPKGFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: tfilestream;
begin
  SaveFile:=tfilestream.Create(DestDir + '\' + FileName, fmOpenWrite or fmCreate);
  try
    thefile.Seek(BundleReader.OffsetsArray[FileNo], sofrombeginning);
    if assigned(FOnDebug) then
      FonDebug('Dumping file ' + FileName);
    if BundleReader.FileSizesArray[FileNo]=0 then
    else
    begin
      savefile.CopyFrom(thefile, BundleReader.FileSizesArray[FileNo]);
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileSizesArray[FileNo] ,savefile.position);
    end;
  finally
    Savefile.Free;
    application.processmessages;
  end;

end;

procedure TPsychoBundleDumper.SavePcAudioFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: tfilestream;
begin
  SaveFile:=tfilestream.Create(DestDir + '\' + FileName{extractfilename(filenames[FileNo])}, fmOpenWrite or fmCreate);
  try
    thefile.Seek(BundleReader.OffsetsArray[FileNo], sofrombeginning);
    if assigned(FOnDebug) then
      FonDebug('Dumping file ' + FileName);
    if BundleReader.FileSizesArray[FileNo]=0 then
    else
    begin
      savefile.CopyFrom(thefile, BundleReader.FileSizesArray[FileNo]);
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileSizesArray[FileNo], savefile.position);
    end;
  finally
    Savefile.Free;
    application.processmessages;
  end;
end;

procedure TPsychoBundleDumper.SaveXboxAudioFile(FileNo: integer; DestDir, FileName: string);
var
  SaveFile: tfilestream;
begin
  SaveFile:=tfilestream.Create(DestDir + '\' + FileName, fmOpenWrite or fmCreate);
  try
    thefile.Seek(BundleReader.OffsetsArray[FileNo], sofrombeginning);
    if assigned(FOnDebug) then
      FonDebug('Dumping file ' + FileName);
    if BundleReader.FileSizesArray[FileNo]=0 then
    else
    begin
      savefile.CopyFrom(thefile, BundleReader.FileSizesArray[FileNo]);
      if assigned(FOnProgress) then
        FOnProgress(BundleReader.FileSizesArray[FileNo], savefile.position);
    end;
  finally
    Savefile.Free;
    application.processmessages;
  end;
end;

end.
