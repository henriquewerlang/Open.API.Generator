object MainForm: TMainForm
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  Caption = 'MainForm'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object lblUnitName: TLabel
    Left = 8
    Top = 8
    Width = 58
    Height = 15
    Caption = 'Unit name:'
  end
  object SelectFiles: TButton
    Left = 8
    Top = 58
    Width = 129
    Height = 25
    Caption = 'Select the files'
    TabOrder = 1
    OnClick = SelectFilesClick
  end
  object UnitName: TEdit
    Left = 8
    Top = 29
    Width = 185
    Height = 23
    TabOrder = 0
    TextHint = 'Fill the unit name'
  end
  object Files: TOpenDialog
    Filter = 'JSON File|*.json'
    Options = [ofHideReadOnly, ofAllowMultiSelect, ofEnableSizing]
    Left = 248
    Top = 8
  end
  object SaveFile: TSaveDialog
    Filter = 'Pascal File|*.pas'
    Left = 248
    Top = 64
  end
end
