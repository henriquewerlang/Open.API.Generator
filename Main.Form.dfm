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
  object lblOpenAPIVersion: TLabel
    Left = 8
    Top = 8
    Width = 91
    Height = 15
    Caption = 'Open API Version'
  end
  object OpenAPIVersion: TComboBox
    Left = 8
    Top = 29
    Width = 193
    Height = 23
    Style = csDropDownList
    TabOrder = 0
    Items.Strings = (
      'Open API 2.0'
      'Open API 3.0')
  end
end
