program TaskHelper;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Winapi.ActiveX,
  ComObj,
  Winapi.Windows,
  System.Variants,
  TaskScheduler_TLB;

procedure CreateElevatedStartupTask(const TaskName, AppPath: string);
var
  TaskService: ITaskService;
  RootFolder: ITaskFolder;
  TaskDef: ITaskDefinition;
  LogonTrigger: ILogonTrigger;
  Action: IExecAction;
begin
  CoInitialize(nil);
  try
    // Create the main Task Scheduler service object
    OleCheck(CoCreateInstance(CLASS_TaskScheduler_, nil, CLSCTX_INPROC_SERVER, IID_ITaskService, TaskService));
    TaskService.Connect(EmptyParam, EmptyParam, EmptyParam, EmptyParam);
    RootFolder := TaskService.GetFolder('\');

    // If task already exists, delete it first to ensure a clean state
    try
      RootFolder.DeleteTask(TaskName, 0);
    except
      // Ignore "not found" errors, but raise others
      on E: EOleException do
        if E.ErrorCode <> HRESULT($80070002) then raise; // $80070002 is HRESULT for "file not found"
    end;

    // Create a new task definition
    TaskDef := TaskService.NewTask(0);

    // --- Principal Settings (for elevation) ---
    TaskDef.Principal.RunLevel := TASK_RUNLEVEL_HIGHEST; // Correct constant

    // --- Settings ---
    TaskDef.Settings.Enabled := True;
    TaskDef.Settings.Hidden := False;
    TaskDef.Settings.StopIfGoingOnBatteries := False;
    TaskDef.Settings.DisallowStartIfOnBatteries := False;

    // --- Trigger (Run at user logon) ---
    LogonTrigger := TaskDef.Triggers.Create(TASK_TRIGGER_LOGON) as ILogonTrigger;
    LogonTrigger.Id := 'LogonTrigger';
    // Optional: You could specify a user ID with LogonTrigger.UserId := 'S-1-5-...';
    // If UserId is not set, it applies to any user logging on.

    // --- Action (What to run) ---
    Action := TaskDef.Actions.Create(TASK_ACTION_EXEC) as IExecAction;
    Action.Path := AppPath;

    // --- Register the Task ---
    // The parameters are now correct for a task that runs for the interactive user.
    RootFolder.RegisterTaskDefinition(
      TaskName,
      TaskDef,
      TASK_CREATE_OR_UPDATE,
      '', // UserID - Empty for interactive user token
      '', // Password - Empty
      TASK_LOGON_INTERACTIVE_TOKEN,
      '' // Sddl
    );

    Writeln('Task "', TaskName, '" installed successfully for "', AppPath, '"');
  finally
    CoUninitialize;
  end;
end;

//procedure CreateElevatedStartupTask2(const TaskName, AppPath: string);
//var
//  TaskService, RootFolder, TaskDef, LogonTrigger, Action: OleVariant;
//begin
//  CoInitialize(nil);
//  try
//    TaskService := CreateOleObject('Schedule.Service');
//    TaskService.Connect;
//    RootFolder := TaskService.GetFolder('\');
//
//    // If task already exists, delete it first
//    try
//      RootFolder.DeleteTask(TaskName, 0);
//    except
//      // ignore if not found
//    end;
//
//    TaskDef := TaskService.NewTask(0);
//    TaskDef.Settings.Enabled := True;
//    TaskDef.Settings.Hidden := False;
//    TaskDef.Principal.RunLevel := 1; // TASK_RUNLEVEL_HIGHEST
//
//    LogonTrigger := TaskDef.Triggers.Create(1); // TASK_TRIGGER_LOGON
//    LogonTrigger.Id := 'LogonTrigger';
//
//    Action := TaskDef.Actions.Create(0); // TASK_ACTION_EXEC
//    Action.Path := AppPath;
//
//    RootFolder.RegisterTaskDefinition(
//      TaskName,
//      TaskDef,
//      6, // TASK_CREATE_OR_UPDATE | TASK_LOGON_INTERACTIVE_TOKEN
//      '', '', 3, // TASK_LOGON_INTERACTIVE_TOKEN
//      ''
//    );
//    Writeln('Task "', TaskName, '" installed for "', AppPath, '"');
//  finally
//    CoUninitialize;
//  end;
//end;

procedure DeleteTask(const TaskName: string);
var
  TaskService: ITaskService;
  RootFolder: ITaskFolder;
begin
  CoInitialize(nil);
  try
    OleCheck(CoCreateInstance(CLASS_TaskScheduler_, nil, CLSCTX_INPROC_SERVER, IID_ITaskService, TaskService));
    TaskService.Connect(EmptyParam, EmptyParam, EmptyParam, EmptyParam);
    RootFolder := TaskService.GetFolder('\');
    RootFolder.DeleteTask(TaskName, 0);
    Writeln('Task "', TaskName, '" removed successfully.');
  finally
    CoUninitialize;
  end;
end;

//procedure DeleteTask_(const TaskName: string);
//var
//  TaskService, RootFolder: OleVariant;
//begin
//  CoInitialize(nil);
//  try
//    TaskService := CreateOleObject('Schedule.Service');
//    TaskService.Connect;
//    RootFolder := TaskService.GetFolder('\');
//    RootFolder.DeleteTask(TaskName, 0);
//    Writeln('Task "', TaskName, '" removed.');
//  finally
//    CoUninitialize;
//  end;
//end;

procedure CheckTask(const TaskName: string);
var
  TaskService, RootFolder, Task, Actions, Action: OleVariant;
  Count: Integer;
begin
  CoInitialize(nil);
  try
    TaskService := CreateOleObject('Schedule.Service');
    TaskService.Connect;
    RootFolder := TaskService.GetFolder('\');

    try
      Task := RootFolder.GetTask(TaskName);
      Writeln('Task "', TaskName, '" exists.');

      Actions := Task.Definition.Actions;
      Count := Actions.Count;

      if Count > 0 then
      begin
        Action := Actions.Item(1); // 1-based
        Writeln('  Path     : ', Action.Path);
      end
      else
        Writeln('  Path     : <No action defined>');

      Writeln('  Enabled  : ', BoolToStr(Task.Enabled, True));
      Writeln('  Hidden   : ', BoolToStr(Task.Definition.Settings.Hidden, True));
      Writeln('  RunLevel : ', Task.Definition.Principal.RunLevel);
    except
      on E: Exception do
        Writeln('Task "', TaskName, '" not found. (', E.Message, ')');
    end;
  finally
    CoUninitialize;
  end;
end;

procedure ListTasks;
var
  TaskService, RootFolder, Tasks, Task: OleVariant;
  I, Count: Integer;
  TaskDisp: IDispatch;
begin
  CoInitialize(nil);
  try
    TaskService := CreateOleObject('Schedule.Service');
    TaskService.Connect;
    RootFolder := TaskService.GetFolder('\');

    Tasks := RootFolder.GetTasks(0);
    Count := Tasks.Count;

    if Count = 0 then
    begin
      Writeln('No scheduled tasks found.');
      Exit;
    end;

    Writeln('Scheduled tasks:');
    for I := 1 to Count do // 1-based
    begin
      TaskDisp := IDispatch(Tasks.Item[I]);
      Task := TaskDisp;
      Writeln('  ', Task.Name, '  [Enabled=', BoolToStr(Task.Enabled, True), ']');
    end;
  finally
    CoUninitialize;
  end;
end;

procedure ShowHelp;
begin
  Writeln('TaskHelper - Manage elevated startup tasks');
  Writeln('Usage:');
  Writeln('  TaskHelper.exe --install "<AppPath>" "<TaskName>"');
  Writeln('  TaskHelper.exe --remove "<TaskName>"');
  Writeln('  TaskHelper.exe --check  "<TaskName>"');
  Writeln('  TaskHelper.exe --list');
  Writeln;
  Writeln('Examples:');
  Writeln('  TaskHelper.exe --install "C:\MyApp\MyApp.exe" "MyElevatedApp"');
  Writeln('  TaskHelper.exe --remove "MyElevatedApp"');
  Writeln('  TaskHelper.exe --check  "MyElevatedApp"');
  Writeln('  TaskHelper.exe --list');
end;

begin
  try
//    ListTasks;
    if ParamCount < 1 then
    begin
      ShowHelp;
      Exit;
    end;

    if SameText(ParamStr(1), '--install') then
    begin
      if ParamCount < 3 then
      begin
        Writeln('Error: Missing arguments for --install');
        ShowHelp;
        Exit;
      end;
      CreateElevatedStartupTask(ParamStr(3), ParamStr(2));
    end
    else if SameText(ParamStr(1), '--remove') then
    begin
      if ParamCount < 2 then
      begin
        Writeln('Error: Missing arguments for --remove');
        ShowHelp;
        Exit;
      end;
      DeleteTask(ParamStr(2));
    end
    else if SameText(ParamStr(1), '--check') then
    begin
      if ParamCount < 2 then
      begin
        Writeln('Error: Missing arguments for --check');
        ShowHelp;
        Exit;
      end;
      CheckTask(ParamStr(2));
    end
    else if SameText(ParamStr(1), '--list') then
    begin
      ListTasks;
    end
    else
      ShowHelp;

  except
    on E: Exception do
      Writeln('Error: ', E.Message);
  end;
end.

