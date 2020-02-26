unit EventTriggerThread;

interface

{$IFDEF FPC}{$MODE DELPHI}{$ENDIF}

uses
  SysUtils, Classes, SyncObjs, System.Generics.Collections, DirectoryWatcherAPI;

type
  TEventTriggerThread = class(TThread)
  private type
    TEventTypeList = TList<TDirectoryEventType>;
  private
    FOnDirectoryEvent: TDirectoryEvent;
    FStoredEvents: TDictionary<String, TEventTypeList>;
    FStoredEventsAux: TList<String>;
    FCriticalSection: TCriticalSection;
    procedure RemoveEventsForIndex(const Idx: Integer);
    procedure TriggerEvents;
    procedure TriggerEventsForIndex(const Idx: Integer);
    procedure RemoveDuplicateModifiedEvents(const EventTypeList
      : TEventTypeList);
    procedure TriggerEventsForFile(const FilePath: String;
      const EventTypeList: TEventTypeList);
  protected
    procedure Execute; override;
  public
    constructor Create(const OnDirectoryEvent: TDirectoryEvent);
    destructor Destroy; override;
    procedure EnqueueEvent(const FilePath: String;
      EventType: TDirectoryEventType);
  end;

implementation

constructor TEventTriggerThread.Create(const OnDirectoryEvent: TDirectoryEvent);
begin
  inherited Create(True);
  FreeOnTerminate := False;
  FOnDirectoryEvent := OnDirectoryEvent;
  FCriticalSection := TCriticalSection.Create;
  FStoredEvents := TDictionary<String, TEventTypeList>.Create;
  FStoredEventsAux := TList<String>.Create;
end;

destructor TEventTriggerThread.Destroy;
var
  I: Integer;
begin
  for I := FStoredEvents.Count - 1 downto 0 do
    RemoveEventsForIndex(I);

  FStoredEvents.Free;
  FStoredEventsAux.Free;
  FCriticalSection.Free;
  inherited;
end;

procedure TEventTriggerThread.Execute;
const
  INTERVALL = 50;
begin
  while not Terminated do
  begin
    Sleep(INTERVALL);
    FCriticalSection.Enter;
    try
      TriggerEvents;
    finally
      FCriticalSection.Leave;
    end;
  end;
end;

procedure TEventTriggerThread.EnqueueEvent(const FilePath: String;
  EventType: TDirectoryEventType);
var
  EventTypeList: TEventTypeList;
begin
  FCriticalSection.Enter;
  try
    if not FStoredEvents.TryGetValue(FilePath, EventTypeList) then
    begin
      EventTypeList := TEventTypeList.Create;
      FStoredEvents.Add(FilePath, EventTypeList);
      FStoredEventsAux.Add(FilePath);
    end;

    EventTypeList.Add(EventType);
  finally
    FCriticalSection.Leave;
  end;
end;

procedure TEventTriggerThread.RemoveEventsForIndex(const Idx: Integer);
var
  key:String;
begin
  key := FStoredEventsAux.Items[idx];
  FStoredEvents.Items[key].Free;
  FStoredEvents.Remove(key);
  FStoredEventsAux.Delete(idx);
end;

procedure TEventTriggerThread.TriggerEvents;
begin
  while FStoredEvents.Count > 0 do
  begin
    TriggerEventsForIndex(0);
    RemoveEventsForIndex(0);
  end;
end;

procedure TEventTriggerThread.TriggerEventsForIndex(const Idx: Integer);
var
  EventTypeList: TEventTypeList;
  FilePath: String;
  key:String;
begin
  key := FStoredEventsAux.Items[Idx];
  FilePath := key;
  EventTypeList := FStoredEvents.Items[key];
  RemoveDuplicateModifiedEvents(EventTypeList);
  TriggerEventsForFile(FilePath, EventTypeList);
end;

procedure TEventTriggerThread.RemoveDuplicateModifiedEvents(const EventTypeList: TEventTypeList);
var
  I: Integer;
  ModifiedEventFound: Boolean;
begin
  ModifiedEventFound := False;
  for I := EventTypeList.Count - 1 downto 0 do
    if EventTypeList[I] = detModified then
      if ModifiedEventFound then
        EventTypeList.Delete(I)
      else
        ModifiedEventFound := True;
end;

procedure TEventTriggerThread.TriggerEventsForFile(const FilePath: String; const EventTypeList: TEventTypeList);
var
  EventType: TDirectoryEventType;
begin
  for EventType in EventTypeList do
    FOnDirectoryEvent(FilePath, EventType);
end;

end.
