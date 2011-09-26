{
******************************************************
  Psychonauts Explorer
  Copyright (c) 2005 - 2007 Bgbennyboy
  Http://quick.mixnmojo.com
******************************************************
}

unit PsychoImageDumper;

interface

uses
  Classes, dds, graphics, GR32, PsychoFileReader;

type
  TPsychoImageDumper = class

  private
    TheFile: TStream;
    DDSImage: tddsimage;
    function GetDDSImage(Offset, Size: integer): boolean;
  public
    constructor Create(ResourceFile: TStream);
    destructor Destroy; override;
    procedure DrawDDSImage(Offset, Size: integer; Outimage: tbitmap32);
    procedure WriteDDSImage(Width, Height, Mipmaps, TextureID: integer; IsCubeMap: boolean; Data, Dest: tstream; DataSize: integer);
end;

implementation

const
   DDSD_CAPS        = $00000001;
   DDSD_HEIGHT      = $00000002;
   DDSD_WIDTH       = $00000004;
   DDSD_PITCH       = $00000008;
   DDSD_PIXELFORMAT = $00001000;
   DDSD_MIPMAPCOUNT = $00020000;
   DDSD_LINEARSIZE  = $00080000;
   DDSD_DEPTH       = $00800000;

   DDPF_ALPHAPIXELS = $00000001;
   DDPF_FOURCC      = $00000004;
   DDPF_RGB         = $00000040;

   DDSCAPS_COMPLEX  = $00000008;
   DDSCAPS_TEXTURE  = $00001000;
   DDSCAPS_MIPMAP   = $00400000;

   DDSCAPS2_CUBEMAP           = $00000200;
   DDSCAPS2_CUBEMAP_POSITIVEX = $00000400;
   DDSCAPS2_CUBEMAP_NEGATIVEX = $00000800;
   DDSCAPS2_CUBEMAP_POSITIVEY = $00001000;
   DDSCAPS2_CUBEMAP_NEGATIVEY = $00002000;
   DDSCAPS2_CUBEMAP_POSITIVEZ = $00004000;
   DDSCAPS2_CUBEMAP_NEGATIVEZ = $00008000;
   DDSCAPS2_VOLUME            = $00200000;


type
   TDDPIXELFORMAT = record
      dwSize,
      dwFlags,
      dwFourCC,
      dwRGBBitCount,
      dwRBitMask,
      dwGBitMask,
      dwBBitMask,
      dwRGBAlphaBitMask : Cardinal;
   end;

   TDDCAPS2 = record
      dwCaps1,
      dwCaps2 : Cardinal;
      Reserved : array[0..1] of Cardinal;
   end;

   TDDSURFACEDESC2 = record
      dwSize,
      dwFlags,
      dwHeight,
      dwWidth,
      dwPitchOrLinearSize,
      dwDepth,
      dwMipMapCount : Cardinal;
      dwReserved1 : array[0..10] of Cardinal;
      ddpfPixelFormat : TDDPIXELFORMAT;
      ddsCaps : TDDCAPS2;
      dwReserved2 : Cardinal;
   end;

   TDDSHeader = record
      Magic : Cardinal;
      SurfaceFormat : TDDSURFACEDESC2;
   end;

   TFOURCC = array[0..3] of char;

const
   FOURCC_DXT1 = $31545844; // 'DXT1'
   FOURCC_DXT3 = $33545844; // 'DXT3'
   FOURCC_DXT5 = $35545844; // 'DXT5'


function TPsychoImageDumper.GetDDSImage(Offset, Size: integer): boolean;
var
  Tempstream: tmemorystream;
begin
  thefile.Seek(offset, sofrombeginning);
  Tempstream:=tmemorystream.Create;
  try
    Tempstream.CopyFrom(thefile, size);
    try
      DDSimage:=tddsimage.Create;
      tempstream.Position:=0;
      DDSimage.LoadFromStream(tempstream);
      result:=true;
    except on E: EDDSException do
      result:=false;
    end;
  finally
    Tempstream.Free;
  end;
end;

procedure TPsychoImageDumper.DrawDDSImage(Offset, Size: integer; Outimage: tbitmap32);
begin
  try
    if GetDDSImage(Offset, Size) = true then
      Outimage.Assign(DDSimage);
  finally
    DDSImage.Free;
  end;
end;

constructor TPsychoImageDumper.Create(ResourceFile: TStream);
begin
  TheFile:=ResourceFile;
end;

destructor TPsychoImageDumper.Destroy;
begin

  inherited;
end;

procedure TPsychoImageDumper.WriteDDSImage(Width, Height, Mipmaps, TextureID: integer;
  IsCubeMap: boolean; Data, Dest: tstream; DataSize: integer);
var
   magic : TFOURCC;
   header : TDDSHeader;
   rowSize : Integer;
begin
   FillChar(header, SizeOf(TDDSHeader), 0);
   magic:='DDS ';
   header.magic:=Cardinal(magic);
   with header.SurfaceFormat do begin
      dwSize:=124;
      dwFlags:=DDSD_CAPS +
               DDSD_PIXELFORMAT +
               DDSD_WIDTH +
               DDSD_HEIGHT +
               DDSD_MIPMAPCOUNT +
               DDSD_LINEARSIZE;
      if TextureID=0 then dwFlags:=dwFlags +  DDSD_PITCH;
      dwWidth:=Width;
      dwHeight:=Height;

      //PixelFormat
      ddpfPixelFormat.dwSize:=32;
      if TextureID=0 then
        ddpfPixelFormat.dwFlags:=DDPF_RGB
      else
        ddpfPixelFormat.dwFlags:=DDPF_FOURCC;
      case TextureID of
        0:  ddpfPixelFormat.dwFourCC:=0;
        6:  ddpfPixelFormat.dwFourCC:=FOURCC_DXT5; //??
        9:  ddpfPixelFormat.dwFourCC:=FOURCC_DXT1;
        10: ddpfPixelFormat.dwFourCC:=FOURCC_DXT3;
        11: ddpfPixelFormat.dwFourCC:=FOURCC_DXT5;
        12: ddpfPixelFormat.dwFourCC:=0;//24 bit??
        14: ddpfPixelFormat.dwFourCC:=FOURCC_DXT5 //??
      end;
      if TextureID=0 then
      begin
        ddpfPixelFormat.dwRGBBitCount:=32;
        ddpfPixelFormat.dwRBitMask:=$00FF0000;
        ddpfPixelFormat.dwGBitMask:=$0000FF00;
        ddpfPixelFormat.dwBBitMask:=$000000FF;
        ddpfPixelFormat.dwFlags:=ddpfPixelFormat.dwFlags + DDPF_ALPHAPIXELS;
        ddpfPixelFormat.dwRGBAlphaBitMask:=$FF000000;
      end
      else
      begin
        ddpfPixelFormat.dwRGBBitCount:=0;
        ddpfPixelFormat.dwRBitMask:=0;
        ddpfPixelFormat.dwGBitMask:=0;
        ddpfPixelFormat.dwBBitMask:=0;
        ddpfPixelFormat.dwRGBAlphaBitMask:=0;
      end;

      //Caps
      ddsCaps.dwCaps1:=DDSCAPS_TEXTURE + DDSCAPS_MIPMAP + DDSCAPS_COMPLEX;
      if IsCubeMap=true then
        ddsCaps.dwCaps2:=DDSCAPS2_CUBEMAP +
                         DDSCAPS2_CUBEMAP_POSITIVEX +
                         DDSCAPS2_CUBEMAP_NEGATIVEX +
                         DDSCAPS2_CUBEMAP_POSITIVEY +
                         DDSCAPS2_CUBEMAP_NEGATIVEY +
                         DDSCAPS2_CUBEMAP_POSITIVEZ +
                         DDSCAPS2_CUBEMAP_NEGATIVEZ;

      if TextureID=0 then
      begin
        rowSize:=(ddpfPixelFormat.dwRGBBitCount div 8)*dwWidth;
        dwPitchOrLinearSize:=dwHeight*Cardinal(rowSize);
      end
      else
        dwPitchOrLinearSize:=data.Size; //compressed - size of data
        
      dwMipMapCount:=1;
      ddsCaps.dwCaps1:=DDSCAPS_TEXTURE;
      dest.Write(header, SizeOf(TDDSHeader));
   end;
   dest.CopyFrom(data, datasize);
   dest.Position:=0;
end;

end.
