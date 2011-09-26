{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit PsychoFileReader;

interface

uses
	Classes, SysUtils;

type
  TPsychoFileStream = class (TFileStream)

  private

  public
    function ReadByte: byte;
    function ReadWord: word;
    function ReadDWord: longword;
    function ReadBlockName: string;
    constructor Create(Filename: string);
    destructor Destroy; override;

end;

implementation

function TPsychoFileStream.ReadByte: byte;
begin
	Read(result,1);
end;

function TPsychoFileStream.ReadWord: word;
begin
  Read(result,2);
end;

function TPsychoFileStream.ReadDWord: longword;
begin
  Read(result,4);
end;

function TPsychoFileStream.ReadBlockName: string;
begin
   result:=chr(ReadByte)+chr(ReadByte)+chr(ReadByte)+chr(ReadByte);
end;


constructor TPsychoFileStream.Create(Filename: string);
begin
  inherited Create(Filename, fmopenread);
end;

destructor TPsychoFileStream.Destroy;
begin
  inherited;
end;

end.
