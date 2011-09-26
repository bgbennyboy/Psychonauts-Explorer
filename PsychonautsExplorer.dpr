{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

program PsychonautsExplorer;

uses
  Forms,
  MainForm in 'MainForm.pas' {Mainfrm},
  PsychoBaseDumper in 'PsychoBaseDumper.pas',
  PsychoAudioDumper in 'PsychoAudioDumper.pas',
  PsychoTypes in 'PsychoTypes.pas',
  PsychoFileReader in 'PsychoFileReader.pas',
  PsychoBundleReader in 'PsychoBundleReader.pas',
  PsychoBundleDumper in 'PsychoBundleDumper.pas',
  PsychoZLibUtils in 'PsychoZLibUtils.pas',
  SearchForm in 'SearchForm.pas' {Searchfrm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Psychonauts Explorer';
  Application.CreateForm(TMainfrm, Mainfrm);
  Application.CreateForm(TSearchfrm, Searchfrm);
  Application.Run;
end.
