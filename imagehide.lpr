{ Image Hide - Simple Image Steganography Tool.

  Copyright (c) 2015 Dilshan R Jayakody. [jayakody2000llk at gmail dot com]

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}

program ImageHide;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, SysUtils, CustApp, Graphics, Interfaces;

type
  TImageHideApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  private
    procedure WriteHelp; virtual;
    procedure InsertImageToSource(SourceImage : String; CoverImage : String; OutputImage : String);
    procedure ExtractImageFromCover(SourceImage : String; ImgWidth : Integer; ImgHeight : Integer; OutputImage: String);
    procedure PrintInfo(InfoMsg : String);
  end;

procedure TImageHideApplication.DoRun;
var
  IsSubjectExtract : Boolean;
  SrImage, CoverImage : String;
  OutWidth, OutHeight : Integer;
  OutImage : String;
begin
  // parse parameters
  if ((ParamCount = 0) or (ParamStr(1) = '-h')) then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  try
     IsSubjectExtract := (lowercase(ParamStr(1)) = '-e');
     if(IsSubjectExtract) then
     begin
       // subject extraction mode.
       if(ParamCount <> 5)then
       begin
         raise Exception.Create('Insufficient parameters');
       end;

       SrImage := ParamStr(2); // <srcimage>
       OutWidth := StrToInt(ParamStr(3)); // <out-width>
       OutHeight := StrToInt(ParamStr(4)); // <out-height>
       OutImage := ParamStr(5); // <outputimage>

       // check the availability of the source image.
       if(not FileExists(SrImage)) then
       begin
         raise Exception.Create('Specified source image is not available');
       end;

       if((OutWidth <= 0) and (OutHeight <= 0)) then
       begin
         raise Exception.Create('Invalid output image dimension ' + IntToStr(OutWidth) + 'x' + IntToStr(OutHeight) + ' pixels.');
       end;

       // perform image extraction from source image.
       ExtractImageFromCover(SrImage, OutWidth, OutHeight, OutImage);

     end
     else
     begin
       // subject insertion mode.
       if(ParamCount <> 4)then
       begin
         raise Exception.Create('Insufficient parameters');
       end;

       CoverImage := ParamStr(2); // <coverimage>
       SrImage := ParamStr(3); // <srcimage>
       OutImage := ParamStr(4); // <outputimage>

       // check the availability of the source image files.
       if(not FileExists(CoverImage)) then
       begin
         raise Exception.Create('Specified cover image is not available');
       end;

       if(not FileExists(SrImage)) then
       begin
         raise Exception.Create('Specified subject image is not available');
       end;

       // perform image insertion operation.
       InsertImageToSource(SrImage, CoverImage, OutImage);
     end;
  except
    on E: Exception do
    begin
      writeln('ERROR: ' + E.Message);
    end;
  end;

  // stop program loop
  Terminate;
end;

procedure TImageHideApplication.PrintInfo(InfoMsg : String);
begin
  Writeln('INFO: ' + InfoMsg);
end;

procedure TImageHideApplication.ExtractImageFromCover(SourceImage : String; ImgWidth : Integer; ImgHeight : Integer; OutputImage: String);
var
  SrcImage, OutImage : TPicture;
  SrcX, SrcY : Integer;
  SrcR, SrcG, SrcB : Byte; BitPos : Byte;
  OutR, OutG, OutB : Byte;
  OutPosX, OutPosY : Integer;
  IsLimit : Boolean;

  function FillOutputImage(ColorData: TColor) : Boolean;
  begin
    // check the output image limit is reached.
    if(OutPosY >= ImgHeight) then
    begin
      result := false;
    end
    else
    begin
      // paint next available pixel of the output image.
      result := true;
      OutImage.Bitmap.Canvas.Pixels[OutPosX, OutPosY] := ColorData;
      OutPosX := OutPosX + 1;
      if(OutPosX >= ImgWidth)then
      begin
        OutPosX := 0;
        OutPosY := OutPosY + 1;
      end;
    end;
  end;

begin
  SrcImage := TPicture.Create;
  SrcImage.LoadFromFile(SourceImage);

  // create output image with specified dimensions.
  OutImage := TPicture.Create;
  OutImage.Bitmap := TBitmap.Create();
  OutImage.Bitmap.PixelFormat := pf24bit;
  OutImage.Bitmap.Canvas.AntialiasingMode := amOff;
  OutImage.Bitmap.Width := ImgWidth;
  OutImage.Bitmap.Height := ImgHeight;
  OutImage.Bitmap.Canvas.Lock;

  // initialize counters and data sets to know state.
  OutR := 0;
  OutG := 0;
  OutB := 0;
  BitPos := 0;
  OutPosX := 0;
  OutPosY := 0;
  IsLimit := false;

  for SrcY := 0 to (SrcImage.Height - 1) do
  begin
    for SrcX := 0 to (SrcImage.Width - 1) do
    begin
      // extract pixel data from source image.
      RedGreenBlue(SrcImage.Bitmap.Canvas.Pixels[SrcX, SrcY], SrcR, SrcG, SrcB);
      OutR := OutR or ((SrcR and $01) shl BitPos);
      OutG := OutG or ((SrcG and $01) shl BitPos);
      OutB := OutB or ((SrcB and $01) shl BitPos);
      if(BitPos = 8) then
      begin
        BitPos := 0;
        // transfer pixel data to output image painter.
        IsLimit := not FillOutputImage(RGBToColor(OutR, OutG, OutB));
        OutR := 0;
        OutG := 0;
        OutB := 0;
        // check for output image size limits.
        if(IsLimit)then
        begin
          PrintInfo('Output image created with extracted data.');
          break;
        end;
      end
      else
      begin
        BitPos := BitPos + 1;
      end;
    end;

    // output image is already constructed, break the source image scanning.
    if(IsLimit)then
    begin
      break;
    end;

  end;

  // check for complete subject image extraction.
  if(not IsLimit)then
  begin
    PrintInfo('Only the portion of image is extracted. (cover image is too small?)');
  end;

  // save extracted image file.
  OutImage.Bitmap.Canvas.Unlock;
  OutImage.SaveToFile(OutputImage);

  FreeAndNil(OutImage);
  FreeAndNil(SrcImage);
end;

procedure TImageHideApplication.InsertImageToSource(SourceImage : String; CoverImage : String; OutputImage: String);
var
  SrcImage, BackImage, OutImg : TPicture;
  SrcBitPos: Byte;
  DrawCol, DrawRow : Integer;
  ColR, ColG, ColB : Byte;
  EncR, EncG, EncB : Byte;
  SrcImageX, SrcImageY : Integer;

  function UpdateSubjectImageData : Boolean;
  begin
    // check subject image size with current index position.
    if(SrcBitPos = 9) then
    begin
      // check for the end of the source image.
      if(SrcImageY > SrcImage.Height) then
      begin
        result := false;
      end;

      // move to next pixel in subject image.
      RedGreenBlue(SrcImage.Bitmap.Canvas.Pixels[SrcImageX, SrcImageY], EncR, EncG, EncB);
      SrcBitPos := 0;
      SrcImageX := SrcImageX + 1;

      // update image XY index values.
      if(SrcImageX >=  SrcImage.Width) then
      begin
        SrcImageY := SrcImageY + 1;
        SrcImageX := 0;
      end;
    end
    else
    begin
      result := true;
    end;
  end;

begin
  // load subject image from specified file location.
  SrcImage := TPicture.Create;
  SrcImage.LoadFromFile(SourceImage);

  // load cover image from specified file location.
  BackImage := TPicture.Create;
  BackImage.LoadFromFile(CoverImage);
  BackImage.Bitmap.Canvas.AntialiasingMode := amOff;

  // create output image buffer.
  OutImg := TPicture.Create;
  OutImg.Bitmap := TBitmap.Create;
  OutImg.Bitmap.Width := BackImage.Width;
  OutImg.Bitmap.Height := BackImage.Height;
  OutImg.Bitmap.Canvas.AntialiasingMode := amOff;
  OutImg.Bitmap.Canvas.Lock;

  // initialize counters to known state.
  SrcBitPos := 8;
  DrawCol := 0;
  DrawRow := 0;
  SrcImageX := 0;
  SrcImageY := 0;

  // show subject image details.
  PrintInfo('Subject image size is ' + IntToStr(SrcImage.Width) + 'x' + IntToStr(SrcImage.Height) + ' pixels.');

  // navigate over cover image pixels.
  for DrawRow := 0 to (BackImage.Height - 1) do
  begin
    for DrawCol := 0 to (BackImage.Width - 1) do
    begin
      RedGreenBlue(BackImage.Bitmap.Canvas.Pixels[DrawCol, DrawRow], ColR, ColG, ColB);
      SrcBitPos := SrcBitPos + 1;
      // load pixel data from subject image.
      if(UpdateSubjectImageData) then
      begin
        // change RGB data based on subject's current pixel value.
        ColR := (ColR and $FE) or ((EncR shr SrcBitPos) and $01);
        ColG := (ColG and $FE) or ((EncG shr SrcBitPos) and $01);
        ColB := (ColB and $FE) or ((EncB shr SrcBitPos) and $01);
      end;
      OutImg.Bitmap.Canvas.Pixels[DrawCol, DrawRow] := RGBToColor(ColR, ColG, ColB);
    end;
  end;

  // save modified image as output image.
  OutImg.Bitmap.Canvas.Unlock;
  OutImg.SaveToFile(OutputImage);

  FreeAndNil(OutImg);
  FreeAndNil(BackImage);
  FreeAndNil(SrcImage);

  PrintInfo('Output image created successfully.');
end;

constructor TImageHideApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
end;

destructor TImageHideApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TImageHideApplication.WriteHelp;
begin
  writeln('Image Hide. Copyright (C) 2015 Dilshan R Jayakody.');
  writeln('');
  writeln('This program comes with ABSOLUTELY NO WARRANTY; ');
  writeln('This is free software, and you are welcome to redistribute it');
  writeln('under certain conditions; Check gpl-3.0.txt file for details.');
  writeln('');
  writeln('Usage: ',ExtractFileName(ExeName),' -e -i -h [parameters] <outputimage>'#10);
  writeln(' -e <srcimage> <out-width> <out-height> <outputimage>');
  writeln('    extract image from <srcimage> and save to <outputimage>.');
  writeln('    <out-width> and <out-height> are dimensions of the output image.'#10);
  writeln(' -i <coverimage> <subjectimage> <outputimage>');
  writeln('    insert <subjectimage> into <coverimage> and save to <outputimage>.'#10);
  writeln(' -h show help screen.');
end;

var
  Application: TImageHideApplication;
begin
  Application := TImageHideApplication.Create(nil);
  Application.Title:='Image Hide';
  Application.Run;
  Application.Free;
end.

