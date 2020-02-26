unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, DirectoryWatcherBuilder,
  DirectoryWatcherAPI, DirectoryWatcher;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Button3: TButton;
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    procedure OnFileEvent(const FilePath: String; const EventType: TDirectoryEventType);
  public
    { Public declarations }
    DirectoryWatcher:IDirectoryWatcher;
  end;

var
  Form1: TForm1;

implementation
{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
begin
  DirectoryWatcher.Start;
end;

procedure TForm1.Button2Click(Sender: TObject);
var

  FolderToWatch:String;
begin
  FolderToWatch := 'C:\techpartner\xxx';
  DirectoryWatcher := TDirectoryWatcherBuilder
                      .New
                      .WatchDirectory(FolderToWatch)
                      .Recursively(True)
                      .OnChangeTrigger(OnFileEvent)
                      .Build;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  DirectoryWatcher := nil;
end;

procedure TForm1.OnFileEvent(const FilePath: String;
  const EventType: TDirectoryEventType);
var
  EventTypeString: String;
begin
  Memo1.Lines.Add('======NEW EVENT======');
  Memo1.Lines.Add('File: ' + FilePath);

  case EventType of
    detAdded: EventTypeString := 'ADDED';
    detRemoved: EventTypeString := 'REMOVED';
    detModified: EventTypeString := 'MODIFIED';
  end;

  Memo1.Lines.Add('Type: ' + EventTypeString);
  Memo1.Lines.Add('');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('');
  Memo1.Lines.Add('');
end;
end.
