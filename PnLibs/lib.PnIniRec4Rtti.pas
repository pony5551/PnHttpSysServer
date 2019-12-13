unit lib.PnIniRec4Rtti;

interface

uses
  System.SysUtils, System.Classes, System.Rtti, System.TypInfo;

type
  IniValueAttribute = class(TCustomAttribute)
  private
    FName: string;
    FDefaultValue: string;
    FSection: string;
  public
    constructor Create(const aSection: string; const aName: string; const aDefaultValue: string = '');
    property Section: string read FSection write FSection;
    property Name: string read FName write FName;
    property DefaultValue: string read FDefaultValue write FDefaultValue;
  end;

  EIniRec4Rtti = class(Exception);

  TIniRec4Rtti = class(TObject)
  private
    class procedure SetValue(aData: string; var aValue: TValue);
    class function GetValue(var aValue: TValue): string;
    class function GetIniAttribute(Obj: TRttiObject): IniValueAttribute;
  public
    class procedure Load(FileName: string; RecPtr: Pointer; TypPtr: PTypeInfo);
    class procedure Save(FileName: string; RecPtr: Pointer; TypPtr: PTypeInfo);
  end;

implementation

uses
  IniFiles;

{ IniValueAttribute }
constructor IniValueAttribute.Create(const aSection, aName, aDefaultValue: string);
begin
  FSection := aSection;
  FName := aName;
  FDefaultValue := aDefaultValue;
end;


{ TIniRec4Rtti }
class function TIniRec4Rtti.GetIniAttribute(Obj: TRttiObject): IniValueAttribute;
var
  Attr: TCustomAttribute;
begin
  for Attr in Obj.GetAttributes do
  begin
    if Attr is IniValueAttribute then
    begin
      Result := IniValueAttribute(Attr);
      Exit;
    end;
  end;
  Result := nil;
end;

class function TIniRec4Rtti.GetValue(var aValue: TValue): string;
begin
  if aValue.Kind in [tkWChar, tkLString, tkWString, tkString, tkChar, tkUString, tkInteger, tkInt64, tkFloat, tkEnumeration, tkSet] then
    Result := aValue.ToString
  else
    raise EIniRec4Rtti.Create('Type not Supported');
end;

class procedure TIniRec4Rtti.Load(FileName: string; RecPtr: Pointer; TypPtr: PTypeInfo);
var
  Ini: TMemIniFile;

  procedure ToRecord(RecPtr: Pointer; TypPtr: PTypeInfo);
  var
    AContext: TRttiContext;
    AFields: TArray<TRttiField>;
    ARttiType: TRttiType;
    ABaseAddr: Pointer;
    J: Integer;
    Value: TValue;
    IniValue: IniValueAttribute;
    Data: string;
    sList: TStringList;
  begin
    AContext := TRttiContext.Create;
    ARttiType := AContext.GetType(TypPtr);
    if (not Assigned(ARttiType)) or (Assigned(ARttiType) and not ARttiType.IsRecord) then
      Exit;
    ABaseAddr := RecPtr;
    AFields := ARttiType.GetFields;
    for J := Low(AFields) to High(AFields) do
    begin
      if AFields[J].FieldType.IsRecord then
      begin
        //µ›πÈ
        ToRecord(Pointer(IntPtr(ABaseAddr) + AFields[J].Offset), AFields[J].FieldType.Handle);
      end
      else
      begin
        //∂¡»°
        IniValue := GetIniAttribute(AFields[J]);
        //debugEx('IniValue: %s, %s', [IniValue.Section, IniValue.Name]);
        if Assigned(IniValue) then
        begin
          if IniValue.Name = '' then
          begin
            sList := TStringList.Create;
            try
              Ini.ReadSectionValues(IniValue.Section, sList);
              Data := sList.Text;
            finally
              FreeAndNil(sList);
            end;
            if Data = '' then
              Data := IniValue.DefaultValue;
          end
          else
          begin
            Data := Ini.ReadString(IniValue.Section, IniValue.Name, IniValue.DefaultValue);
          end;
          Value := AFields[J].GetValue(ABaseAddr);
          SetValue(Data, Value);
          AFields[J].SetValue(ABaseAddr, Value);
        end;
      end;
    end;
  end;

begin
  Ini := TMemIniFile.Create(FileName);
  try
    ToRecord(RecPtr, TypPtr);
  finally
    FreeAndNil(Ini);
  end;
end;

class procedure TIniRec4Rtti.Save(FileName: string; RecPtr: Pointer; TypPtr: PTypeInfo);
var
  Ini: TMemIniFile;

  procedure ToIni(RecPtr: Pointer; TypPtr: PTypeInfo);
  var
    AContext: TRttiContext;
    AFields: TArray<TRttiField>;
    ARttiType: TRttiType;
    ABaseAddr: Pointer;
    J: Integer;
    Value: TValue;
    IniValue: IniValueAttribute;
    Data: string;
  begin
    AContext := TRttiContext.Create;
    ARttiType := AContext.GetType(TypPtr);
    if (not Assigned(ARttiType)) or (Assigned(ARttiType) and not ARttiType.IsRecord) then
      Exit;
    ABaseAddr := RecPtr;
    AFields := ARttiType.GetFields;
    for J := Low(AFields) to High(AFields) do
    begin
      if AFields[J].FieldType.IsRecord then
      begin
        //µ›πÈ
        ToIni(Pointer(IntPtr(ABaseAddr) + AFields[J].Offset), AFields[J].FieldType.Handle);
      end
      else
      begin
        //±£¥Ê
        IniValue := GetIniAttribute(AFields[J]);
        if Assigned(IniValue) then
        begin
          Value := AFields[J].GetValue(ABaseAddr);
          Data := GetValue(Value);
          if IniValue.Name='' then
          begin
            if Data[1]='=' then
              Delete(Data, 1, 1);
            Ini.WriteString(IniValue.Section, IniValue.Name, Data);
          end
          else
            Ini.WriteString(IniValue.Section, IniValue.Name, Data);
        end;
      end;
    end;
  end;

begin
  Ini := TMemIniFile.Create(FileName);
  try
    ToIni(RecPtr, TypPtr);
    Ini.UpdateFile;
  finally
    FreeAndNil(Ini);
  end;
end;

class procedure TIniRec4Rtti.SetValue(aData: string; var aValue: TValue);
var
  I: Integer;
begin
  case aValue.Kind of

    tkWChar, tkLString, tkWString, tkString, tkChar, tkUString:
      aValue := aData;

    tkInteger, tkInt64:
      aValue := StrToInt64Def(aData, 0);

    tkFloat:
      aValue := StrToFloatDef(aData, 0.00);

    tkEnumeration:
      aValue := TValue.FromOrdinal(aValue.TypeInfo, GetEnumValue(aValue.TypeInfo, aData));

    tkSet:
      begin
        I := StringToSet(aValue.TypeInfo, aData);
        TValue.Make(@I, aValue.TypeInfo, aValue);
      end;
  else
    raise EIniRec4Rtti.Create('Type not Supported');
  end;
end;

end.

