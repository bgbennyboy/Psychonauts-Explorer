{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit SearchForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Mask, JvExMask, JvToolEdit, ExtCtrls, JvExControls,
  JvComponent, JvSpeedButton, VirtualTrees, JvExStdCtrls, JvListComb, Jclstrings, Jclfileutils;

type
  TSearchfrm = class(TForm)
    pnlSearch: TPanel;
    editFind: TJvComboEdit;
    SearchTree: TVirtualStringTree;
    chkboxWholeWord: TCheckBox;
    procedure SearchTreeGetImageIndex(Sender: TBaseVirtualTree;
      Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
      var Ghosted: Boolean; var ImageIndex: Integer);
    procedure SearchTreeChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure SearchTreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: WideString);
    procedure SearchTreeGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure editFindButtonClick(Sender: TObject);
  private

  public
    { Public declarations }
  end;

var
  Searchfrm: TSearchfrm;
  NodeNums: array of cardinal;
  FoundNames: TStringList;

implementation

uses MainForm;

{$R *.dfm}

procedure TSearchfrm.editFindButtonClick(Sender: TObject);
var
  i, FoundPos: integer;
  temp, prevnode: pvirtualnode;
  TempName: string;
begin
  if EditFind.Text = '' then exit;

  SearchTree.Clear;
  SearchTree.Enabled:=false;
  EditFind.Enabled:=false;

  temp:=mainfrm.tree.getfirstvisible;
  NodeNums:=nil;
  FoundNames.Clear;
  if chkboxWholeWord.Checked=false then
  for i:=0 to mainfrm.tree.VisibleCount -1 do
  begin
    FoundPos:=pos(uppercase(EditFind.Text) , uppercase(dumper.FileNamesArray[temp.index]));
    if FoundPos > 0 then
    begin
      FoundNames.Add(dumper.FileNamesArray[temp.index]);
      setlength(NodeNums, FoundNames.Count);
      NodeNums[FoundNames.Count -1]:=temp.index;
    end;
    prevnode:=temp;
    temp:=mainfrm.tree.GetNextVisible(prevnode);
  end
  else //Search for whole word only
  for i:=0 to mainfrm.tree.VisibleCount -1 do
  begin
    if extractfileext(EditFind.Text) > '' then //search term has file extension
      TempName:=uppercase(dumper.FileNamesArray[temp.index])
    else //search doesnt include file ext, so remove it
      TempName:=pathextractfilenamenoext(uppercase(dumper.FileNamesArray[temp.index]));

    if TempName = UpperCase(EditFind.Text) then
      FoundPos:=1
    else
      FoundPos:=0;

    if FoundPos > 0 then
    begin
      FoundNames.Add(dumper.FileNamesArray[temp.index]);
      setlength(NodeNums, FoundNames.Count);
      NodeNums[FoundNames.Count -1]:=temp.index;
    end;
    prevnode:=temp;
    temp:=mainfrm.tree.GetNextVisible(prevnode);
  end;

  SearchTree.RootNodeCount:=FoundNames.Count;

  if FoundNames.Count = 0 then
    Showmessage('Could not find "' + EditFind.Text + '"')
  else
    EditFind.AutoCompleteItems.Add(EditFind.Text);

  SearchTree.Enabled:=true;
  EditFind.Enabled:=true;
end;

procedure TSearchfrm.FormDestroy(Sender: TObject);
begin
  NodeNums:=nil;
  FoundNames.Free;
end;

procedure TSearchfrm.FormCreate(Sender: TObject);
begin
  FoundNames:=TStringList.Create;
end;

procedure TSearchfrm.SearchTreeGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := 0;
end;

procedure TSearchfrm.SearchTreeGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: WideString);
begin
  case Column of
   -1,0: Celltext := FoundNames[node.index];
  end;
end;

procedure TSearchfrm.SearchTreeChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  temp, prevnode: pvirtualnode;
  i: integer;
begin
  if SearchTree.RootNodeCount=0 then exit;
  if SearchTree.SelectedCount=0 then exit;

  temp:=mainfrm.tree.getfirstvisible;
  for i:=0 to mainfrm.tree.VisibleCount -1 do //get the node
  begin
    if temp.Index = NodeNums[Node.index] then
    begin
      break;
    end;

    prevnode:=temp;
    temp:=mainfrm.tree.GetNextVisible(prevnode);
  end;

  mainfrm.tree.FocusedNode:=temp;
  mainfrm.Tree.Selected[temp]:=true;
  mainfrm.tree.ScrollIntoView(temp, true);
end;

procedure TSearchfrm.SearchTreeGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: Integer);
var
  ext: string;
begin
  ext:=Uppercase(extractfileext(FoundNames[node.index]));
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
    if (ext='.PLB') or (ext='.PL2')then
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

end.
