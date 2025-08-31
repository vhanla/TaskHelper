# TaskHelper

TaskHelper is a command-line utility for Windows designed to simplify the management of scheduled tasks. Its primary purpose is to allow applications that require administrator privileges to run at startup without triggering a User Account Control (UAC) prompt every time.

## The Problem

When you add a program that needs elevation to the Windows startup folder, you are greeted with a UAC prompt on every boot. This can be annoying and disrupt a smooth startup experience.

## How It Works

TaskHelper leverages the Windows Task Scheduler to create a task that runs with the highest privileges. By setting up a scheduled task to run at user logon, the application can start automatically without requiring a UAC prompt. This tool provides a simple command-line interface to create and manage these tasks.

## Usage

TaskHelper is a console application. You can use it from `cmd.exe` or `PowerShell`.

### Add a new task

To create a new scheduled task that runs a program at startup:

```
TaskHelper.exe add <TaskName> <ProgramPath> [Arguments]
```

- `<TaskName>`: The name you want to give to the task (e.g., "My-App-Startup").
- `<ProgramPath>`: The full path to the executable you want to run (e.g., "C:\Program Files\MyApp\MyApp.exe").
- `[Arguments]`: (Optional) Any command-line arguments the program needs.

### Remove a task

To remove a previously created task:

```
TaskHelper.exe remove <TaskName>
```

- `<TaskName>`: The name of the task you want to remove.

### List tasks

To list all tasks created with TaskHelper:

```
TaskHelper.exe list
```

## Examples

### Adding a task

Suppose you want to run `C:\Tools\MyUtil.exe` at startup, and it requires administrator privileges. You can create a task named "MyUtilStartup" like this:

```
TaskHelper.exe add "MyUtilStartup" "C:\Tools\MyUtil.exe"
```

### Adding a task with arguments

If your program needs arguments, you can add them at the end:

```
TaskHelper.exe add "My-App" "C:\Path\To\App.exe" --silent --run-as-service
```

### Removing a task

To remove the "MyUtilStartup" task:

```
TaskHelper.exe remove "MyUtilStartup"
```

## Building from Source

This project is written in Delphi. To build it, you will need:

- A recent version of Embarcadero Delphi.
- Open the `TaskHelper.dproj` file in the IDE.
- Build the project for the Win32 or Win64 platform.

## License

This project is open-source. Please refer to the license file for more details.
