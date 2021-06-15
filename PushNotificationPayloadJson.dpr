program PushNotificationPayloadJson;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Variants,
  System.JSON,
  System.JSON.Serializers,
  System.JSON.Readers,
  System.JSON.Writers,
  System.Rtti,
  System.TypInfo,
  System.JSON.Types;

type
  TJsonKeyValuesConverter = class(TJsonConverter)
  public
    procedure WriteJson(const AWriter: TJsonWriter; const AValue: TValue; const ASerializer: TJsonSerializer); override;
    function ReadJson(const AReader: TJsonReader; ATypeInf: PTypeInfo; const AExistingValue: TValue; const ASerializer: TJsonSerializer): TValue; override;
  end;

  TKeyValue = record
  public
    Key: String;
    Value: Variant;
    constructor Create(const aKey: String; const aValue: Variant);
  end;

  [JsonConverter(TJsonKeyValuesConverter)]
  TKeyValueDynArray = array of TKeyValue;
  TKeyValueDynArray_Helper = record helper for TKeyValueDynArray
  private
    function GetValues(const aKey: String): Variant;
    procedure SetValues(const aKey: String; const aValue: Variant);
    function GetCount: Integer; inline;
    procedure SetCount(const aValue: Integer);
  public
    property Count: Integer read GetCount write SetCount;
    property Values[const aKey: String]: Variant read GetValues write SetValues;
  end;

  TPayload = record
  private
    function GetAsJson: String;
    procedure SetAsJson(const aValue: String);
  public
    &message: record
      token: string;
      notification: record
        title: string;
        body: string;
        image: string;
      end;
      android: record
        priority: string;
        data: TKeyValueDynArray;
        notification: record
          click_action: string;
          image: string;
          sound: string;
        end;
      end;
      apns: record
        payload: record
          aps: record
            sound: string;
            badge: integer;
            [JsonName('content-available')]
            contentAvailable: integer;
            [JsonName('mutable-content')]
            mutableContent: integer;
          end;
        end;
      end;
    end;
    constructor Create(const aJson: String);
    property AsJson: String read GetAsJson write SetAsJson;
  end;

{ TJsonKeyValuesConverter }

function TJsonKeyValuesConverter.ReadJson(const AReader: TJsonReader;
  ATypeInf: PTypeInfo; const AExistingValue: TValue;
  const ASerializer: TJsonSerializer): TValue;
begin
  Assert(AReader.CurrentState = TJsonReader.TState.ObjectStart);
  Assert(AExistingValue.TypeInfo = TypeInfo(TKeyValueDynArray));
  var lValues := AExistingValue.AsType<TKeyValueDynArray>;
  lValues.Count := 0;
  var lPropertyName: string := '';
  while AReader.Read do begin
    case AReader.TokenType of
      TJsonToken.PropertyName
      : lPropertyName := AReader.Value.AsString;
      TJsonToken.EndObject
      : Break;
      TJsonToken.Integer,
      TJsonToken.Float,
      TJsonToken.String,
      TJsonToken.Boolean,
      TJsonToken.Null,
      TJsonToken.Date
      : lValues.Values[lPropertyName] := AReader.Value.AsVariant;
    else
//      TJsonToken.None: ;
//      TJsonToken.StartObject: ;
//      TJsonToken.StartArray: ;
//      TJsonToken.StartConstructor: ;
//      TJsonToken.Comment: ;
//      TJsonToken.Raw: ;
//      TJsonToken.Undefined: ;
//      TJsonToken.EndArray: ;
//      TJsonToken.EndConstructor: ;
//      TJsonToken.Bytes: ;
//      TJsonToken.Oid: ;
//      TJsonToken.RegEx: ;
//      TJsonToken.DBRef: ;
//      TJsonToken.CodeWScope: ;
//      TJsonToken.MinKey: ;
//      TJsonToken.MaxKey: ;
      Assert(False,GetEnumName(TypeInfo(TJsonToken),Ord(AReader.TokenType)));
    end;
  end;
  Result := TValue.From<TKeyValueDynArray>(lValues);
end;

procedure TJsonKeyValuesConverter.WriteJson(const AWriter: TJsonWriter;
  const AValue: TValue; const ASerializer: TJsonSerializer);
begin
  AWriter.WriteStartObject;
  Assert(aValue.TypeInfo = TypeInfo(TKeyValueDynArray),'Wrong type');
  var lValues := aValue.AsType<TKeyValueDynArray>;
  for var lItem in lValues do begin
    AWriter.WritePropertyName(lItem.Key);
    AWriter.WriteValue(TValue.FromVariant(lItem.Value));
  end;
  AWriter.WriteEndObject;
end;

{ TKeyValue }

constructor TKeyValue.Create(const aKey: String; const aValue: Variant);
begin
  Key := aKey;
  Value := aValue;
end;

{ TKeyValueDynArray_Helper }

function TKeyValueDynArray_Helper.GetCount: Integer;
begin
  Result := Length(Self);
end;

function TKeyValueDynArray_Helper.GetValues(const aKey: String): Variant;
begin
  for var lItem in Self do
    if lItem.Key = aKey then
      Exit(lItem.Value);
  Result := Unassigned;
end;

procedure TKeyValueDynArray_Helper.SetCount(const aValue: Integer);
begin
  SetLength(Self,aValue);
end;

procedure TKeyValueDynArray_Helper.SetValues(const aKey: String; const aValue:
    Variant);
begin
  for var lIndex := Low(Self) to High(Self) do begin
    if Self[lIndex].Key <> aKey then
      continue;
    Self[lIndex].Value := aValue;
  end;
  System.Insert(TKeyValue.Create(aKey, aValue), Self, Count);
end;

constructor TPayload.Create(const aJson: String);
begin
  AsJson := aJson;
end;

function TPayload.GetAsJson: String;
begin
  with TJsonSerializer.Create do try
    Result := Serialize<TPayload>(Self);
  finally
    Free;
  end;
end;

procedure TPayload.SetAsJson(const aValue: String);
begin
  with TJsonSerializer.Create do try
    Self := Deserialize<TPayload>(aValue);
  finally
    Free;
  end;
end;

begin
  try
    var lSample :=
      '  {'#13#10 + //0
      '    "message": {'#13#10 + //1
      '      "token": "/topics/GotchaGroup1",'#13#10 + //2
      '      "notification": {'#13#10 + //3
      '        "title": "Title",'#13#10 + //4
      '        "body": "Body",'#13#10 + //5
      '        "image": "http://imageurl"'#13#10 + //6
      '      },'#13#10 + //7
      '      "android": {'#13#10 + //8
      '        "priority": "normal",'#13#10 + //9
      '        "data": {'#13#10 + //10
      '          "something": "bloop"'#13#10 + //11
      '        },'#13#10 + //12
      '        "notification": {'#13#10 + //13
      '          "click_action": "https://www.google.com",'#13#10 + //14
      '          "image": "http://imageurl",'#13#10 + //15
      '          "sound": "1"'#13#10 + //16
      '        }'#13#10 + //17
      '      },'#13#10 + //18
      '      "apns": {'#13#10 + //19
      '        "payload": {'#13#10 + //20
      '          "aps": {'#13#10 + //21
      '            "sound": "1",'#13#10 + //22
      '            "badge": 1,'#13#10 + //23
      '            "content-available": 1,'#13#10 + //24
      '            "mutable-content": 1'#13#10 + //25
      '          }'#13#10 + //26
      '        }'#13#10 + //27
      '      }'#13#10 + //28
      '    }'#13#10 + //29
      '  }';

    var lPayload := TPayload.Create(lSample);
    var lOutput := lPayload.AsJson;
    Writeln(lOutput);
    Readln;

    { TODO -oUser -cConsole Main : Insert code here }
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.

