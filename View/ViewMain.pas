unit ViewMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, System.ImageList, Vcl.ImgList,
  System.Actions, Vcl.ActnList, FireDAC.Stan.Def, FireDAC.VCLUI.Wait, FireDAC.Phys.IBWrapper,
  FireDAC.Stan.Intf, FireDAC.Phys, FireDAC.Phys.IBBase, Vcl.ComCtrls, Vcl.ExtCtrls, Vcl.CheckLst,
  ACBrBase, FireDAC.Phys.FBDef, FireDAC.Phys.FB, NsEditBtn, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Pool,
  FireDAC.Stan.Async, Data.DB, FireDAC.Comp.Client, System.IniFiles,
  Migration, Config, MyUtils;

type
  TWindowMain = class(TForm)
    Page: TPageControl;
    TabMigration: TTabSheet;
    Images: TImageList;
    Actions: TActionList;
    ActAddBackup: TAction;
    ActRmvBackup: TAction;
    ActEsc: TAction;
    ActDbFile: TAction;
    ActRestore: TAction;
    FBRestore: TFDIBRestore;
    ActMigrate: TAction;
    GroupBoxSource: TGroupBox;
    GroupBoxDest: TGroupBox;
    LblUserSource: TLabel;
    TxtUserSource: TEdit;
    LblPasswordSource: TLabel;
    TxtPasswordSource: TEdit;
    LblDbSource: TLabel;
    LblDbDest: TLabel;
    TxtDbDest: TNsEditBtn;
    TabAdmin: TTabSheet;
    TxtDb: TNsEditBtn;
    LblDb: TLabel;
    LblUser: TLabel;
    TxtUser: TEdit;
    LblPassword: TLabel;
    TxtPassword: TEdit;
    LblProtocol: TLabel;
    BoxProtocol: TComboBox;
    TxtHost: TEdit;
    LblHost: TLabel;
    LblPort: TLabel;
    TxtPort: TEdit;
    CheckVerbose: TCheckBox;
    LblBackupFile: TLabel;
    TxtDbSource: TNsEditBtn;
    FBBackup: TFDIBBackup;
    ActBackup: TAction;
    LblOptions: TLabel;
    RadioGroupMethod: TRadioGroup;
    MemoErrors: TMemo;
    MemoLog: TMemo;
    LblErrors: TLabel;
    LblLog: TLabel;
    CheckListOptions: TCheckListBox;
    BtnMigrate: TButton;
    BtnStart: TButton;
    LblDll: TLabel;
    TxtDll: TNsEditBtn;
    BoxVersionSource: TComboBox;
    BoxVersionDest: TComboBox;
    LblVersionSource: TLabel;
    LblVersionDest: TLabel;
    RadioGroupConnMethod: TRadioGroup;
    BtnTestConn: TButton;
    TxtBackupFile: TNsEditBtn;
    MemoLogAdmin: TMemo;
    LblLogAdmin: TLabel;
    procedure ActEscExecute(Sender: TObject);
    procedure ActRestoreExecute(Sender: TObject);
    procedure FBError(ASender, AInitiator: TObject; var AException: Exception);
    procedure FBProgress(ASender: TFDPhysDriverService; const AMessage: string);
    procedure ActMigrateExecute(Sender: TObject);
    procedure BtnTestConnClick(Sender: TObject);
    procedure ActBackupExecute(Sender: TObject);
    procedure BtnStartClick(Sender: TObject);
    procedure TxtDbBtnClick(Sender: TObject);
    procedure TxtDllBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure RadioGroupConnMethodClick(Sender: TObject);
    procedure TxtBackupFileBtnClick(Sender: TObject);

    procedure OpenFileAll(Sender: TObject);
    procedure OpenFileFB(Sender: TObject);
    procedure OpenFileFBK(Sender: TObject);
    procedure OpenFolder(Sender: TObject);

    procedure SaveFileFB(Sender: TObject);
    procedure SaveFileFBK(Sender: TObject);
    procedure SaveFolder(Sender: TObject);
    procedure RadioGroupMethodClick(Sender: TObject);
  private
    procedure LoadConfigs;
    procedure SaveConfigs;

    procedure LoadAdminConfigs;
    procedure SaveAdminConfigs;

    procedure CopyFirebirdMsg;
    procedure OpenFileDLL(Sender: TObject);

    procedure OpenFile(Sender: TObject; DisplayName, FileMask: string; IncludeAllFiles: boolean);
    procedure SaveFile(Sender: TObject; DisplayName, FileMask: string; IncludeAllFiles: boolean);
  end;

var
  WindowMain: TWindowMain;
  MigrationConfig: TMigrationConfig;

implementation

{$R *.dfm}

//INIT

procedure TWindowMain.FormCreate(Sender: TObject);
begin
  MigrationConfig := TMigrationConfig.Create;
end;

procedure TWindowMain.FormDestroy(Sender: TObject);
begin
  MigrationConfig.Free;
end;

procedure TWindowMain.FormActivate(Sender: TObject);
begin
  LoadConfigs;
  LoadAdminConfigs;
  RadioGroupMethodClick(Self);
  RadioGroupConnMethodClick(Self);
end;

procedure TWindowMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveConfigs;
  SaveAdminConfigs;
end;

/////////////
//MIGRATION//
/////////////

procedure TWindowMain.LoadConfigs;
begin
  var Config := TMigrationConfig.Create;

  TConfig.GetGeral(Config);

  with Config.Source do
  begin
    TxtUserSource.Text := User;
    TxtPasswordSource.Text := Password;
    TxtDbSource.Text := Database;
    BoxVersionSource.ItemIndex := Integer(Version);
  end;

  with Config.Dest do
  begin
    TxtDbDest.Text := Database;
    BoxVersionDest.ItemIndex := Integer(Version);
  end;
end;

procedure TWindowMain.SaveConfigs;
begin
  var Config := TMigrationConfig.Create;

  with Config.Source do
  begin
    User := TxtUserSource.Text;
    Password := TxtPasswordSource.Text;
    Database := TxtDbSource.Text;
    Version := TVersion(BoxVersionSource.ItemIndex);
  end;

  with Config.Dest do
  begin
    Database := TxtDbDest.Text;
    Version := TVersion(BoxVersionDest.ItemIndex);
  end;

  TConfig.SetGeral(Config);

  Config.Free;
end;


procedure TWindowMain.BtnTestConnClick(Sender: TObject);
var
  FBDriverLink: TFDPhysFBDriverLink;
  ConnTest: TFDConnection;
begin
  BtnTestConn.Enabled := false;

  with MigrationConfig.Source do
  begin
    User := TxtUserSource.Text;
    Password := TxtPasswordSource.Text;
    Version := TVersion(BoxVersionSource.ItemIndex);
    Database := TxtDbSource.Text;
  end;

  FBDriverLink := TFDPhysFBDriverLink.Create(self);

  ConnTest := TFDConnection.Create(self);

  try
    FBDriverLink.Embedded := true;
    FBDriverLink.VendorLib := MigrationConfig.GetPathSourceDll;
    FBDriverLink.DriverID := 'FB';

    ConnTest.DriverName := 'FB';

    with TFDPhysFBConnectionDefParams(ConnTest.Params) do
    begin
      UserName := TxtUserSource.Text;
      Password := TxtPasswordSource.Text;
      Database := TxtDbSource.Text;
      Protocol := ipLocal;
    end;

    try
      ConnTest.Open;

      ShowMessage('Conex�o Ok!');
    Except on E: Exception do
    begin
      ShowMessage('Erro: ' + E.Message);
    end;
    end;
  finally
    ConnTest.Close;
    FreeAndNil(ConnTest);
    FBDriverLink.Release;
    FreeAndNil(FBDriverLink);
    BtnTestConn.Enabled := true;
  end;
end;

procedure TWindowMain.ActMigrateExecute(Sender: TObject);
var
  Migration: TMigration;
begin
  SaveConfigs;

  MemoLog.Clear;
  MemoErrors.Clear;

  try
    with MigrationConfig.Source do
    begin
      User := TxtUserSource.Text;
      Password := TxtPasswordSource.Text;
      Version := TVersion(BoxVersionSource.ItemIndex);
      Database := TxtDbSource.Text;
    end;

    with MigrationConfig.Dest do
    begin
      Version := TVersion(BoxVersionDest.ItemIndex);
      Database := TxtDbDest.Text;
    end;

    Migration := TMigration.Create(MigrationConfig);

    Migration.Migrate(MemoLog, MemoErrors);
  finally
    Migration.Free;
  end;
end;

/////////////
//ADMIN//////
/////////////

procedure TWindowMain.LoadAdminConfigs;
var
  Arq: TIniFile;
begin
  Arq := TIniFile.Create(TUtils.AppPath + 'Config.ini');

  try
    TxtDb.Text := Arq.ReadString('GENERAL', 'Database', '');
    TxtUser.Text := Arq.ReadString('GENERAL', 'User', 'SYSDBA');
    TxtPassword.Text := Arq.ReadString('GENERAL', 'Password', 'masterkey');
    RadioGroupConnMethod.ItemIndex := Arq.ReadString('GENERAL', 'ConnMethod', '0').ToInteger;
    BoxProtocol.ItemIndex := Arq.ReadString('GENERAL', 'Protocol', '1').ToInteger;
    TxtHost.Text := Arq.ReadString('GENERAL', 'Host', 'localhost');
    TxtPort.Text := Arq.ReadString('GENERAL', 'Port', '3050');
    TxtDll.Text := Arq.ReadString('GENERAL', 'Dll', '');
    TxtBackupFile.Text := Arq.ReadString('GENERAL', 'BackupFile', '');
  finally
    Arq.Free;
  end;
end;

procedure TWindowMain.SaveAdminConfigs;
var
  Arq: TIniFile;
begin
  Arq := TIniFile.Create(TUtils.AppPath + 'Config.ini');

  try
    Arq.WriteString('GENERAL', 'Database', TxtDb.Text);
    Arq.WriteString('GENERAL', 'User', TxtUser.Text);
    Arq.WriteString('GENERAL', 'Password', TxtPassword.Text);
    Arq.WriteString('GENERAL', 'ConnMethod', RadioGroupConnMethod.ItemIndex.ToString);
    Arq.WriteString('GENERAL', 'Protocol', BoxProtocol.ItemIndex.ToString);
    Arq.WriteString('GENERAL', 'Host', TxtHost.Text);
    Arq.WriteString('GENERAL', 'Port', TxtPort.Text);
    Arq.WriteString('GENERAL', 'Dll', TxtDll.Text);
    Arq.WriteString('GENERAL', 'BackupFile', TxtBackupFile.Text);
  finally
    Arq.Free;
  end;
end;

procedure TWindowMain.CopyFirebirdMsg;
var
  Arq: string;
begin
  Arq := ExtractFilePath(TxtDll.Text) + 'Firebird.msg';

  if FileExists(Arq) then
  begin
    CopyFile(PWideChar(Arq), PWideChar(ExtractFilePath(Application.ExeName) + 'Firebird.msg'), false);
  end;
end;

procedure TWindowMain.RadioGroupConnMethodClick(Sender: TObject);
begin
  case RadioGroupConnMethod.ItemIndex of
  0:
  begin
    BoxProtocol.Enabled := true;
    TxtHost.Enabled := true;
    TxtPort.Enabled := true;
//    TxtDll.Enabled := false;
  end;

  1:
  begin
    BoxProtocol.Enabled := false;
    TxtHost.Enabled := false;
    TxtPort.Enabled := false;
    TxtDll.Enabled := true;
  end;

  end;
end;

procedure TWindowMain.RadioGroupMethodClick(Sender: TObject);
begin
  case RadioGroupMethod.ItemIndex of
  0:
  begin
    with CheckListOptions.Items do
    begin
      Clear;

      Add('boIgnoreChecksum');
      Add('boIgnoreLimbo');
      Add('boMetadataOnly');
      Add('boNoGarbageCollect');
      Add('boOldDescriptions');
      Add('boNonTransportable');
      Add('boConvert');
      Add('boExpand');
    end;
  end;

  1:
  begin
    with CheckListOptions.Items do
    begin
      Clear;

      Add('roDeactivateIdx');
      Add('roNoShadow');
      Add('roNoValidity');
      Add('roOneAtATime');
      Add('roReplace');
      Add('roUseAllSpace');
      Add('roValidate');
      Add('roFixFSSData');
      Add('roFixFSSMetaData');
      Add('roMetaDataOnly');
    end;
  end;

  end;
end;

procedure TWindowMain.TxtDbBtnClick(Sender: TObject);
begin
  case RadioGroupMethod.ItemIndex of
  0:
    OpenFileFB(Sender);
  1:
    SaveFileFB(Sender);
  end;
end;

procedure TWindowMain.TxtBackupFileBtnClick(Sender: TObject);
begin
  case RadioGroupMethod.ItemIndex of
  0:
    SaveFileFBK(Sender);
  1:
    OpenFileFBK(Sender);
  end;
end;

procedure TWindowMain.TxtDllBtnClick(Sender: TObject);
begin
  OpenFileDLL(Sender);
end;

procedure TWindowMain.BtnStartClick(Sender: TObject);
begin
  case RadioGroupMethod.ItemIndex of
  0:
    ActBackup.Execute;
  1:
    ActRestore.Execute;
  end;
end;

procedure TWindowMain.ActBackupExecute(Sender: TObject);
var
  I: integer;
  FBDriverLink: TFDPhysFBDriverLink;
begin
  Page.ActivePageIndex := 0;

  TabAdmin.Enabled := false;

  MemoLogAdmin.Clear;

  Application.ProcessMessages;

  FBDriverLink := TFDPhysFBDriverLink.Create(nil);

  try
    FBBackup.Database := TxtDb.Text;
    FBBackup.UserName := TxtUser.Text;
    FBBackup.Password := TxtPassword.Text;

    FBBackup.BackupFiles.Clear;
    FBBackup.BackupFiles.Text := TxtBackupFile.Text;

    //TCPIP
    case RadioGroupConnMethod.ItemIndex of
    0:
    begin
      FBDriverLink.Embedded := false;

      FBDriverLink.VendorLib := TxtDll.Text;

      FBBackup.Protocol := TIBProtocol(BoxProtocol.ItemIndex);
      FBBackup.Host := TxtHost.Text;
      FBBackup.Port := StrToInt(TxtPort.Text);
    end;
    //EMBEDDED
    1:
    begin
      FBDriverLink.Embedded := true;

      FBDriverLink.VendorLib := TxtDll.Text;

      FBBackup.Protocol := ipLocal;

//      CopyFirebirdMsg;
    end;

    end;

    FBBackup.DriverLink := FBDriverLink;

    FBBackup.Verbose := CheckVerbose.Checked;
    FBBackup.Options := [];

    for I := 0 to CheckListOptions.Count - 1 do
    begin
      if CheckListOptions.Checked[I] then
      begin
        case I of
        0: FBBackup.Options := FBBackup.Options + [boIgnoreChecksum];
        1: FBBackup.Options := FBBackup.Options + [boIgnoreLimbo];
        2: FBBackup.Options := FBBackup.Options + [boMetadataOnly];
        3: FBBackup.Options := FBBackup.Options + [boNoGarbageCollect];
        4: FBBackup.Options := FBBackup.Options + [boOldDescriptions];
        5: FBBackup.Options := FBBackup.Options + [boNonTransportable];
        6: FBBackup.Options := FBBackup.Options + [boConvert];
        7: FBBackup.Options := FBBackup.Options + [boExpand];
        end;
      end;
    end;

    FBBackup.Backup;
  finally
    TabAdmin.Enabled := true;
    FBDriverLink.Free;
  end;
end;

procedure TWindowMain.ActRestoreExecute(Sender: TObject);
var
  I: integer;
  FBDriverLink: TFDPhysFBDriverLink;
begin
  Page.ActivePageIndex := 0;

  TabAdmin.Enabled := false;

  MemoLogAdmin.Clear;

  Application.ProcessMessages;

  FBDriverLink := TFDPhysFBDriverLink.Create(nil);

  try
    FBRestore.Database := TxtDb.Text;
    FBRestore.UserName := TxtUser.Text;
    FBRestore.Password := TxtPassword.Text;

    FBRestore.BackupFiles.Clear;
    FBRestore.BackupFiles.Text := TxtBackupFile.Text;

    case RadioGroupConnMethod.ItemIndex of
    0:
    begin
      FBDriverLink.Embedded := false;

      FBRestore.Protocol := TIBProtocol(BoxProtocol.ItemIndex);
      FBRestore.Host := TxtHost.Text;
      FBRestore.Port := StrToInt(TxtPort.Text);
    end;

    1:
    begin
      FBDriverLink.Embedded := true;

      FBDriverLink.VendorLib := TxtDll.Text;

      FBRestore.Protocol := ipLocal;

//      CopyFirebirdMsg;
    end;

    end;

    FBRestore.DriverLink := FBDriverLink;

    FBRestore.Verbose := CheckVerbose.Checked;
    FBRestore.Options := [];

    for I := 0 to CheckListOptions.Count - 1 do
    begin
      if CheckListOptions.Checked[I] then
      begin
        case I of
        0: FBRestore.Options := FBRestore.Options + [roDeactivateIdx];
        1: FBRestore.Options := FBRestore.Options + [roNoShadow];
        2: FBRestore.Options := FBRestore.Options + [roNoValidity];
        3: FBRestore.Options := FBRestore.Options + [roOneAtATime];
        4: FBRestore.Options := FBRestore.Options + [roReplace];
        5: FBRestore.Options := FBRestore.Options + [roUseAllSpace];
        6: FBRestore.Options := FBRestore.Options + [roValidate];
        7: FBRestore.Options := FBRestore.Options + [roFixFSSData];
        8: FBRestore.Options := FBRestore.Options + [roFixFSSMetaData];
        9: FBRestore.Options := FBRestore.Options + [roMetaDataOnly];
        end;
      end;
    end;

    FBRestore.Restore;
  finally
    TabAdmin.Enabled := true;
    FBDriverLink.Free;
  end;
end;

procedure TWindowMain.FBProgress(ASender: TFDPhysDriverService; const AMessage: string);
begin
  WindowMain.MemoLogAdmin.Lines.Add(AMessage);
end;

procedure TWindowMain.FBError(ASender, AInitiator: TObject; var AException: Exception);
begin
  WindowMain.MemoLogAdmin.Lines.Add(AException.Message);
end;

//OTHERS

//Load
procedure TWindowMain.OpenFileAll(Sender: TObject);
var
  FileName: string;
begin
  if TUTils.OpenFileAll(FileName) then
    (Sender as TNsEditBtn).Text := FileName;
end;

procedure TWindowMain.OpenFile(Sender: TObject; DisplayName, FileMask: string; IncludeAllFiles: boolean);
var
  FileName: string;
begin
  if TUTils.OpenFile(DisplayName, FileMask, IncludeAllFiles, FileName) then
    (Sender as TNsEditBtn).Text := FileName;
end;

procedure TWindowMain.OpenFileFB(Sender: TObject);
begin
  OpenFile(Sender, 'Firebird Database (*.FDB)', '*.FDB', true);
end;

procedure TWindowMain.OpenFileFBK(Sender: TObject);
begin
  OpenFile(Sender, 'Firebird Backup (*.FBK)', '*.FBK', true);
end;

procedure TWindowMain.OpenFileDLL(Sender: TObject);
begin
  OpenFile(Sender, 'Dynamic Link Library (*.DLL)', '*.DLL', true);
end;

procedure TWindowMain.OpenFolder(Sender: TObject);
var
  FileName: string;
begin
  if TUTils.OpenFolder(FileName) then
    (Sender as TNsEditBtn).Text := FileName;
end;

//Save
procedure TWindowMain.SaveFile(Sender: TObject; DisplayName, FileMask: string; IncludeAllFiles: boolean);
var
  FileName: string;
begin
  if TUTils.SaveFile(DisplayName, FileMask, IncludeAllFiles, FileName) then
    (Sender as TNsEditBtn).Text := FileName;
end;

procedure TWindowMain.SaveFileFB(Sender: TObject);
begin
  SaveFile(Sender, 'Firebird Database (*.FDB)', '*.FDB', false);
end;

procedure TWindowMain.SaveFileFBK(Sender: TObject);
begin
  SaveFile(Sender, 'Firebird Backup (*.FBK)', '*.FBK', true);
end;

procedure TWindowMain.SaveFolder(Sender: TObject);
var
  FileName: string;
begin
  if TUTils.SaveFolder(FileName) then
    (Sender as TNsEditBtn).Text := FileName;
end;

procedure TWindowMain.ActEscExecute(Sender: TObject);
begin
  Close;
end;

end.
