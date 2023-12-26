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
  object SelectFiles: TButton
    Left = 8
    Top = 8
    Width = 129
    Height = 25
    Caption = 'Select the files'
    TabOrder = 0
    OnClick = SelectFilesClick
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
