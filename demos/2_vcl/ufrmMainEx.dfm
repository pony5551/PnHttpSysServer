object frmMainEx: TfrmMainEx
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'PnHttpSysServerMain'
  ClientHeight = 562
  ClientWidth = 811
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnl1: TPanel
    Left = 0
    Top = 0
    Width = 811
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object pnl4: TPanel
      Left = 627
      Top = 0
      Width = 184
      Height = 41
      Align = alRight
      BevelOuter = bvNone
      TabOrder = 0
      object lbl1: TLabel
        Left = 58
        Top = 7
        Width = 16
        Height = 13
        Caption = '0/0'
      end
      object lbl2: TLabel
        Left = 58
        Top = 23
        Width = 16
        Height = 13
        Caption = '0/0'
      end
      object lbl3: TLabel
        Left = 3
        Top = 7
        Width = 52
        Height = 13
        Caption = #35831#27714#32479#35745':'
      end
      object lbl4: TLabel
        Left = 3
        Top = 23
        Width = 52
        Height = 13
        Caption = #23545#35937#32479#35745':'
      end
    end
    object pnl5: TPanel
      Left = 0
      Top = 0
      Width = 361
      Height = 41
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 1
      object chkLog: TCheckBox
        Left = 168
        Top = 12
        Width = 55
        Height = 17
        Caption = 'IIS'#26085#24535
        Checked = True
        State = cbChecked
        TabOrder = 0
      end
      object lnklblLocalUrl: TLinkLabel
        Left = 229
        Top = 13
        Width = 106
        Height = 17
        Caption = 'http://localhost:8080'
        TabOrder = 1
        OnLinkClick = lnklblLocalUrlLinkClick
      end
      object btnStart: TBitBtn
        Left = 6
        Top = 8
        Width = 75
        Height = 25
        Caption = 'btnStart'
        TabOrder = 2
        OnClick = btnStartClick
      end
      object btnStop: TBitBtn
        Left = 87
        Top = 8
        Width = 75
        Height = 25
        Caption = 'btnStop'
        TabOrder = 3
        OnClick = btnStopClick
      end
    end
    object pnl6: TPanel
      Left = 361
      Top = 0
      Width = 266
      Height = 41
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 2
      object Label1: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 13
        Width = 52
        Height = 25
        Margins.Top = 13
        Align = alLeft
        Caption = #31995#32479#36816#34892':'
        ExplicitHeight = 13
      end
      object lbl5: TLabel
        AlignWithMargins = True
        Left = 61
        Top = 13
        Width = 3
        Height = 25
        Margins.Top = 13
        Align = alLeft
        ExplicitHeight = 13
      end
    end
  end
  object pnl2: TPanel
    Left = 0
    Top = 41
    Width = 811
    Height = 479
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object mmo1: TMemo
      Left = 0
      Top = 0
      Width = 811
      Height = 479
      Align = alClient
      Color = clNone
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clLime
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = []
      Lines.Strings = (
        'mmo1')
      ParentFont = False
      TabOrder = 0
    end
  end
  object pnl3: TPanel
    Left = 0
    Top = 520
    Width = 811
    Height = 42
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object lblCopyRight: TLinkLabel
      AlignWithMargins = True
      Left = 6
      Top = 10
      Width = 802
      Height = 29
      Margins.Left = 6
      Margins.Top = 10
      Align = alClient
      Caption = 'lblCopyRight'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsItalic]
      ParentFont = False
      TabOrder = 0
      ExplicitWidth = 94
      ExplicitHeight = 23
    end
  end
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 368
    Top = 200
  end
  object tmr1: TTimer
    Interval = 500
    OnTimer = tmr1Timer
    Left = 472
    Top = 208
  end
end
