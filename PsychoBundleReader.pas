{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit PsychoBundleReader;

interface

uses
  windows, classes, forms, sysutils, jclstrings, jclsysinfo, jclfileutils, zlibex,
  PsychoTypes, PsychoFileReader, math;

type
  TPsychoBundleReader = class

  private
    TheFile: TPsychoFileStream;
    FonProgress: TProgressEvent;
    FonDebug: TDebugEvent;
    FonDoneLoading: TOnDoneLoading;
    TempFileCreated: boolean;
    ResFileName: string;
    FileType: string;
    FileNames: tstringlist;
    FileExtensions, XSBFileNames: array of string;
    Offsets, FileSizes: array of integer;
    procedure ReadHeader;
    procedure ParseZPKG;
    procedure ParsePPAK;
    procedure ParsePcAudio;
    procedure ParseXboxAudio;
    procedure ParsePS2Audio;
    procedure ParseXSB(Path: string);
    procedure ParsePs2File;
    procedure LoadPS2FromFile;
    procedure ParsePS2PPAK(var prevnofiles: integer);
    procedure CheckZLIB;
    procedure DecompressZLIB;
    procedure GetPKGFileName(ArrayPos, Offset: integer; fileext: string);
    procedure ParsePPAKdds(TextureID, Mipmaps, Width, Height: integer; filename: string);
    procedure ParsePPAKMultipleDDS(NumFrames, TextureID, Mipmaps, Width, Height: integer; filename: string);
    procedure ParsePS2Image(TextureID, Mipmaps, Width, Height: integer; filename: string);
    procedure ParsePS2MultipleImage(NumFrames, TextureID, Mipmaps, Width, Height: integer; filename: string);
    function GetPKGFileExt(Offset: integer): string;
    function GetPPAKnofiles: integer;
    function GetPS2PPAKnofiles: integer;
    function GetOffsetsArray(Index: integer): integer;
    function GetFileSizesArray(Index: integer): integer;
    function GetFileNamesArray(Index: integer): string;
    function GetFileExtensionsArray(Index: integer): string;
    function GetFileNamesCount: integer;
    function GetFileType: string;
    function GetDDSSize(MinimumNoBytes, MipMaps, TextureSize: integer): integer;
    function GetDDSSizeNonSquare(MinimumNoBytes, Mipmaps, TextureSize, Width, Height: integer): integer;
  public
    constructor Create(ResourceFile: TPsychoFileStream; FileName: string);
    destructor Destroy; override;
    procedure ParseFiles;
    property OnDebug: TDebugEvent read FOnDebug write FOnDebug;
    property OnProgress: TProgressEvent read FOnProgress write FOnProgress;
    property OnDoneLoading: TOnDoneLoading read FOnDoneLoading write FOnDoneLoading;
    property OffsetsArray[Index: integer]: integer read GetOffsetsArray;
    property FileSizesArray[Index: integer]: integer read GetFileSizesArray;
    property FileNamesArray[Index: integer]: string read GetFileNamesArray;
    property FileExtensionsArray[Index: integer]: string read GetFileExtensionsArray;
    property FileNamesCount: integer read GetFileNamesCount;
    property ResFileType: string read GetFileType;
    procedure GetDDSFileInfo(offset: integer; var Width, Height, Mipmaps, TextureID, SeekVal: integer);
end;

implementation

function TPsychoBundleReader.GetOffsetsArray(Index: integer): integer;
begin
  if (not assigned(offsets)) or
     (index < 0) or
     (index > length(offsets))
  then
  begin
    result:=-1;
    exit;
  end;

  Result:=Offsets[Index];
end;

function TPsychoBundleReader.GetFileSizesArray(Index: integer): integer;
begin
  if (not assigned(filesizes)) or
     (index < 0) or
     (index > length(filesizes))
  then
  begin
    result:=-1;
    exit;
  end;

  Result:=FileSizes[Index];
end;

function TPsychoBundleReader.GetFileNamesArray(Index: integer): string;
begin
  if (not assigned(filenames)) or
     (index < 0) or
     (index > FileNames.Count)
  then
  begin
    result:='';
    exit;
  end;

  Result:=FileNames[Index];
end;

function TPsychoBundleReader.GetFileExtensionsArray(Index: integer): string;
begin
  if (not assigned(fileextensions)) or
     (index < 0) or
     (index > length(FileExtensions))
  then
  begin
    result:='';
    exit;
  end;

  Result:=FileExtensions[Index];
end;

function TPsychoBundleReader.GetFileNamesCount: integer;
begin
  if not assigned(filenames) then
  begin
    result:=-1;
    exit;
  end;
  result:=filenames.Count;
end;

function TPsychoBundleReader.GetFileType: string;
begin
  result:=FileType;
end;

Constructor TPsychoBundleReader.Create(ResourceFile: TPsychoFileStream; FileName: string);
begin
  ResFileName:=FileName;
  TheFile:=ResourceFile;
  TempFileCreated:=false;
  FileNames:=tstringlist.Create;

  ReadHeader;
  if FileType='unknown' then
    raise EInvalidFile.Create('Not a valid Psychonauts resource file');
end;

destructor TPsychoBundleReader.Destroy;
begin
  FileNames.Free;
  Offsets:=nil;
  Filesizes:=nil;
  FileExtensions:=nil;
  XSBFileNames:=nil;

  if TempFileCreated then
  begin
    thefile.Free;
    deletefile(ResFileName);
    if fileexists(ResFileName) then
      if assigned(FOnDebug) then FOnDebug('Deleting temp file... Failed!')
    else
      if assigned(FOnDebug) then FOnDebug('Deleting temp file... Done!');
  end;

  inherited;
end;

procedure TPsychoBundleReader.ReadHeader;
var
  Header, temp: string;
begin
  thefile.Position:=0;
  if thefile.ReadDWord=4278059011 then
    header:='PS2FILE'
  else
  begin
    thefile.Position:=0;
    header:=thefile.readblockname;
  end;
  if header='ZLIB' then FileType:=header
  else
  if header='WBND' then FileType:=header
  else
  if header='PPAK' then FileType:=header
  else
  if header='ZPKG' then FileType:=header
  else
  if header='PS2FILE' then FileType:=header
  else
  if header='WB  ' then FileType:=header
  else
  if header='RIFF' then
  begin
    thefile.Seek(4, sofromcurrent);
    temp:=thefile.readblockname;
    if temp='isbf' then
      FileType:=header
    else
      FileType:='unknown';
  end
  else
    FileType:='unknown';   
end;

procedure TPsychoBundleReader.ParseFiles;
begin
  if FileType='PPAK' then
    ParsePPAK
  else
  if FileType='ZPKG' then
    ParseZPKG
  else
  if FileType='RIFF' then
    ParsePcAudio
  else
  if FileType='ZLIB' then
    CheckZlib
  else
  if FileType='WBND' then
    ParseXboxAudio
  else
  if FileType='WB  ' then
    ParsePS2Audio
  else
  if FileType='PS2FILE' then
    LoadPS2FromFile
    //ParsePS2File
  else
end;

procedure TPsychoBundleReader.ParseZPKG;
var
  blockname, tempname, prevname: string;
  namedirofs, recordsend, nofiles, i, temp, FileExtOfs,
  NoDirRecords, RecordID, StartIndex, EndIndex, UN1, UN2: integer;
begin
  thefile.Position:=0;
  blockname:=thefile.readblockname;
  if blockname='ZPKG' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Filecheck ok!');
  end
  else
  if blockname='ZLIB' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('File is Zlib Compressed... exiting');
    exit;
  end
  else
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid header...exiting');
    exit;
  end;

  //Read Header
  thefile.seek(4, sofromcurrent); //version
  thefile.seek(4, sofromcurrent); //file types dir dir end
  NoFiles:=thefile.readdword;     //number of files
  RecordsEnd:=thefile.readdword;  //end of file records
  thefile.seek(4, sofromcurrent); //?
  NameDirOfs:=thefile.readdword;  //name dir offset
  FileExtOfs:=thefile.readdword;  //file types dir offset

  //Setup Arrays
  Setlength(offsets, NoFiles);
  Setlength(filesizes, NoFiles);
  Setlength(fileExtensions, NoFiles);

  //Parse File Records
  thefile.seek(512, sofrombeginning);
  i:=-1;
  while thefile.Position < RecordsEnd do
  begin
    thefile.seek(1, sofromcurrent); //null
    temp:=thefile.readword; //offset in file ext dir
    thefile.seek(1, sofromcurrent); //null
    inc(i);
    FileExtensions[i]:=GetPKGFileExt(FileExtOfs + temp);
    GetPKGFileName(i, integer(thefile.ReadDWord) + namedirofs, '.' + FileExtensions[i]);
    offsets[i] := thefile.ReadDWord;
    filesizes[i] := thefile.ReadDWord;
    if Assigned(fondebug) then
    fondebug(inttostr(i) +  Chr(9) + Chr(9) + FileNames[i]);
  end;

  TheFile.Position:=RecordsEnd;
  while thefile.Position < NameDirOfs do
  begin
    TempName:=TempName + chr(thefile.ReadByte);
    if TempName='/' then TempName:=PrevName + '/';

    TheFile.Seek(1, SoFromCurrent); //null
    UN1:=TheFile.ReadWord;
    UN2:=TheFile.ReadWord;
    RecordID:=TheFile.ReadWord;
    StartIndex:=TheFile.ReadWord;
    EndIndex:=TheFile.ReadWord;

       if Assigned(fondebug) then
       FOnDebug(inttostr(RecordID) +  Chr(9) +  Chr(9) + 'UN1=' + inttostr(UN1) + Chr(9) +  Chr(9) + 'UN2=' + inttostr(UN2) + Chr(9) +  Chr(9) +
      'Start=' + inttostr(StartIndex) + Chr(9) + Chr(9) + 'End=' + inttostr(EndIndex) + Chr(9) +   Chr(9) + 'Ofs=' + inttostr(thefile.position - 12) +   Chr(9) +   Chr(9) +  Chr(9) + TempName);



    if (Startindex <> 0) or (EndIndex <> 0) then
    begin


      PrevName:=TempName;
      TempName:='';
    end;

  end;

 {1 byte: one character of a directory name
  1 byte: null
  2 bytes: Unknown (seems to be a reference to another record if nonzero)
  2 bytes: Unknown (seems to be a reference to another record if nonzero)
  2 bytes: Record ID (starting with 1 and incrementing)
  2 bytes: Start index (inclusive)
  2 bytes: End Index (exclusive)

The characters read in each record add up to form a directory name.
Start index and and end index are usually zero unless the name is complete.
If start index or end index are nonzero, then the directory name is complete and
the entries in the file records in the given range belong to the directory name just read.
When a new directory name starts with a slash (/), the new name must be appended to the
one previously read.}


  if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);
end;

function TPsychoBundleReader.GetPKGFileExt(Offset: integer): string;
var
  FileExt, TempByte: string;
  Stop: boolean;
  CurrentPos: integer;
begin
  stop:=false;
  Currentpos:=thefile.position;
  FileExt:='';
  TheFile.seek(offset, sofrombeginning);
  while stop=false do
  begin
  tempbyte:=chr(thefile.readbyte);
  if tempbyte=#0 then
    stop:=true
  else
    fileext:=fileext + tempbyte;
  end;

  if fileext='' then
    if assigned(FOnDebug) then
      FOnDebug('oi! no file extension!');

  thefile.Position:=CurrentPos;
  result:={'.' +} FileExt;
end;

procedure TPsychoBundleReader.GetPKGFileName(ArrayPos, Offset: integer; fileext: string);
var
  Currentpos: integer;
  stop: boolean;
  tempbyte, filename: string;
begin
  Stop:=false;
  Currentpos:=thefile.position;
  thefile.Seek(Offset, sofrombeginning);
  while stop=false do
  begin
    tempbyte:=chr(thefile.readbyte);
    if tempbyte=#0 then
      stop:=true
    else
      filename:=filename + tempbyte;
  end;

  if filename='' then
    if assigned(FOnDebug) then
      FOnDebug('oi! no filename!');
  filenames.Add(filename + fileext);
  thefile.Position:=Currentpos;
end;

function TPsychoBundleReader.GetDDSSize(MinimumNoBytes, Mipmaps, TextureSize: integer): integer;
var
  total, temp, i: integer;
begin
  if mipmaps < 2 then
    result:=TextureSize
  else
  begin
    total:=TextureSize;
    temp:=total;
    for i:=0 to mipmaps -2 do
    begin
      if temp div 4 < MinimumNoBytes then
        inc(total, MinimumNoBytes)
      else
      begin
        temp:=temp div 4;
        inc(total, temp);
      end;
    end;
    result:=total;
  end;
end;

function TPsychoBundleReader.GetDDSSizeNonSquare(MinimumNoBytes, Mipmaps, TextureSize, width, height: integer): integer;
var
  total, temp, i, CurrWidth, CurrHeight: integer;
begin
  CurrWidth:=Width;
  CurrHeight:=Height;

  if mipmaps < 2 then
    result:=TextureSize
  else
  begin
    total:=TextureSize;
    for i:=0 to mipmaps -2 do
    begin
      CurrWidth:=Max(1, CurrWidth div 2);
      CurrHeight:=Max(1, CurrHeight div 2);

      temp:=Max(1, CurrWidth div 4) * Max(1, CurrHeight div 4) * MinimumNoBytes;
      inc(total, temp);
    end;
    result:=total;
  end;
end;

procedure TPsychoBundleReader.ParsePPAKdds(TextureID, Mipmaps, Width, Height: integer; filename: string);
var
  temp, total: integer;
begin
    case TextureId of
    0:  begin {rgba8?}
          if pos('fonts', filename) > 0 then //fonts dont need mipmaps correcting
          else
          if (mipmaps=0) or (width<>height) then
          begin
            temp:=min(width, height);
            case temp of
              512:  mipmaps:=10;
              256:  mipmaps:=9;
              128:  mipmaps:=8;
              64:   mipmaps:=7;
              32:   mipmaps:=6;
              16:   mipmaps:=5;
              8:    mipmaps:=4;
              4:    mipmaps:=3;
              2:    mipmaps:=2;
              1:    mipmaps:=1
              else
                Mipmaps:=1;
            end;
          end;

          total:=GetDDSSize(1, Mipmaps,  (Width * Height) * 4);
        end;
    6:  begin
          total:=GetDDSSize(16, Mipmaps,  (Width * Height));
        end;
    9:  begin {dxt1 no alpha?}
          if width <> height then
            total:=GetDDSSizeNonSquare(8, Mipmaps, (Width * Height) div 2, width, height)
          else
            total:=GetDDSSize(8, MipMaps, (Width * Height) div 2);
        end;
    10: begin
          if width <> height then
            total:=GetDDSSizeNonSquare(16, Mipmaps, (Width * Height), Width, Height)
          else
            total:=GetDDSSize(16, Mipmaps,  (Width * Height));
        end;
    11: begin {dxt5?}
          if width <> height then
            total:=GetDDSSizeNonSquare(16, Mipmaps, (Width * Height), Width, Height)
          else
            total:=GetDDSSize(16, Mipmaps,  (Width * Height));
        end;
    12: begin
          if width <> height then
            total:=GetDDSSizeNonSquare(1, Mipmaps, (Width * Height)*2, Width, Height)
          else
            total:=GetDDSSize(1, Mipmaps,  (Width * Height)*2);
        end;
    14: begin
          if (mipmaps=0) or (width<>height) then
          begin
            temp:=min(width, height);
            case temp of
              512:  mipmaps:=10;
              256:  mipmaps:=9;
              128:  mipmaps:=8;
              64:   mipmaps:=7;
              32:   mipmaps:=6;
              16:   mipmaps:=5;
              8:    mipmaps:=4;
              4:    mipmaps:=3;
              2:    mipmaps:=2;
              1:    mipmaps:=1
              else
                Mipmaps:=1;
            end;
          end;

          temp:=thefile.readword;
          total:=GetDDSSize(1, Mipmaps,  (Width * Height));
          if (temp=256) or (temp=1) then //has a palette
            inc(total, 1026)
          else
            inc(total, 2);

          thefile.Seek(-2, sofromcurrent);
        end;
    else
        begin
          if assigned(FOnDebug) then
            FOnDebug('Unsupported ID = ' + inttostr(textureid));
          total:=0;
        end;
    end;

    if pos('cubemaps', filename) > 0 then  //its a cubemap
      total:=total * 6;

    //if assigned(fondebug) then fondebug('total size= ' + inttostr(total));
    thefile.Seek(total, sofromcurrent);
end;

procedure TPsychoBundleReader.ParsePPAKMultipleDDS(NumFrames, TextureID, Mipmaps, Width, Height: integer; filename: string);
var
  i: integer;
begin
  //Parse the first 'frame' of texture data
  ParsePPAKdds(TextureID, Mipmaps, Width, Height,filename);

  //Then for the other frames
  for i:=0 to NumFrames -2 do
  begin
    //then the 44 byte header
    thefile.seek(4, sofromcurrent);
    TextureID:=thefile.ReadWord;;
    thefile.Seek(10, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    thefile.Seek(16, sofromcurrent);

    //then the texture data again
    ParsePPAKdds(TextureID, Mipmaps, Width, Height, filename);
  end;
end;

procedure TPsychoBundleReader.ParsePS2Audio;
var
  BlockName: string;
  i: integer;
begin
  thefile.Position:=0;

  blockname:=thefile.readblockname;
  if blockname='WB  ' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Filecheck ok');
  end
  else
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid header...exiting');
    exit;
  end;


  Setlength(filesizes, 10);
  Setlength(offsets, 10);

  thefile.Seek(48, sofrombeginning);

  for i:=0 to 10 do
  begin
   thefile.Seek(4, sofromcurrent);
   offsets[i]:=thefile.ReadDWord + 2048;
   filesizes[i]:=thefile.ReadWord;
   thefile.Seek(12, sofromcurrent);
  end;
    

end;

procedure TPsychoBundleReader.ParsePPAK;
var
  BlockName: string;
  NoFiles, temp, i, j, PrevNoFiles, textureid,
  width, height, mipmaps, ID1, ID2, NewTextureID: integer;
begin
  thefile.Position:=0;

  blockname:=thefile.readblockname;
  if blockname='PPAK' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Filecheck ok');
  end
  else
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid header...exiting');
    exit;
  end;

  nofiles:=GetPPAKnofiles; //Need to work out total no of files
  Setlength(filesizes, nofiles);
  Setlength(offsets, nofiles);
  //if assigned(FOnDebug) then fondebug(inttostr(totalfiles));


  //DDS
  nofiles:=thefile.ReadWord;
  //if assigned(FOnDebug) then
  //  FOnDebug('No dds files = ' + inttostr(nofiles));
  {Setlength(filesizes, nofiles);
  Setlength(offsets, nofiles);}

  for i:=0 to nofiles -1 do
  begin
    //if assigned(FOnDebug) then FOnDebug('Filepos = ' + inttostr(thefile.position));
    thefile.Seek(40, sofromcurrent);

    //Filename
    temp:=thefile.ReadWord;
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      Blockname:=BlockName + chr(thefile.readbyte);
    end;
    thefile.Seek(1, sofromcurrent); //seek past the null byte
    FileNames.Add(Trim(BlockName));
    offsets[i]:=thefile.position;
    temp:=thefile.Position;

    //if assigned(FOnDebug) then FOnDebug(BlockName);
    ID1:=thefile.ReadWord;
    ID2:=thefile.ReadWord;
    {if assigned(FOnDebug) then FOnDebug('ID = ' + inttostr(ID1));
    if assigned(FOnDebug) then FOnDebug('ID 2 = ' + inttostr(ID2));}
    TextureId:=thefile.ReadWord;
    //if assigned(FOnDebug) then FOnDebug('Texture ID = ' + inttostr(textureid));
    thefile.Seek(10, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    thefile.Seek(4, sofromcurrent);
    NewTextureID:=thefile.ReadWord;
    {if assigned(FOnDebug) then FOnDebug('Width = ' + inttostr(Width));
    if assigned(FOnDebug) then FOnDebug('Height = ' + inttostr(Height));
    if assigned(FOnDebug) then FOnDebug('Mipmaps = ' + inttostr(Mipmaps));
    if assigned(FOnDebug) then FOnDebug('New Texture ID = ' + inttostr(NewTextureID));}
    thefile.Seek(10, sofromcurrent);



    if (ID2=0) then //Its an animation/multiple images
    begin
      Width:=thefile.ReadDWord;
      Height:=thefile.ReadDWord;
      Mipmaps:=thefile.ReadDWord;
      {if assigned(FOnDebug) then FOnDebug('New Width = ' + inttostr(Width));
      if assigned(FOnDebug) then FOnDebug('New Height = ' + inttostr(Height));
      if assigned(FOnDebug) then FOnDebug('New Mipmaps = ' + inttostr(Mipmaps));}
      thefile.seek(16, sofromcurrent);
    end;

    //if assigned(FOnDebug) then FOnDebug('');



    if (ID2=0) and (TextureID=0) then
      ParsePPAKMultipleDDS(ID1, NewTextureID, Mipmaps, Width, Height, BlockName)
    else
      ParsePPAKdds(TextureID, Mipmaps, Width, Height, BlockName);

    FileSizes[i]:=thefile.Position - temp;

    {if (textureid=0) or (textureid=6) or (textureid=9) or (textureid=10) or (textureid=11) or (textureid=12) or (textureid=14) then
    else break;}
  end;

  {if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);
  exit;}


  {totalfiles:=GetPPAKnofiles; //Need to work out total no of files
  Setlength(filesizes, totalfiles);
  Setlength(offsets, totalfiles);}
  //if assigned(FOnDebug) then fondebug(inttostr(totalfiles));



  //MPAK Section

  thefile.seek(4, sofromcurrent); //past 'MPAK'
  PrevNoFiles:=NoFiles;
  NoFiles:=thefile.readword;
  //if assigned(FOnDebug) then
  //  FOnDebug('No of MPAK files = ' + inttostr(nofiles));

  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) -1 do
  //for i:=0 to nofiles -1 do
  begin
    temp:=thefile.readword; //Filename length

    //Filename
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      Blockname:=BlockName + chr(thefile.readbyte);
    end;
    thefile.Seek(1, sofromcurrent);

    FileNames.Add(BlockName);
    thefile.Seek(2, sofromcurrent); //??

    temp:=thefile.ReadDWord; //data block
    Filesizes[i]:=temp;
    Offsets[i]:=thefile.Position; //data offset
    thefile.Seek(temp, sofromcurrent);
  end;
  PrevNoFiles:=PrevNoFiles + NoFiles;

  //Named Scripts Section
  //PrevNoFiles:=NoFiles;
  NoFiles:=thefile.readword;
  //if assigned(FOnDebug) then
  //  FOnDebug('No of named script files = ' + inttostr(nofiles));

  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) -1 do
  begin
    temp:=thefile.readword; //Filename length

    //Filename
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      Blockname:=BlockName + chr(thefile.readbyte);
    end;
    thefile.Seek(1, sofromcurrent);

    FileNames.Add(BlockName + '.lua');

    temp:=thefile.ReadDWord; //data block
    Filesizes[i]:=temp;
    Offsets[i]:=thefile.Position; //data offset
    thefile.Seek(temp, sofromcurrent);
  end;
    PrevNoFiles:=PrevNoFiles + NoFiles;

  //Unnamed Scripts Section
  NoFiles:=thefile.readword;
  //if assigned(FOnDebug) then
  //  FOnDebug('No of unnamed script files = ' + inttostr(nofiles));
    
  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) - 1 do
  begin
    Filenames.add('Script ' + inttostr(i - PrevNoFiles + 1) + '.lua');
    temp:=thefile.ReadDWord; //data block
    Filesizes[i]:=temp;
    Offsets[i]:=thefile.Position; //data offset
    thefile.Seek(temp, sofromcurrent);
  end;
    PrevNoFiles:=PrevNoFiles + NoFiles;

  //level? section
  if thefile.Position >= thefile.Size then
  begin
    if (assigned(FOnDoneLoading)) then
      FOnDoneLoading(filenames.count);
      
    exit; //some files dont have this section
  end;

  //Filenames.add('Unknown file from ' + extractfilename(ResFileName));
  Filenames.Add(pathextractfilenamenoext(ResFileName) + ' level file.plb');
  Filesizes[PrevNoFiles]:=thefile.Size - thefile.Position;
  Offsets[PrevNoFiles]:=thefile.Position; //data offset


  if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);
end;


function TPsychoBundleReader.GetPPAKnofiles: integer;
var
  Origpos, num, i, temp: integer;
  BlockName: string;
  j, ID1, ID2, TextureID, NewTextureID, Width, Height, Mipmaps: integer;
begin
  Origpos:=thefile.position;

  //dds files
  num:=thefile.readword;
  result:=num;
  for i:=0 to num -1 do //seek past section
  begin
    thefile.Seek(40, sofromcurrent);

    //Filename
    temp:=thefile.ReadWord;
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      Blockname:=BlockName + chr(thefile.readbyte);
    end;
    thefile.Seek(1, sofromcurrent); //seek past the null byte

    ID1:=thefile.ReadWord;
    ID2:=thefile.ReadWord;
    TextureId:=thefile.ReadWord;
    thefile.Seek(10, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    thefile.Seek(4, sofromcurrent);
    NewTextureID:=thefile.ReadDWord;
    thefile.Seek(8, sofromcurrent);


    if (ID2=0) then //Its an animation/multiple images
    begin //Another 28 bytes in header
      Width:=thefile.ReadDWord;
      Height:=thefile.ReadDWord;
      Mipmaps:=thefile.ReadDWord;
      thefile.seek(16, sofromcurrent);
    end;

    if (ID2=0) and (TextureID=0) then
      ParsePPAKMultipleDDS(ID1, NewTextureID, Mipmaps, Width, Height, BlockName)
    else
      ParsePPAKdds(TextureID, Mipmaps, Width, Height, BlockName);

    {if (textureid) or (newtextureid) in [0,6, 9,10,11,12,14]=false then break;}
  end;

  //MPAK files
  thefile.seek(4, sofromcurrent); //seek past 'MPAK'
  num:=thefile.readword;
  inc(result,num);
  for i:=0 to num -1 do //seek past section
  begin
    temp:=thefile.readword;//filename length
    thefile.Seek(temp, sofromcurrent);
    thefile.seek(2, sofromcurrent);
    temp:=thefile.ReadDWord;//data length
    thefile.Seek(temp, sofromcurrent);
  end;

  //Named scripts
  num:=thefile.readword;
  inc(result,num);
  for i:=0 to num -1 do //seek past section
  begin
    temp:=thefile.readword;//filename length
    thefile.Seek(temp, sofromcurrent);
    temp:=thefile.ReadDWord;//data length
    thefile.Seek(temp, sofromcurrent);
  end;

  //Unnamed scripts
  num:=thefile.readword;
  inc(result,num);

  inc(result,1); //for level? file at end

  thefile.Position:=Origpos;
end;


procedure TPsychoBundleReader.ParsePcAudio;
var
  I, fileno, currpos: Integer;
  BlockName, FileName, TempString: string;
  BlockSize: integer;
begin
  FileNo:=0;
  thefile.position:=0;
  blockname:=thefile.readblockname;
  thefile.Seek(4, sofromcurrent);
  TempString:=thefile.ReadBlockName;
  thefile.Seek(-8, sofromcurrent);
  if (blockname <> 'RIFF') or (TempString <> 'isbf') then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid file!...Aborting');
    if assigned(FOnDebug) then
      FOnDebug('Header is ' + blockname + ' isbf header = ' + TempString);
    exit;
  end
  else if assigned(FOnDebug) then
    FOnDebug('Filecheck ok. Scanning for sound files...');

  thefile.Seek(4, sofromcurrent); //filesize
  thefile.Seek(8, sofromcurrent); //Seek past ''isbftitl'' bytes
  blocksize:=thefile.ReadDWord; //text block
  thefile.Seek(blocksize, sofromcurrent); //seek past

  //get number of files + setup arrays accordingly
  i:=0;
  currpos:=thefile.Position;
  while thefile.Position <> thefile.Size do
  begin
    blockname:=thefile.readblockname;
    blocksize:=thefile.ReadDWord;
    if blockname='LIST' then
    begin
      thefile.Seek(8, sofromcurrent);
      blocksize:=thefile.ReadDWord;
      thefile.Seek(blocksize, sofromcurrent);
      continue;
    end;
    if blockname='data' then
    begin
      inc(i);
      if blocksize mod 2 <> 0 then
        blocksize:=blocksize+1;
    end;
      thefile.Seek(blocksize, sofromcurrent);
      application.ProcessMessages;
  end;

  if i=0 then //Check for cabhmusic - file has no audio inside it, its just a header
  begin
    raise EInvalidFile.Create('No audio files found!');
    Exit;
  end;

  Setlength(offsets, i);
  setlength(filesizes, i);
  //if assigned(FOnDebug) then FOnDebug(inttostr(i));
  thefile.Position:=currpos;


  while thefile.Position <> thefile.Size do
  begin
    blockname:=thefile.readblockname;

    if blockname='LIST' then
    begin
      thefile.Seek(4, sofromcurrent); //list block size
      thefile.Seek(8, sofromcurrent); //Seek past ''isbftitl'' bytes
      blocksize:=thefile.ReadDWord;

      TempString:='';
      filename:='';
      for I := 0 to blocksize - 1 do
      begin
        TempString:=chr(thefile.readbyte);
        if TempString=#0 then
        else
          filename:=filename + TempString;
      end;
      continue;
    end;

    if blockname='sinf' then
    begin
      thefile.Seek(12, sofromcurrent);
      thefile.seek(4, sofromcurrent);//samplerate:=thefile.ReadDWord;
      thefile.Seek(8, sofromcurrent);
      continue;
    end;

    if blockname='chnk' then
    begin
      thefile.Seek(4, sofromcurrent);
      thefile.seek(4, sofromcurrent);//PCchannels:=thefile.ReadDWord;
      continue;
    end;

    if blockname='cmpi' then
    begin
      thefile.Seek(24, sofromcurrent);
      if thefile.ReadDWord=1053609165 then
        //IsPCM:=true
      else
        ;//IsPCM:=false;
      continue;
    end;

    if blockname='data' then
    begin
      blocksize:=thefile.ReadDWord;
      if blocksize mod 2 <> 0 then
        blocksize:=blocksize+1;

      if thefile.ReadBlockName='OggS' then
      begin
        //IsOgg:=true;
      end
      else
        ; //IsOgg:=false;

      thefile.Seek(-4, sofromcurrent);

      FileNames.Add(filename);
      Filesizes[fileno]:=blocksize;
      Offsets[fileno]:=thefile.Position ;
      inc(FileNo);
      thefile.Seek(blocksize, sofromcurrent);
      application.processmessages;
      continue;
    end;

    blocksize:=thefile.ReadDWord;
    thefile.Seek(blocksize, sofromcurrent);
  end;

if assigned(FOnDebug) then
    FOnDebug('...Done.');
  if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);
end;


procedure TPsychoBundleReader.CheckZlib;
var
  blockname, tempname: string;
begin
  thefile.Position:=0;
  blockname:=thefile.readblockname;
  if blockname='ZLIB' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('File is compressed...decompressing...');
    application.ProcessMessages;
    decompressZlib;
    //thefile.Free;

    tempname:=extractfilename(ResFileName);
    thefile:=tpsychofilestream.Create(Getwindowstempfolder + '\' + tempname);
    ResFileName:=Getwindowstempfolder + '\' + tempname;
    TempFileCreated:=true;

    //Go back through the calling procedure, but reinitialize things first
    ReadHeader;
    if FileType='unknown' then
      raise EInvalidFile.Create('Not a valid Psychonauts resource file');

    ParseFiles;
  end
  else
end;

procedure TPsychoBundleReader.DecompressZlib;
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
end;

procedure TPsychoBundleReader.ParseXBoxAudio;
var
  BlockName, temp: string;
  i, NoEntries, FileOfs, TempInt: integer;
begin
  Thefile.Position:=0;
  blockname:=thefile.readblockname;
  if blockname <> 'WBND' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid file!...Aborting');
    exit;
  end
  else
    if assigned(FOnDebug) then
      FOnDebug('Filecheck ok. Scanning for sound files...');


  thefile.Seek(40, sofromcurrent); //past wave bank header
  NoEntries:=thefile.ReadDWord;
  thefile.Seek(24, sofromcurrent);
  fileofs:=thefile.ReadDWord;
  thefile.Seek(4, sofromcurrent);

  //Section 2
  Setlength(Offsets, noentries);
  Setlength(FileSizes, noentries);

  //If its in the same folder
  temp:=PathExtractFilenameNoExt(ResFileName) + '.xsb';
  if fileexists(temp) then
  begin
    if assigned(FOnDebug) then FOnDebug('Corresponding XSF file found, now using internal file names for dumping');
    ParseXSB(temp);
  end;

  //If its in the folders as on the cd
  temp:=PathRemoveExtension(ResFileName) + '.xsb';//Extractfiledir(ResFile + '\' + '.xsb');
  strreplace(temp, 'XACT Wavebanks', 'XACT Soundbanks',[rfignorecase]);
  if fileexists(temp) then
  begin
    if assigned(FOnDebug) then FOnDebug('Corresponding XSF file found, now using internal file names for dumping');
    ParseXSB(temp);
  end;

  for I := 0 to noentries - 1 do
  begin
    thefile.seek(8, sofromcurrent);
    TempInt:=thefile.ReadDWord;
    Offsets[i]:=TempInt + FileOfs;
    FileSizes[i]:=thefile.ReadDWord;
    thefile.seek(8, sofromcurrent);

    if i > length(XSBFileNames)-1 then //no more xsb filenames
      FileNames.Add(pathextractfilenamenoext(ResFileName) + inttostr(i+1) + '.wav')
    else
    if length(XSBFileNames)>0 then //use the xsb name
      FileNames.Add(XSBFileNames[i])
    else
      FileNames.Add(pathextractfilenamenoext(ResFileName) + inttostr(i+1));
  end;

  if assigned(FOnDebug) then
    FOnDebug('...Done.');

  if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);
end;

procedure TPsychoBundleReader.ParseXSB(Path: string);
var
  I: Integer;
  XSBfile: tfilestream;
  BlockName, FileName: string;
  TempInt, NoFiles: integer;
  abyte: byte;
  aword: word;
  aDword: longword;
begin
  XSBfile:=tfilestream.Create(Path , fmopenread);
  try
    xsbfile.Read(abyte, 1);
    BlockName:=BlockName + chr(abyte);
    xsbfile.Read(abyte, 1);
    BlockName:=BlockName + chr(abyte);
    xsbfile.Read(abyte, 1);
    BlockName:=BlockName + chr(abyte);
    xsbfile.Read(abyte, 1);
    BlockName:=BlockName + chr(abyte);

    if BlockName <> 'SDBK' then
    begin
      If assigned(FOnDebug) then FOnDebug('Invalid .XSB soundbank file...');
      exit;
    end;

    XSBfile.Seek(30, sofrombeginning);
    XSBfile.Read(aword, 2); //no of files in name dir
    Nofiles:=aword;

    Setlength(XSBFileNames, nofiles);

    XSBfile.Seek(60, sofrombeginning);
    XSBfile.Read(aDword, 4); //offset of namedir
    tempint:=aDword;

    XSBfile.Seek(tempint, sofrombeginning);

    abyte:=1;
    //Put filenames in the array
    for I := 0 to Nofiles - 1 do
    begin
      while abyte <> 0 do
      begin
        xsbfile.Read(abyte,1);
        if abyte=0 then
        else
          filename:= filename + chr(abyte);
      end;

      XSBFileNames[i]:=Filename + '.wav';
      filename:='';
      abyte:=1;
    end;

  finally
    XSBfile.Free;
  end;
end;


procedure TPsychoBundleReader.GetDDSFileInfo(offset: integer; var Width, Height,
  Mipmaps, TextureID, SeekVal: integer);
var
  ID2, NewTextureID: integer;
begin
  thefile.Seek(offset, sofrombeginning);
  thefile.Seek(2, sofromcurrent);
  ID2:=thefile.ReadWord;
  TextureID:=thefile.ReadWord;
  thefile.seek(10, sofromcurrent);
  Width:=thefile.ReadDWord;
  Height:=thefile.ReadDWord;
  Mipmaps:=thefile.ReadDWord;
  thefile.Seek(4, sofromcurrent);
  NewTextureID:=thefile.ReadWord;
  SeekVal:=44;

  if (ID2=0) and (TextureID=0) then
  begin
    thefile.Seek(10, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    SeekVal:=72;
  end;
end;


procedure TPsychoBundleReader.ParsePs2File;
const
  LevelOffsets: array[0..49] of integer = (663617536, 673284096, 684294144, 697237504,
  706150400, 719618048, 731217920, 743276544, 749862912, 759398400, 765132800, 780632064,
  785416192, 790298624, 795049984, 799866880, 812974080, 826277888, 831979520, 845742080,
  859602944, 872284160, 886996992, 901808128, 911245312, 920748032, 935460864, 949944320,
  963117056, 976846848, 985726976, 987529216, 999784448, 1006501888, 1019314176, 1031667712,
  1046446080, 1060601856, 1070432256, 1081049088, 1085734912, 1097760768, 1108574208, 1114013696,
  1129742336, 1139539968, 1142816768, 1152450560, 1158578176, 1171456000);
var
  TotalFiles, i, prevnofiles: integer;
begin
  TotalFiles:=0;
  for i:=low(leveloffsets) to high(leveloffsets) do
  begin
    thefile.Position:=LevelOffsets[i];
    thefile.Seek(4, sofromcurrent);
    TotalFiles:=TotalFiles + GetPS2PPAKnofiles;
  end;

  Setlength(filesizes, TotalFiles);
  Setlength(offsets, TotalFiles);
  Prevnofiles:=0;
  for i:=low(leveloffsets) to high(leveloffsets) do
  begin
    thefile.Position:=LevelOffsets[i];
    ParsePS2PPAK(prevnofiles);
  end;

  if (assigned(FOnDoneLoading)) then FOnDoneLoading(filenames.count);
end;

procedure TPsychoBundleReader.ParsePs2PPAK(var prevnofiles: integer);
var
  BlockName, TempString: string;
  i, j, NoFiles, Temp, TextureID, Width, Height, MipMaps, NewTextureID, ID1, ID2: integer;
begin
  //thefile.Position:=663617536;//663617536;

  blockname:=thefile.readblockname;
  if blockname='PPAK' then
  begin
    if assigned(FOnDebug) then
      FOnDebug('Filecheck ok');
  end
  else
  begin
    if assigned(FOnDebug) then
      FOnDebug('Invalid header...exiting');
    exit;
  end;

  nofiles:=GetPS2PPAKnofiles; //Need to work out total no of files
  //Setlength(filesizes, nofiles);
  //Setlength(offsets, nofiles);
  if assigned(FOnDebug) then fondebug('No Files = ' + inttostr(nofiles));

  NoFiles:=thefile.ReadWord;
  
  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) -1 do
  //for i:=0 to nofiles -1 do
  begin
    //if assigned(FOnDebug) then FOnDebug('Filepos = ' + inttostr(thefile.position-663617536));
    thefile.Seek(40, sofromcurrent);
    //if assigned(FOnDebug) then FOnDebug('FileNo = ' + inttostr(i));

    //Filename
    temp:=thefile.ReadWord;
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      TempString:=chr(thefile.readbyte);
      if TempString='/' then TempString:='\';
      Blockname:=BlockName + TempString;
    end;
    thefile.Seek(1, sofromcurrent); //seek past the null byte
    FileNames.Add(BlockName);
    offsets[i]:=thefile.position;
    temp:=thefile.Position;

    //if assigned(FOnDebug) then FOnDebug(BlockName);
    ID1:=thefile.ReadWord;
    ID2:=thefile.ReadWord;
    TextureId:=thefile.ReadWord;
    //if assigned(FOnDebug) then FOnDebug('Texture ID = ' + inttostr(textureid));
    thefile.Seek(6, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    thefile.Seek(4, sofromcurrent);
    NewTextureID:=thefile.ReadWord;
    {if assigned(FOnDebug) then FOnDebug('Width = ' + inttostr(Width));
    if assigned(FOnDebug) then FOnDebug('Height = ' + inttostr(Height));
    if assigned(FOnDebug) then FOnDebug('Mipmaps = ' + inttostr(Mipmaps));
    if assigned(FOnDebug) then FOnDebug('New Texture ID = ' + inttostr(NewTextureID));}
    thefile.Seek(12, sofromcurrent);



    if (ID1 <> 0)  then //Its an animation/multiple images
    begin //Bigger header
      //if assigned(FOnDebug) then FOnDebug('ITS AN ANIMATION');
      thefile.Seek(-6, sofromcurrent);
      Width:=thefile.ReadDWord;
      Height:=thefile.ReadDWord;
      Mipmaps:=thefile.ReadDWord;
      thefile.seek(18, sofromcurrent);
    end;
    {if assigned(FOnDebug) then FOnDebug('NEWWidth = ' + inttostr(Width));
    if assigned(FOnDebug) then FOnDebug('NEWHeight = ' + inttostr(Height));
    if assigned(FOnDebug) then FOnDebug('NEWMipmaps = ' + inttostr(Mipmaps));}

    //if textureid <> 14 then
    //  if assigned(FOnDebug) then FOnDebug('OI! ITS NOT 14!!!!!!!!!!');

    if (ID2=0) and (TextureID=0) then
      ParsePS2MultipleImage(ID1, NewTextureID, Mipmaps, Width, Height, BlockName)
    else
      ParsePS2Image(TextureID, Mipmaps, Width, Height, BlockName);

    FileSizes[i]:=thefile.Position - temp;
  end;


  //MPAK Section
  thefile.seek(4, sofromcurrent); //past 'MPAK'
  //PrevNoFiles:=NoFiles;
  PrevNoFiles:=PrevNoFiles + NoFiles;
  NoFiles:=thefile.readword;
  //if assigned(FOnDebug) then FOnDebug('No of MPAK files = ' + inttostr(nofiles));

  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) -1 do
  begin
    temp:=thefile.readword; //Filename length

    //Filename
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      TempString:=chr(thefile.readbyte);
      if TempString='/' then TempString:='\';
      Blockname:=BlockName + TempString
    end;
    thefile.Seek(1, sofromcurrent);

    FileNames.Add(BlockName);
    thefile.Seek(2, sofromcurrent); //??

    temp:=thefile.ReadDWord; //data block
    Filesizes[i]:=temp;
    Offsets[i]:=thefile.Position; //data offset
    thefile.Seek(temp, sofromcurrent);
  end;
  PrevNoFiles:=PrevNoFiles + NoFiles;
  //if assigned(FOnDebug) then fondebug(inttostr(thefile.Position - 663617536));

  //Named Scripts Section
  NoFiles:=thefile.readword;
  //if assigned(FOnDebug) then FOnDebug('No of named script files = ' + inttostr(nofiles));

  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) -1 do
  begin
    temp:=thefile.readword; //Filename length

    //Filename
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      TempString:=chr(thefile.readbyte);
      if TempString='/' then TempString:='\';
      Blockname:=BlockName + TempString
    end;
    thefile.Seek(1, sofromcurrent);

    FileNames.Add(BlockName + '.lua');

    temp:=thefile.ReadDWord; //data block
    Filesizes[i]:=temp;
    Offsets[i]:=thefile.Position; //data offset
    thefile.Seek(temp, sofromcurrent);
  end;
    PrevNoFiles:=PrevNoFiles + NoFiles;
  //if assigned(FOnDebug) then fondebug(inttostr(thefile.Position - 663617536));

  //Unnamed Scripts Section
  NoFiles:=thefile.readword;                   
  //if assigned(FOnDebug) then FOnDebug('No of unnamed script files = ' + inttostr(nofiles));
    
  for i:=PrevNoFiles to (PrevNoFiles + NoFiles) - 1 do
  begin
    Filenames.add('Script ' + inttostr(i - PrevNoFiles + 1) + '.lua');
    temp:=thefile.ReadDWord; //data block
    Filesizes[i]:=temp;
    Offsets[i]:=thefile.Position; //data offset
    thefile.Seek(temp, sofromcurrent);
  end;
    PrevNoFiles:=PrevNoFiles + NoFiles;
 //if assigned(FOnDebug) then fondebug(inttostr(thefile.Position - 663617536));


  //level? section
  BlockName:=thefile.ReadBlockName;
  thefile.Seek(-4, sofromcurrent);

  if BlockName <> 'CYSP' then //level file isnt there
  begin
    {if (assigned(FOnDoneLoading)) then
      FOnDoneLoading(filenames.count);}

    exit; //some files dont have this section
  end;

  Filenames.add('level file.plb');  //'Level file from ' + extractfilename(ResFileName));
  Filesizes[PrevNoFiles]:=1;//thefile.Size - thefile.Position;
  Offsets[PrevNoFiles]:=thefile.Position; //data offset
  inc(prevnofiles,1);

  {if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);}
end;


procedure TPsychoBundleReader.ParsePS2Image(TextureID, Mipmaps, Width, Height: integer; filename: string);
var
  total: integer;
begin
    case TextureId of
    14: begin
          total:=GetDDSSize(1, Mipmaps,  (Width * Height));
          inc(total, 1080);
        end;                                       
    else
        begin
          if assigned(FOnDebug) then
            FOnDebug('Unsupported ID = ' + inttostr(textureid));
          total:=0;
        end;
    end;

    //if assigned(fondebug) then fondebug('total size= ' + inttostr(total));
    thefile.Seek(total, sofromcurrent);
end;

procedure TPsychoBundleReader.ParsePS2MultipleImage(NumFrames, TextureID, Mipmaps, Width, Height: integer; filename: string);
var
  i: integer;
begin
  //Parse the first 'frame' of texture data
  ParsePS2Image(TextureID, Mipmaps, Width, Height,filename);

  //Then for the other frames
  for i:=0 to NumFrames -2 do
  begin
    //then the header
    thefile.seek(4, sofromcurrent);
    TextureID:=thefile.ReadWord;;
    thefile.Seek(6, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    thefile.Seek(18, sofromcurrent);

    //then the texture data again
    ParsePS2Image(TextureID, Mipmaps, Width, Height, filename);
  end;
end;

function TPsychoBundleReader.GetPS2PPAKnofiles: integer;
var
  Origpos, num, i, temp: integer;
  BlockName: string;
  j, ID1, ID2, TextureID, NewTextureID, Width, Height, Mipmaps: integer;
begin
  Origpos:=thefile.position;

  //Image files
  num:=thefile.readword;
  result:=num;
  for i:=0 to num -1 do //seek past section
  begin
    thefile.Seek(40, sofromcurrent);

    //Filename
    temp:=thefile.ReadWord;
    BlockName:='';
    for j:=0 to temp -2 do //-2 because of null byte in filename
    begin
      Blockname:=BlockName + chr(thefile.readbyte);
    end;
    thefile.Seek(1, sofromcurrent); //seek past the null byte

    ID1:=thefile.ReadWord;
    ID2:=thefile.ReadWord;
    TextureId:=thefile.ReadWord;
    thefile.Seek(6, sofromcurrent);
    Width:=thefile.ReadDWord;
    Height:=thefile.ReadDWord;
    Mipmaps:=thefile.ReadDWord;
    thefile.Seek(4, sofromcurrent);
    NewTextureID:=thefile.ReadWord;
    thefile.Seek(12, sofromcurrent);

    if (ID1 <>0) then //Its an animation/multiple images
    begin
      thefile.Seek(-6, sofromcurrent);
      Width:=thefile.ReadDWord;
      Height:=thefile.ReadDWord;
      Mipmaps:=thefile.ReadDWord;
      thefile.seek(18, sofromcurrent);
    end;

    if (ID2=0) and (TextureID=0) then
      ParsePS2MultipleImage(ID1, NewTextureID, Mipmaps, Width, Height, BlockName)
    else
      ParsePS2Image(TextureID, Mipmaps, Width, Height, BlockName);

  end;

  //MPAK files
  thefile.seek(4, sofromcurrent); //seek past 'MPAK'
  num:=thefile.readword;
  inc(result,num);
  for i:=0 to num -1 do //seek past section
  begin
    temp:=thefile.readword;//filename length
    thefile.Seek(temp, sofromcurrent);
    thefile.seek(2, sofromcurrent);
    temp:=thefile.ReadDWord;//data length
    thefile.Seek(temp, sofromcurrent);
  end;



  //Named scripts
  num:=thefile.readword;
  inc(result,num);
  for i:=0 to num -1 do //seek past section
  begin
    temp:=thefile.readword;//filename length
    thefile.Seek(temp, sofromcurrent);
    temp:=thefile.ReadDWord;//data length
    thefile.Seek(temp, sofromcurrent);
  end;

  //Unnamed scripts
  num:=thefile.readword;
  inc(result,num);

  inc(result,1); //for level? file at end

  thefile.Position:=Origpos;
end;

procedure TPsychoBundleReader.LoadPS2FromFile;
var
  LoadFile: tPsychoFilestream;
  res: TResourceStream;
  TempName: string;
  noitems, stringlength, i, j: integer;
begin
  if fileexists(extractfilepath(application.ExeName) + '\' + 'PS2Values.bgbb')= false then
  begin
    if assigned(FonDebug) then FOnDebug('PS2Values file not found! Extracting file to current dir. Psychonauts Explorer uses this file to work with the PS2 version, this is just a temporary measure and will not be required in future versions of the program.');
    if assigned(FonDebug) then FOnDebug('...done.');

    res:=TResourceStream.Create(0, 'PS2', 'DATA');
    try
      try
        res.SaveToFile(extractfilepath(application.ExeName) +'PS2Values.bgbb');
      except on efcreateerror do
        begin
          if assigned(FonDebug) then FOnDebug('Could not create PS2Values.bgbb ' + #13 + 'It is possible that you are running from a read-only location, like a cd');
        end;
      end;
    finally
      res.Free;
    end;
  end;

  if getsizeoffile(ResFileName) <> 3510413312 then
  begin
    if assigned(fondebug) then fondebug('Size of file does not match! Please report this. Your file size = ' + inttostr(getsizeoffile(ResFileName)));
    exit;
  end;

  LoadFile:=tPsychofilestream.Create(extractfilepath(application.ExeName) + '\' + 'PS2Values.bgbb');
  try
    if loadfile.ReadBlockName <> 'BGBB' then
    begin
      if assigned(fondebug) then fondebug('Invalid header!...exiting');
      exit;
    end;

    loadfile.Seek(4, sofromcurrent); //version

    if loadfile.ReadBlockName='NAME' then
    begin
      NoItems:=loadfile.ReadDWord;
      for i:=0 to NoItems -1 do
      begin
        StringLength:=loadfile.ReadDWord;
        TempName:='';
        for j:=0 to StringLength -1 do
          TempName:=TempName + chr(loadfile.ReadByte);

        FileNames.Add(TempName);
      end;
    end
    else
    begin
      if assigned(fondebug) then fondebug('NAME header expected, but not found...exiting');
      exit;
    end;

    if loadfile.ReadBlockName='SIZE' then
    begin
      NoItems:=loadfile.ReadDWord;
      SetLength(FileSizes, NoItems);
      for i:=0 to NoItems -1 do
      begin
        FileSizes[i]:=loadfile.ReadDWord;
      end;
    end
    else
    begin
      if assigned(fondebug) then fondebug('SIZE header expected, but not found...exiting');
      exit;
    end;

    if loadfile.ReadBlockName='OFFS' then
    begin
      NoItems:=loadfile.ReadDWord;
      SetLength(Offsets, NoItems);
      for i:=0 to NoItems -1 do
      begin
        OffSets[i]:=loadfile.ReadDWord;
      end;
    end
    else
    begin
      if assigned(fondebug) then fondebug('OFFS header expected, but not found...exiting');
      exit;
    end;
  finally
    LoadFile.Free;
  end;

 if (assigned(FOnDoneLoading)) then
    FOnDoneLoading(filenames.count);
end;

end.
