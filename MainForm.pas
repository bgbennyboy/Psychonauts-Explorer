{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

{BEFORE RELEASE CHECK:}
{
  Update help file
  Include freeimage.dll with program
  Compress exe with UPX
  Change build configuration from debug to release
}

{Optional}
{
  Preview of audio - play without dumping
  Tree autosizing/header adjusting? - double click header resize - resizes whole form?
  Icons in tree column headers?
  Splash/about screen? --HELP AND ABOUT BUTTONS PERHAPS?
  View as file tree? - using paths in level file names
  Save and convert all - like dump all where folders are made - everything dumped like that but also converted into a normal format. eg all images as png etc
  Access help file from program
  Implement drag and drop?
}

{Problems}
{
  XBox - a few sound problems remain - on 10 or so files
  PC/XBox - Some .dds images dont decode properly
  PS2 archive and image formats
  PS2 size of level .plb files
  ALL - DDS images that are animated - only view 1st cell - are these animated or just cubemaps?  
  ALL - BundleReader - procedures - May need to replace fondebug/exit with raise error
  ALL - Cube Maps - currently only viewing middle
  ALL - If text file selected eg .asd - and viewing all files - pressing save all text saves ALL text types not just asd - when filter is on this doesnt occur
}

{Added in 1.3}
{
  Fixed - possible small memory leak
  Fixed - Ensure suffix when saving images
  Image stretching/resampling - rewritten/tweaked
  Fixed - crash when opening empty sound file cabhmusic.isb
  Added - Speed improvements when saving individual images
  New - Save as dds - as requested - helpful when image has alpha or this program doesnt display it correctly eg with lightmaps
  New dds decoder - stops jagged images
  Added - save all text
  New XP Icons and some changed
}


unit MainForm;

interface

uses
  Windows, SysUtils, Forms, Variants, Classes, ImgList, Controls, Dialogs,
  Menus, XPMan, ExtCtrls, StdCtrls, ComCtrls, CommCtrl, Graphics, Consts, Jpeg,

  JvMenus, JvBaseDlg, JvBrowseFolder, JvExControls, JvSpeedButton, JvExStdCtrls,
  JvRichEdit, JvExExtCtrls, JvExtComponent, JvPanel,

  JclStrings, Jclfileutils, JclSysInfo, JclShell,
  GR32_Image, GR32, GR32_Resamplers,
  PngImage,
  VirtualTrees,
  PsychoBaseDumper, PsychoTypes;

type
  TMainfrm = class(TForm)
    OpenDialog1: TOpenDialog;
    XPManifest1: TXPManifest;
    dlgBrowseForFolder: TJvBrowseForFolderDialog;
    ProgressBar1: TProgressBar;
    Tree: TVirtualStringTree;
    pnlBottom: TJvPanel;
    pnlContainer: TPanel;
    PopupFilter: TPopupMenu;
    mnuFilterCubic: TMenuItem;
    mnuFilterSpline: TMenuItem;
    mnuFilterLanczos3: TMenuItem;
    mnuFilterMitchell: TMenuItem;
    PopupResize: TPopupMenu;
    mnuFilterHermite: TMenuItem;
    mnuResize50: TMenuItem;
    mnuResize125: TMenuItem;
    mnuResize150: TMenuItem;
    mnuResize175: TMenuItem;
    mnuResize200: TMenuItem;
    mnuResize640x480: TMenuItem;
    mnuResize800x600: TMenuItem;
    mnuResize1024x768: TMenuItem;
    mnuResize1280x1024: TMenuItem;
    mnuResize1600x1200: TMenuItem;
    mnuResizeNo: TMenuItem;
    PopupImageType: TPopupMenu;
    mnuBitmap: TMenuItem;
    mnuJpeg: TMenuItem;
    mnuPng: TMenuItem;
    pnlImage: TPanel;
    pnlOpenDump: TPanel;
    btnDumpAll: TJvSpeedButton;
    btnOpen: TJvSpeedButton;
    btnDumpSingle: TJvSpeedButton;
    btnFilterByType: TJvSpeedButton;
    btnResize: TJvSpeedButton;
    btnResample: TJvSpeedButton;
    btnSaveImage: TJvSpeedButton;
    pnlText: TPanel;
    memoText: TMemo;
    pnlAudio: TPanel;
    btnSaveText: TJvSpeedButton;
    btnSaveAllImages: TJvSpeedButton;
    btnSaveAllAudio: TJvSpeedButton;
    pnlNone: TPanel;
    Image2: TImage;
    btnSaveSingleAudio: TJvSpeedButton;
    btnSearch: TJvSpeedButton;
    PopupFileTypes: TJvPopupMenu;
    SaveDialog1: TSaveDialog;
    MemoLog: TJvRichEdit;
    Image1: TImage32;
    mnuDDS: TMenuItem;
    btnSaveAllText: TJvSpeedButton;
    ImageList1: TImageList;
    procedure MemoLogURLClick(Sender: TObject; const URLText: string;
      Button: TMouseButton);
    procedure btnSearchClick(Sender: TObject);
    procedure btnSaveSingleAudioClick(Sender: TObject);
    procedure btnSaveAllAudioClick(Sender: TObject);
    procedure btnSaveAllImagesMouseEnter(Sender: TObject);
    procedure btnSaveImageMouseEnter(Sender: TObject);
    procedure btnSaveTextClick(Sender: TObject);
    procedure TreeChange(Sender: TBaseVirtualTree;
      Node: PVirtualNode);
    procedure btnDumpSingleClick(Sender: TObject);
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure btnDumpAllClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TreeGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure TreeGetText(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: WideString);
    procedure FormCreate(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure ResizeMenuHandler(Sender: TObject);
    procedure FilterMenuHandler(Sender: TObject);
    procedure FileTypeMenuHandler(Sender: TObject);
    procedure SaveImageMenuHandler(Sender: TObject);
    procedure TreeHeaderClick(Sender: TVTHeader; Column: TColumnIndex;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure btnSaveAllTextClick(Sender: TObject);
  private
    function  GetImageResizeValues(SourceWidth, SourceHeight: integer; var NewWidth, NewHeight: integer): boolean;
    procedure DoLog(logitem: string);
    procedure DoButtons(Value: boolean);
    procedure DoImageControls(Value: boolean);
    procedure FreeResources;
    procedure OnProgress(ProgressMax: integer; ProgressPos: integer);
    procedure OnDebug(DebugText: string);
    procedure FilterNodes(FileExt: string);
    procedure OnDoneLoading(RootNodeCount: integer);
    procedure AddFileTypePopups;
    procedure ViewAll;
    procedure UpdateAllFilesView;
    procedure SaveImage(DestFolder, FileName: string; FileNo: integer; SourceBmp: tbitmap32); overload;
    procedure SaveImage(DestFolder, FileName: string; FileNo: integer; SourceBmp: tbitmap32; NewWidth, NewHeight: integer); overload;
    procedure SaveSingleImage;
    procedure SaveAllImages;
    procedure SaveBundleInfoToFile;
    procedure ConvertTo32BitImageList(const ImageList: TImageList);
    procedure LoadAllIconsFromrc;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Mainfrm: TMainfrm;
  ShowLog: boolean;
  Dumper: TPsychoBaseDumper;
  MyPopUpItems: array of TMenuItem;
  FileTypes: tstringlist;

const
  TextTypes: array [0..7] of string=(
  '.H',
  '.INI',
  '.ASD',
  '.ATX',
  '.DFS',
  '.HLPS',
  '.PSH',
  '.VSH'
  );

  AudioTypes: array [0..5] of string=(
  '.AIF',
  '.AIF-LOOP',
  '.WAV',
  '.AIFF',
  '.AIFF-LOOP',
  '.CDDA'
  );

implementation

uses SearchForm;

{$R *.dfm}
{$R extras.res}

procedure TMainfrm.DoLog(logitem: string);
begin
  MemoLog.Lines.Add(LogItem);
end;

procedure TMainfrm.DoButtons(Value: boolean);
begin
  searchfrm.close;
  btnOpen.Enabled:=value;
  btnDumpAll.Enabled:=value;
  btnDumpSingle.Enabled:=value;
  btnFilterByType.Enabled:=value;
  btnSaveText.Enabled:=value;
  btnSaveAllText.Enabled:=value;
  btnSaveSingleAudio.Enabled:=value;
  btnSaveAllAudio.Enabled:=value;
  tree.Enabled:=value;
  btnSearch.Enabled:=value;
end;

procedure TMainfrm.DoImageControls(Value: boolean);
begin
  if value=true then
  begin
    if tree.FocusedNode=nil then
    begin
      btnResample.Enabled:=false;
      btnSaveImage.Enabled:=false;
      btnSaveAllImages.Enabled:=false;
      btnResize.Enabled:=false;
    end
    else
    if (Uppercase(extractfileext(dumper.FileNamesArray[Tree.focusednode.Index])) = '.DDS')
    or (UpperCase(extractfileext(dumper.FileNamesArray[Tree.focusednode.Index])) = '.TGA')
    {or (UpperCase(extractfileext(dumper.FileNamesArray[Tree.focusednode.Index])) = '.PS2')} then  //is an image
    begin
      btnSaveImage.Enabled:=true;
      btnSaveAllImages.Enabled:=true;
      btnResize.Enabled:=true;

      if popupResize.Items[0].Checked then
        btnResample.Enabled:=false
      else
        btnResample.Enabled:=true;
    end
    else
    begin
      btnSaveImage.Enabled:=false;
      btnSaveAllImages.Enabled:=false;
      btnResize.Enabled:=false;
      btnResample.Enabled:=false;
    end;

  end
  else
  if value=false then
  begin
    btnResample.Enabled:=false;
    btnSaveImage.Enabled:=false;
    btnSaveAllImages.Enabled:=false;
    btnResize.Enabled:=false;
  end;
end;

procedure TMainfrm.OnProgress(ProgressMax: integer; ProgressPos: integer);
begin
  Progressbar1.max:=ProgressMax;
  Progressbar1.Position:=progresspos;
end;

procedure TMainfrm.OnDebug(DebugText: string);
begin
  DoLog(DebugText);
end;

procedure TMainfrm.TreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: WideString);
begin
  case Column of
   -1,0: Celltext := dumper.FileNamesArray[node.index];
    1: Celltext := inttostr(Dumper.FileSizesArray[Node.Index]);
    2: Celltext := inttostr(Dumper.OffsetsArray[Node.Index]);
  end;
end;

procedure TMainfrm.TreeHeaderClick(Sender: TVTHeader; Column: TColumnIndex;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Column = 0 then
  begin
    Tree.Header.SortColumn:=Column;

    if Tree.Header.SortDirection = sdAscending then
      Tree.Header.SortDirection := sdDescending
    else
      Tree.Header.SortDirection := sdAscending;

    //Tree.Header.Columns[Tree.Header.SortColumn].Color := $F7F7F7;
    Tree.SortTree(Tree.Header.SortColumn, Tree.Header.SortDirection, False);
  end;  
end;

procedure TMainfrm.TreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := 0;
end;

procedure TMainfrm.TreeGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  ext: string;
begin
  ext:=Uppercase(extractfileext(dumper.FileNamesArray[node.index]));
  if column=0 then
  begin
    if (ext='.DDS') or (ext='.TGA') or (ext='.PS2') then
      ImageIndex:=1
    else
    if (ext='.H') or (ext='.ASD') or (ext='.ATX') or (ext='.DFS') or (ext='.HLPS') or (ext='.PSH') or (ext='.VSH') then
      ImageIndex:=2
    else
    if ext='.INI' then
      ImageIndex:=3
    else
    if strindex(ext, AudioTypes)>-1 then //(ext='.AIF') or (ext='.AIF-LOOP') or (ext='.WAV') or (ext='.AIFF') or (ext='.AIFF-LOOP') then
      ImageIndex:=4
    else
    if (ext='.LUA') or (ext='.LPF') then
      ImageIndex:=5
    else
    if (ext='.PLB') or (ext='.PL2') then
      ImageIndex:=7
    else
    if ext='.CAM' then
      ImageIndex:=8
    else
    if ext='.EVE' then
      ImageIndex:=9
    else
    if ext='.JAN' then
      ImageIndex:=10
    else
    if ext='.PBA' then
      ImageIndex:=11
    else
      ImageIndex:=0;
  end;
end;

procedure TMainfrm.TreeChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  Ext: string;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;
  ext:=uppercase(extractfileext(dumper.FileNamesArray[Tree.focusednode.Index]));

  if (ext='.DDS') or (ext='.TGA') {or (ext='.PS2')} then
  begin
    //if extractfileext(opendialog1.FileName)='.ppf' then exit;
    DoImageControls(true);
    pnlText.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlImage.Align:=alClient;
    pnlImage.BringToFront;
    Dumper.DrawDDSImage(dumper.OffsetsArray[Tree.focusednode.Index], dumper.FileSizesArray[Tree.focusednode.Index], image1.Bitmap, Dumper.FileNamesArray[Tree.focusednode.Index]);
  end
  {else
  if ext='.PS2' then
  begin
    DoImageControls(true);
    pnlText.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlImage.Align:=alClient;
    pnlImage.BringToFront;
  end}
  else
  if strindex(Ext, TextTypes)>-1 then//(ext='.H') or (ext='.INI') or (ext='.ASD') or (ext='.ATX') or (ext='.DFS') or (ext='.HLPS') or (ext='.PSH') or (ext='.VSH') then
  begin
    btnSaveText.Enabled:=true;
    memotext.Enabled:=true;
    image1.Bitmap:=nil;
    pnlImage.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlText.Align:=alClient;
    pnltext.BringToFront;
    memoText.Clear;
    Dumper.ExtractText(dumper.OffsetsArray[Tree.focusednode.Index], dumper.FileSizesArray[Tree.focusednode.Index], memotext.Lines);
  end
  else
  if strindex(Ext, AudioTypes)>-1 then //(ext='.AIF') or (ext='.AIF-LOOP') or (ext='.WAV') or (ext='.AIFF') or (ext='.AIFF-LOOP') then
  begin
    btnSaveSingleAudio.Enabled:=true;
    image1.Bitmap:=nil;
    pnlText.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlImage.Align:=alnone;
    pnlAudio.Align:=alClient;
    pnlAudio.BringToFront;
  end
  else
  begin
    image1.Bitmap:=nil;
    memoText.Clear;
    //show the blank panel
    pnlText.Align:=alNone;
    pnlImage.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlNone.Align:=alClient;
    pnlNone.BringToFront;
  end;
end;

procedure TMainfrm.FreeResources;
var
  i: integer;
begin
  tree.Clear;

  //if invalid files are opened twice in succession then none of the resources below
  //are created so need to check if they are nil
  if dumper <> nil then
    freeandnil(dumper);

  if filetypes <> nil then
    freeandnil(filetypes);

  if MyPopUpItems <> nil then
  begin
    for i:=low(mypopupitems) to high(mypopupitems) do
      mypopupitems[i].Free;

    MyPopUpItems:=nil;
  end;
end;

procedure TMainfrm.ConvertTo32BitImageList(const ImageList: TImageList);
const
  Mask: array[Boolean] of Longint = (0, ILC_MASK);
var
  TemporyImageList: TImageList;
begin
  if Assigned(ImageList) then
  begin
    TemporyImageList := TImageList.Create(nil);
    try
      TemporyImageList.Assign(ImageList);
      with ImageList do
      begin
        ImageList.Handle := ImageList_Create(Width, Height, ILC_COLOR32 or Mask[Masked], 0, AllocBy);
        if not ImageList.HandleAllocated then
        begin
          raise EInvalidOperation.Create(SInvalidImageList);
        end;
      end;
      ImageList.AddImages(TemporyImageList);
    finally
      TemporyImageList.Free;
    end;
  end;
end;

procedure TMainfrm.LoadAllIconsFromrc;
const
  ResNames: array [0..11] of string =
  ('REDDOT', 'IMAGE', 'TEXT', 'INI', 'AUDIO', 'LUA', 'VIEWALL',
   'RAZPLB', 'CAM', 'TAGRED', 'TAGTARTAN', 'TAGBLUE');
var
  Stream: TResourceStream;
  icon1: ticon;
  i: integer;
begin
  for I := 0 to high(ResNames)  do
  begin
    Stream := TResourceStream.Create(hInstance, ResNames[i], 'Data');
    try
      icon1:=ticon.create;
      try
        icon1.LoadFromStream(Stream);
        Mainfrm.ImageList1.AddIcon(Icon1);
      finally
        Icon1.Free;
      end;
    finally
      Stream.free;
    end;
  end;
end;

procedure TMainfrm.FormCreate(Sender: TObject);
begin
  dlgBrowseforfolder.RootDirectory:=fdDesktopDirectory;
  dlgBrowseforfolder.RootDirectoryPath:=GetDesktopDirectoryFolder;
  opendialog1.InitialDir:=getprogramfilesfolder + '\Double Fine Productions\Psychonauts\';
  SaveDialog1.InitialDir:=GetDesktopDirectoryFolder;

  ConvertTo32BitImageList(ImageList1);
  LoadAllIconsFromRC;
end;

procedure TMainfrm.FormDestroy(Sender: TObject);
begin
  FreeResources;
end;

procedure TMainfrm.btnOpenClick(Sender: TObject);
begin
  if OpenDialog1.Execute then
  begin
    FreeResources;
    try
      Dumper:=tpsychoBasedumper.Create(opendialog1.FileName, OnDebug);
      try
        DoButtons(false);
        memoText.Clear;
        searchfrm.searchtree.Clear;
        image1.Bitmap:=nil;
        pnlNone.Align:=alClient;
        pnlNone.BringToFront;
        //Dumper.OnDebug:=OnDebug;
        Dumper.OnProgress:=OnProgress;
        Dumper.OnDoneLoading:=OnDoneLoading;
        memoLog.clear;
        Tree.Clear;
        DoLog('Opened file "' + opendialog1.filename + '"');
        Dumper.ParseFiles;
        Tree.Header.AutoFitColumns(true);
        btnFilterByType.Enabled:=true;
        AddFileTypePopups;
        btnFilterByType.Caption:='View: ' + PopupFileTypes.Items[0].caption; //Needs to be reset each time a file is opened

      finally
        DoButtons(true);
        UpdateAllFilesView;
      end;
    except on E: EInvalidFile do
      DoLog(E.Message);
    end;
  end
  else

end;

procedure TMainfrm.btnDumpAllClick(Sender: TObject);
begin
  if Tree.RootNodeCount=0 then exit;
  if dlgBrowseforFolder.Execute then
  begin

  end
  else
  begin
    DoLog('No Save folder chosen, aborting.');
    exit;
  end;

  DoButtons(false);
  DoImageControls(false);
  DoLog('Dumping all files...');
  try
    Dumper.SaveFiles(dlgBrowseForFolder.Directory);
  finally
    DoButtons(true);
    DoImageControls(true);
    DoLog('All done!');
    Progressbar1.Position:=0;
  end;

end;

procedure TMainfrm.btnDumpSingleClick(Sender: TObject);
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.FileName:=extractfilename(dumper.FileNamesArray[Tree.focusednode.Index]);
  if SaveDialog1.Execute then
  begin

  end
  else
  begin
    DoLog('Save cancelled, aborting.');
    exit;
  end;

  DoButtons(false);
  DoImageControls(false);
  try
    Dumper.SaveFile(Tree.focusednode.Index, ExtractFilePath(SaveDialog1.FileName), extractfilename(SaveDialog1.FileName));
  finally
    DoButtons(true);
    DoImageControls(true);
    DoLog('Done!');
    Progressbar1.Position:=0;
  end;
end;

procedure TMainfrm.SaveImage(DestFolder, FileName: string; FileNo: integer; SourceBmp: tbitmap32);
var
  Target: TJPEGImage;
  png: tpngobject;
  DestBmp: tbitmap;
begin
  if popupImageType.Items[1].Checked then //jpeg
  begin
    Target:=TJPEGImage.Create;
    DestBmp:=tbitmap.Create;
    try
      DestBmp.Assign(SourceBmp);
      target.Assign(DestBmp);
      target.SaveToFile(DestFolder + '\' + FileName);
    finally
      target.Free;
      DestBmp.Free;
    end;
  end
  else
  if popupImageType.Items[2].Checked then //png
  begin
    png:=TPngObject.Create;
    DestBmp:=tbitmap.Create;
    try
      DestBmp.Assign(SourceBmp);
      png.Assign(DestBmp);
      png.SaveToFile(DestFolder + '\' + FileName);
    finally
      png.Free;
      DestBmp.Free;
    end;
  end
  else
    SourceBmp.SaveToFile(DestFolder + '\' + FileName); //bmp
end;

procedure TMainfrm.SaveImage(DestFolder, FileName: string; FileNo: integer; SourceBmp: tbitmap32; NewWidth, NewHeight: integer);
var
  i, Index: integer;
  Jpeg: TJPEGImage;
  Png: tpngobject;
  R: TKernelResampler;
  K: TCustomKernel;
  DestBmp: TBitmap32;
  TempBmp: TBitmap;
begin
  //Get Filter
  Index:=-1;
  for i:=0 to popupFilter.Items.Count -1 do
    if popupFilter.Items[i].Checked then Index:=i;


  case Index of
   -1: K:=THermiteKernel.Create;
    0: K:=THermiteKernel.Create;
    1: K:=TCubicKernel.Create;
    2: K:=TSplineKernel.Create;
    3: K:=TLanczosKernel.Create;
    4: K:=TMitchellKernel.Create;
    else
      K:=THermiteKernel.Create;
  end;

  //Resize and resample
  DestBmp:=tbitmap32.Create;
  try
    R := TKernelResampler.Create(SourceBmp);
    R.Kernel := K;
    DestBmp.Width:=NewWidth;
    DestBmp.Height:=NewHeight;
    DestBmp.Draw(DestBmp.BoundsRect, SourceBmp.BoundsRect, SourceBmp);

    //Save the image
    if popupImageType.Items[1].Checked then //jpeg
    begin
      JPEG:=TJPEGImage.Create;
      TempBmp:=tbitmap.Create;
      try
        TempBmp.Assign(DestBmp);
        JPEG.Assign(TempBmp);
        JPEG.SaveToFile(DestFolder + '\' + FileName);
      finally
        JPEG.Free;
        TempBmp.Free;
      end;
    end
    else
    if popupImageType.Items[2].Checked then //png
    begin
      png:=TPngObject.Create;
      TempBmp:=tbitmap.Create;
      try
        TempBmp.Assign(DestBmp);
        png.Assign(TempBmp);
        png.SaveToFile(DestFolder + '\' + FileName);
      finally
        png.Free;
        TempBmp.Free;
      end;
    end
    else
      DestBmp.SaveToFile(DestFolder + '\' + FileName); //bmp
  finally
    DestBmp.Free;
  end;
end;

procedure TMainfrm.FilterNodes(FileExt: string);
var
  i: integer;
  prevnode, tempnode: pvirtualnode;
begin
  if Tree.RootNodeCount=0 then exit;

  Tree.BeginUpdate;
  try
    prevnode:=Tree.GetFirst;
    if extractfileext(dumper.FileNamesArray[prevnode.Index])=FileExt then
      Tree.IsVisible[prevnode]:=true
    else
      Tree.IsVisible[prevnode]:=false;
    for i:=0 to Tree.RootNodeCount -2 do
    begin
      if extractfileext(dumper.FileNamesArray[prevnode.index + 1])=FileExt then
        Tree.IsVisible[Tree.GetNext(prevnode)]:=true
      else
        Tree.IsVisible[Tree.GetNext(prevnode)]:=false;
      tempnode:=Tree.GetNext(prevnode);
      prevnode:=tempnode;
    end;
    Tree.Selected [Tree.focusednode]:=false;
    image1.Bitmap:=nil;
    DoImageControls(false);
  finally
    Tree.EndUpdate;
  end;
end;

procedure TMainfrm.ViewAll;
var
  i: integer;
  prevnode, tempnode: pvirtualnode;
begin
  if Tree.RootNodeCount=0 then exit;

  Tree.BeginUpdate;
  try
    prevnode:=Tree.GetFirst;
    Tree.IsVisible[prevnode]:=true;
    for i:=0 to Tree.RootNodeCount -2 do
    begin
      Tree.IsVisible[Tree.GetNext(prevnode)]:=true;
      tempnode:=Tree.GetNext(prevnode);
      prevnode:=tempnode;
    end;
    Tree.Selected [Tree.focusednode]:=false;
    image1.Bitmap:=nil;
    DoImageControls(false);
  finally
    Tree.EndUpdate;
  end;

end;

procedure TMainfrm.AddFileTypePopups;
var
  i: integer;
  temp: string;
begin
  Filetypes:=tstringlist.Create;
  for i:=0 to tree.RootNodeCount -1 do
  begin
    temp:=copy(extractfileext(dumper.FileNamesArray[i]), 1, length(extractfileext(dumper.FileNamesArray[i])));
    if (FileTypes.IndexOf(temp)=-1) and (temp > '' ) then
      FileTypes.Add(temp);
  end;
  FileTypes.Sort;

  setlength(MyPopupItems, Filetypes.Count + 1);
  for i:=low(mypopupitems) to high(mypopupitems)-1 do
  begin
    MyPopUpItems[i]:=TMenuItem.Create(Self);
    MyPopUpItems[i].Caption:=FileTypes[i];
    MyPopUpItems[i].tag:=i + 1;
    PopupFileTypes.Items.add(MyPopupItems[i]);
    MyPopUpItems[i].OnClick:=FileTypeMenuHandler;

    //icons
    if (UpperCase(FileTypes[i])='.DDS') or (UpperCase(FileTypes[i])='.TGA')
    or (UpperCase(FileTypes[i])='.PS2') then MyPopUpItems[i].ImageIndex:=1
    else
    if UpperCase(FileTypes[i])='.INI' then MyPopUpItems[i].ImageIndex:=3
    else
    if strindex(UpperCase(FileTypes[i]), TextTypes)>-1 then MyPopUpItems[i].ImageIndex:=2
    else
    if strindex(UpperCase(FileTypes[i]), AudioTypes)>-1 then MyPopUpItems[i].ImageIndex:=4
    else
    if (UpperCase(FileTypes[i])='.LUA') or (UpperCase(FileTypes[i])='.LPF') then MyPopUpItems[i].ImageIndex:=5
    else
    if (UpperCase(FileTypes[i])='.PLB') or (UpperCase(FileTypes[i])='.PL2') then MyPopUpItems[i].ImageIndex:=7
    else
    if UpperCase(FileTypes[i])='.CAM' then MyPopUpItems[i].ImageIndex:=8
    else
    if UpperCase(FileTypes[i])='.EVE' then MyPopUpItems[i].ImageIndex:=9
    else
    if UpperCase(FileTypes[i])='.JAN' then MyPopUpItems[i].ImageIndex:=10
    else
    if UpperCase(FileTypes[i])='.PBA' then MyPopUpItems[i].ImageIndex:=11
    else MyPopUpItems[i].ImageIndex:=0;
  end;

  //Add 'all files' menu item
  i:=high(mypopupitems);
  MyPopUpItems[i]:=TMenuItem.Create(Self);
  MyPopUpItems[i].Caption:='All Files';
  MyPopUpItems[i].tag:=0;
  MyPopUpItems[i].Checked:=true;
  MyPopUpItems[i].ImageIndex:=6;
  popupFileTypes.Items.Insert(0, MyPopUpItems[i]);
  MyPopUpItems[i].OnClick:=FileTypeMenuHandler;
end;

{Popup Menu Handlers}
procedure TMainfrm.FilterMenuHandler(Sender: TObject);
var
  i: Integer;
begin
  for i:=0 to popupFilter.Items.Count -1 do
    popupFilter.Items[i].Checked:=false;

  with sender as tmenuitem do
  begin
    btnResample.Caption:='Resampling Filter: ' + caption;
    Checked:=true;
  end;
end;

procedure TMainfrm.SaveImageMenuHandler(Sender: TObject);
var
  i: Integer;
begin
  for i:=0 to popupImageType.Items.Count -1 do
    popupImageType.Items[i].Checked:=false;

  with sender as tmenuitem do
  begin
    Checked:=true;
  end;

  DoButtons(false);
  DoImageControls(false);
  try
    if popupImageType.Tag=0 then //Save single is sender
      SaveSingleImage
    else
      SaveAllImages; //Save all is sender
  finally
    DoButtons(true);
    DoImageControls(true);
  end;
end;

procedure TMainfrm.ResizeMenuHandler(Sender: TObject);
var
  i: Integer;
begin
  for i:=0 to popupResize.Items.Count -1 do
    popupResize.Items[i].Checked:=false;

  with sender as tmenuitem do
  begin
    if name='mnuResizeNo' then
    begin
      btnResample.Enabled:=false;
      mnuDDS.Enabled:=true;
    end
    else
    begin
      btnResample.Enabled:=true;
      mnuDDS.Enabled:=false;
    end;
    Checked:=true;
    btnResize.Caption:='Resize Image: ' + Caption;
  end;
end;

procedure TMainfrm.FileTypeMenuHandler(Sender: TObject);
var
  i: Integer;
  ext: string;
begin
  if Tree.RootNodeCount=0 then exit;

  image1.Bitmap:=nil;
  memoText.Clear;
  pnlNone.Align:=alClient;
  pnlNone.BringToFront;

  with Sender as TMenuItem do
  begin
    ext:=caption;
    StrReplace(ext, '&', '',[rfIgnoreCase, rfReplaceAll]);

    if ext='All Files' then
    begin
      btnFilterByType.Caption:='View: ' + ext;
      ViewAll;
    end
    else
    begin
      FilterNodes(ext);
      btnFilterByType.Caption:='View: ' + ext + ' Files';
     end;
  end;

  for I := 0 to popupFileTypes.Items.Count -1 do
  begin
    popupFileTypes.Items[i].Checked:=false;
  end;

  with Sender as TMenuItem do
  begin
    popupFileTypes.Items[tag].Checked:=true;
    ext:=UpperCase(caption);
    StrReplace(ext, '&', '',[rfIgnoreCase, rfReplaceAll]);
  end;

  if ext='ALL FILES' then
  begin
    UpdateAllFilesView;
    exit;
  end;

  if (ext='.DDS') or (ext='.TGA') or (ext='.PS2') then
  begin
    btnSaveAllImages.Enabled:=true;
    btnResize.Enabled:=true;
    if popupResize.Items[0].Checked then
      btnResample.Enabled:=false
    else
      btnResample.Enabled:=true;
    pnlText.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlImage.Align:=alClient;
    pnlImage.BringToFront;
  end
  {else
  if ext='.PS2' then
  begin
    btnSaveAllImages.Enabled:=true;
    btnResize.Enabled:=true;
    if popupResize.Items[0].Checked then
      btnResample.Enabled:=false
    else
      btnResample.Enabled:=true;
    pnlText.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlImage.Align:=alClient;
    pnlImage.BringToFront;
  end}
  else
  if strindex(Ext, TextTypes)>-1 then //(ext='.H') or (ext='.INI') or (ext='.ASD') or (ext='.ATX') or (ext='.DFS') or (ext='.HLPS') or (ext='.PSH') or (ext='.VSH') then
  begin
    btnSaveText.Enabled:=false;
    memoText.Enabled:=false;
    image1.Bitmap:=nil;
    pnlImage.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlText.Align:=alClient;
    pnltext.BringToFront;
    memoText.Clear;
  end
  else
  if strindex(Ext, AudioTypes)>-1 then //(ext='.AIF') or (ext='.AIF-LOOP') or (ext='.WAV') or (ext='.AIFF') or (ext='.AIFF-LOOP') then
  begin
    btnSaveSingleAudio.Enabled:=false;
    image1.Bitmap:=nil;
    pnlText.Align:=alNone;
    pnlNone.Align:=alNone;
    pnlImage.Align:=alnone;
    pnlAudio.Align:=alClient;
    pnlAudio.BringToFront;
  end
  else
  begin
    image1.Bitmap:=nil;
    memoText.Clear;
    //show the blank panel
    pnlText.Align:=alNone;
    pnlImage.Align:=alNone;
    pnlAudio.Align:=alnone;
    pnlNone.Align:=alClient;
    pnlNone.BringToFront;
  end;

end;


procedure TMainfrm.btnSaveTextClick(Sender: TObject);
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  SaveDialog1.FileName:=pathextractfilenamenoext(dumper.FileNamesArray[Tree.focusednode.Index]) + '.txt';
  SaveDialog1.DefaultExt:='.txt';
  SaveDialog1.Filter:='Txt files' + '|' + '*.txt';
  if SaveDialog1.Execute then
  begin

  end
  else
  begin
    DoLog('Save cancelled, aborting.');
    SaveDialog1.DefaultExt:='';
    SaveDialog1.Filter:='All Files|*.*';
    exit;
  end;

  DoButtons(false);
  try
    memoText.Lines.SaveToFile(ExtractFilePath(SaveDialog1.FileName) + '\' + extractfilename(SaveDialog1.FileName));
    DoLog('Saved ' + extractfilename(savedialog1.filename));
  finally
    DoButtons(true);
    SaveDialog1.DefaultExt:='';
    SaveDialog1.Filter:='All Files|*.*';
  end;

end;

procedure TMainfrm.btnSaveAllTextClick(Sender: TObject);
var
  i: integer;
  temp, prevnode: pvirtualnode;
  CurrExt: string;
  TempText: tstringlist;
begin
  if Tree.RootNodeCount=0 then exit;
//  if Tree.SelectedCount=0 then exit;

  if dlgBrowseforFolder.Execute then
  begin

  end
  else
  begin
    DoLog('No Save folder chosen, aborting.');
    exit;
  end;

  DoLog('Saving all as text files...');
  DoButtons(false);
  try
    progressbar1.Max:=tree.VisibleCount;
    temp:=tree.getfirstvisible;
    for i:=0 to tree.VisibleCount -1 do
    begin
      CurrExt:=UpperCase(extractfileext(dumper.FileNamesArray[Temp.Index]));
      if strindex(CurrExt, TextTypes)>-1 then
      begin
        TempText:=tstringlist.Create;
        try
          Dumper.ExtractText(dumper.OffsetsArray[Temp.Index], dumper.FileSizesArray[Temp.Index], TempText);
          TempText.SaveToFile(dlgBrowseForFolder.Directory + '\' + pathextractfilenamenoext(dumper.FileNamesArray[Temp.Index]) + '.txt');
        finally
          TempText.Free;
        end;
      end;
      prevnode:=temp;
      temp:=tree.GetNextVisible(prevnode);
      progressbar1.Position:=i;
      application.ProcessMessages;
    end;

  finally
    DoButtons(true);
    DoLog('All done!');
    progressbar1.Position:=0;
  end;
end;

procedure TMainfrm.btnSaveImageMouseEnter(Sender: TObject);
begin
  popupImageType.Tag:=0;
end;

procedure TMainfrm.btnSaveAllImagesMouseEnter(Sender: TObject);
begin
  popupImageType.Tag:=1;
end;

function TMainfrm.GetImageResizeValues(SourceWidth, SourceHeight: integer; var NewWidth, NewHeight: integer): boolean;
var
  i, Index: integer;
begin
  {Function returns false if theres no resize}

  Index:=-1;
  for i:=0 to popupResize.Items.Count -1 do
    if popupResize.Items[i].Checked then index:=i;

  case index of
   -1: begin
        NewWidth:=SourceWidth;
        NewHeight:=SourceHeight;
        result:=false;
       end;
    0: begin
        NewWidth:=SourceWidth;
        NewHeight:=SourceHeight;
        result:=false;
       end;
    1: begin
        NewWidth:=SourceWidth div 2; //50%
        NewHeight:=SourceHeight div 2;
        result:=true;
       end;
    2: begin
        NewWidth:=(SourceWidth div 4) + SourceWidth;//125%
        NewHeight:=(SourceHeight div 4) + SourceHeight;
        result:=true;
       end;
    3: begin
        NewWidth:=(SourceWidth div 2) + SourceWidth;//150%
        NewHeight:=(SourceHeight div 2) + SourceHeight;
        result:=true;
       end;
    4: begin
        NewWidth:=(SourceWidth div 4) * 3 + SourceWidth;//175%
        NewHeight:=(SourceHeight div 4) * 3 + SourceHeight;
        result:=true;
       end;
    5: begin
        NewWidth:=SourceWidth * 2;//200%
        NewHeight:=SourceHeight * 2;
        result:=true;
       end;
    6: begin
        NewWidth:=640;//640x480
        NewHeight:=480;
        result:=true;
       end;
    7: begin
        NewWidth:=800;//800x600
        NewHeight:=600;
        result:=true;
       end;
    8: begin
        NewWidth:=1024;//1024x768
        NewHeight:=768;
        result:=true;
       end;
    9: begin
        NewWidth:=1280;//1280x1024
        NewHeight:=1024;
        result:=true;
       end;
   10: begin
        NewWidth:=1600;//1600x1200
        NewHeight:=1200;
        result:=true;
       end;
   else
    result:=false;
  end;

end;

procedure TMainfrm.SaveAllImages;
var
  i, NewWidth, NewHeight: integer;
  temp, prevnode: pvirtualnode;
  tempbmp: tbitmap32;
  ext: string;
begin
  if dlgBrowseforFolder.Execute then
  begin

  end
  else
  begin
    DoLog('No Save folder chosen, aborting.');
    exit;
  end;

  DoLog('Dumping all image files - any existing files with the same name will be replaced.');
  progressbar1.Max:=tree.VisibleCount;

  if popupImageType.Items[1].Checked then
    ext:='.jpg'
  else
  if popupImageType.Items[2].Checked then
    ext:='.png'
  else
  if popupImageType.Items[3].Checked then
    ext:='.dds'
  else
    ext:='.bmp';

  tempbmp:=tbitmap32.Create;
  try
    temp:=tree.getfirstvisible;
    for i:=0 to tree.VisibleCount -1 do
    begin
      if (UpperCase(extractfileext(dumper.FileNamesArray[Temp.Index]))='.DDS')
      or (UpperCase(extractfileext(dumper.FileNamesArray[Temp.Index]))='.TGA')
      {or (UpperCase(extractfileext(dumper.FileNamesArray[Temp.Index]))='.PS2')} then
      begin
        if Ext='.dds' then
        begin
          Dumper.SaveDDSFile(Temp.Index, dlgbrowseforfolder.Directory, pathextractfilenamenoext(dumper.FileNamesArray[Temp.Index]) + ext);
        end
        else
        begin
          Dumper.DrawDDSImage(dumper.OffsetsArray[temp.Index], dumper.FileSizesArray[temp.Index], tempbmp, Dumper.FileNamesArray[Temp.Index]);

          if GetImageResizeValues(TempBmp.Width, TempBmp.Height, NewWidth, NewHeight)=true then
            SaveImage(dlgbrowseforfolder.Directory, pathextractfilenamenoext(dumper.FileNamesArray[Temp.Index]) + ext, temp.index, tempbmp, NewWidth, NewHeight)
          else
            SaveImage(dlgbrowseforfolder.Directory, pathextractfilenamenoext(dumper.FileNamesArray[Temp.Index]) + ext, temp.index, tempbmp);
        end;
      end;
      prevnode:=temp;
      temp:=tree.GetNextVisible(prevnode);
      progressbar1.Position:=i;
      application.ProcessMessages;
    end;
  finally
    tempbmp.Free;
    DoLog('All done!');
    progressbar1.Position:=0;
  end;
end;

procedure TMainfrm.SaveSingleImage;
var
  ext: string;
  tempbmp: tbitmap32;
  NewWidth, NewHeight: integer;
begin
  if Image1.Bitmap = nil then exit;

  if popupImageType.Items[1].Checked then
    ext:='.jpg'
  else
  if popupImageType.Items[2].Checked then
    ext:='.png'
  else
  if popupImageType.Items[3].Checked then
    ext:='.dds'
  else
    ext:='.bmp';

  SaveDialog1.FileName:=pathextractfilenamenoext(dumper.FileNamesArray[Tree.focusednode.Index]) + ext;
  SaveDialog1.DefaultExt:=ext;
  SaveDialog1.Filter:=ext + ' files' + '|' + '*' + ext;
  if SaveDialog1.Execute then
  begin

  end
  else
  begin
    DoLog('Save cancelled, aborting.');
    SaveDialog1.DefaultExt:='';
    SaveDialog1.Filter:='All Files|*.*';
    exit;
  end;

  DoLog('Saving image '  + extractfilename(SaveDialog1.FileName) + '...');
  if Ext='.dds' then
  begin
    DoLog('Saving DDS file ' + extractfilename(SaveDialog1.FileName)); //cant put this in SaveDDSFile because saveallimages uses that too and it means that it logs every dumped file
    Dumper.SaveDDSFile(Tree.focusednode.Index, ExtractFilePath(SaveDialog1.FileName), extractfilename(SaveDialog1.FileName));
  end
  else
  begin
    if GetImageResizeValues(Image1.bitmap.Width, Image1.bitmap.Height, NewWidth, NewHeight)=true then
    begin
      tempbmp:=tbitmap32.Create;
      try
        Dumper.DrawDDSImage(dumper.OffsetsArray[Tree.focusednode.Index], dumper.FileSizesArray[Tree.focusednode.Index], tempbmp, Dumper.FileNamesArray[Tree.focusednode.Index]);
        SaveImage(ExtractFilePath(SaveDialog1.FileName), extractfilename(SaveDialog1.FileName), Tree.focusednode.Index, tempbmp, NewWidth, NewHeight)
      finally
        tempbmp.Free;
      end;
    end
    else
      SaveImage(ExtractFilePath(SaveDialog1.FileName), extractfilename(SaveDialog1.FileName), Tree.focusednode.Index, Image1.Bitmap);
  end;
  DoLog('Done!');
  SaveDialog1.DefaultExt:='';
  SaveDialog1.Filter:='All Files|*.*';
  progressbar1.Position:=0;
end;

procedure TMainfrm.btnSaveAllAudioClick(Sender: TObject);
begin
  if dlgBrowseforFolder.Execute then
  begin

  end
  else
  begin
    DoLog('No Save folder chosen, aborting.');
    exit;
  end;

  DoLog('Saving all audio files...');
  DoButtons(false);
  try
    dumper.SaveAudioFiles(dlgBrowseforfolder.Directory);
  finally
    DoButtons(true);
    DoLog('All done!');
    progressbar1.Position:=0;
  end;
end;


procedure TMainfrm.OnDoneLoading(RootNodeCount: integer);
begin  
  Tree.RootNodeCount:=RootNodeCount;
end;

procedure TMainfrm.btnSaveSingleAudioClick(Sender: TObject);
var
  FileExt, FileName: string;
begin
  if Tree.RootNodeCount=0 then exit;
  if Tree.SelectedCount=0 then exit;

  if dumper.IsAudioOgg(Tree.focusednode.Index)= true then
    fileext:='.ogg'
  else
    fileext:='.wav';

  FileName:=dumper.FileNamesArray[Tree.focusednode.Index];

  if stripos('loop', extractfileext(filename)) > 0 then //It has 'loop' in the file extension.
    filename:=pathextractfilenamenoext(filename)+ 'Loop' + '.blah'; //File extension will be removed, so add 'loop' to filename


  SaveDialog1.FileName:=pathextractfilenamenoext(filename) + fileext;
  SaveDialog1.DefaultExt:=fileext;
  SaveDialog1.Filter:=fileext + ' files' + '|' + '*' + fileext;
  if SaveDialog1.Execute then
  begin

  end
  else
  begin
    DoLog('Save cancelled, aborting.');
    SaveDialog1.DefaultExt:='';
    SaveDialog1.Filter:='All Files|*.*';
    exit;
  end;

  DoLog('Saving audio file '  + extractfilename(SaveDialog1.FileName) + '...');
  DoButtons(false);
  try
    dumper.SaveAudioFile(Tree.focusednode.Index, ExtractFilePath(SaveDialog1.FileName), extractfilename(SaveDialog1.FileName));
  finally
    DoButtons(true);
    DoLog('Done!');
    progressbar1.Position:=0;
    SaveDialog1.DefaultExt:='';
    SaveDialog1.Filter:='All Files|*.*';
  end;
end;

procedure TMainfrm.UpdateAllFilesView;
var
  temp, prevnode: pvirtualnode;
  i: integer;
  firstext, currext: string;
  AllMatch: boolean;
begin
  if tree.RootNodeCount=0 then exit;
  
  //see if the files are all the same type
    AllMatch:=true;
    temp:=tree.getfirstvisible;
    firstext:=extractfileext(dumper.FileNamesArray[temp.index]);

    //just do it for audio files, since all others contain a mix of files
    if strindex(uppercase(firstext), AudioTypes)>-1 then
    begin
      for i:=0 to tree.VisibleCount -2 do
      begin
        prevnode:=temp;
        temp:=tree.GetNextVisible(prevnode);
        currext:=extractfileext(dumper.FileNamesArray[temp.index]);
        if strindex(uppercase(currext), AudioTypes)=-1 then
        begin
          AllMatch:=false;
          break;
        end
      end;

      if AllMatch=true then
      begin
        btnSaveSingleAudio.Enabled:=false;
        image1.Bitmap:=nil;
        pnlText.Align:=alNone;
        pnlNone.Align:=alNone;
        pnlImage.Align:=alnone;
        pnlAudio.Align:=alClient;
        pnlAudio.BringToFront;
      end;
    end;

end;

procedure TMainfrm.btnSearchClick(Sender: TObject);
begin
  if tree.rootnodecount=0 then exit;

  Searchfrm.show;
end;

//For making the ps2values file
procedure TMainfrm.SaveBundleInfoToFile;
var
  temp: tfilestream;
  i, j: integer;
  adword: longword;
  tempstring: string;
  letter: byte;
begin
  temp:=tfilestream.Create('c:\PS2Values.bgbb', fmcreate or fmopenwrite);
  try
    adword:=1111639874; //BGBB
    temp.Writebuffer(adword, sizeof(adword));

    adword:=1; //Version = 1
    temp.Writebuffer(adword, sizeof(adword));

    adword:=1162690894; //NAME section
    temp.Writebuffer(adword, sizeof(adword));

    adword:=tree.RootNodeCount; //No of files in name section
    temp.Writebuffer(adword, sizeof(adword));

    for i:=0 to tree.RootNodeCount -1 do
    begin
      adword:=length(dumper.FileNamesArray[i]);
      temp.Writebuffer(adword, sizeof(adword));

      tempstring:=dumper.FileNamesArray[i];
      for j:=1 to length(tempstring) do
      begin
        letter:=ord(tempstring[j]);
        temp.WriteBuffer(letter, sizeof(letter));
      end;
    end;

    adword:=1163544915; //SIZE section
    temp.Writebuffer(adword, sizeof(adword));

    adword:=tree.RootNodeCount; //No of files in name section
    temp.Writebuffer(adword, sizeof(adword));

    for i:=0 to tree.RootNodeCount -1 do
    begin
      adword:=dumper.FileSizesArray[i];
      temp.Writebuffer(adword, sizeof(adword));
    end;

    adword:=1397114447; //OFFS section
    temp.Writebuffer(adword, sizeof(adword));

    adword:=tree.RootNodeCount; //No of files in name section
    temp.Writebuffer(adword, sizeof(adword));

    for i:=0 to tree.RootNodeCount -1 do
    begin
      adword:=dumper.OffsetsArray[i];
      temp.Writebuffer(adword, sizeof(adword));
    end;

  finally
    temp.Free;
  end;
end;

procedure TMainfrm.MemoLogURLClick(Sender: TObject; const URLText: string;
  Button: TMouseButton);
begin
  shellexec(0, 'open', URLText,'', '', SW_SHOWNORMAL);
end;

end.
