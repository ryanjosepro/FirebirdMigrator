unit ViewMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons,
  System.ImageList, Vcl.ImgList, System.Actions, Vcl.ActnList, FireDAC.Stan.Def,
  FireDAC.VCLUI.Wait, FireDAC.Phys.IBWrapper, FireDAC.Stan.Intf, FireDAC.Phys,
  FireDAC.Phys.IBBase, Vcl.ComCtrls;

type
  TWindowMain = class(TForm)
    MemoLog: TMemo;
    MemoErrors: TMemo;
    LblLog: TLabel;
    LblErrors: TLabel;
    SpeedButton1: TSpeedButton;
    SpeedButton3: TSpeedButton;
    Actions: TActionList;
    Images: TImageList;
    ActOpenFile: TAction;
    ActRestore: TAction;
    Page: TPageControl;
    TabRestore: TTabSheet;
    TabConfigs: TTabSheet;
    Restore: TFDIBRestore;
    LblBackupFiles: TLabel;
    ListBox1: TListBox;
    Label1: TLabel;
    Edit1: TEdit;
    Edit2: TEdit;
    Label2: TLabel;
    Edit3: TEdit;
    Label3: TLabel;
    Edit4: TEdit;
    Label4: TLabel;
    ComboBox1: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    Edit5: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  WindowMain: TWindowMain;

implementation

{$R *.dfm}

end.