; Cosmius Hermes Inno Setup script
; MODIFIED: uses installer\app_icon.ico for Setup and shortcuts.
; MODIFIED: installs under the current user's LocalAppData to avoid admin rights.
; MODIFIED: creates only per-user shortcuts so the app can run without elevation.

#ifndef RepoRoot
  #define RepoRoot AddBackslash(SourcePath) + ".."
#endif

#ifndef SourceDir
  #define SourceDir RepoRoot
#endif

#ifndef OutputDir
  #define OutputDir AddBackslash(RepoRoot) + "dist"
#endif

#ifndef OutputBaseName
  #define OutputBaseName "CosmiusHermes-Setup"
#endif

#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

#define MyAppName "Cosmius Hermes"
#define MyAppPublisher "Cosmius"
#define MyAppExeName "CosmiusHermes.exe"
; MODIFIED: requested relative icon path.
#define AppIconRelativePath "installer\app_icon.ico"
#define AppIconSourcePath AddBackslash(RepoRoot) + AppIconRelativePath
; MODIFIED: keep repository metadata and local user data out of the installer payload.
#define PayloadExcludes ".git\*,installer\*,dist\*,data\*,chat_history\*,conversations\*,user_data\*,history\*,runtime\temp\*,.env,.env.*,*.key,config.local.json,*.log,*.db,*.sqlite,*.sqlite3"

[Setup]
AppId={{C6F2B8F8-1CEB-48C8-9D3B-DBAF0D4C4E8F}
AppName={#MyAppName}
AppVersion={#AppVersion}
AppVerName={#MyAppName} {#AppVersion}
AppPublisher={#MyAppPublisher}
; MODIFIED: per-user writable install directory; no Program Files permission issues.
DefaultDirName={localappdata}\CosmiusHermes
DisableDirPage=no
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=no
AllowNoIcons=yes
OutputDir={#OutputDir}
OutputBaseFilename={#OutputBaseName}
; MODIFIED: Setup executable icon uses installer\app_icon.ico.
SetupIconFile={#AppIconSourcePath}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
; MODIFIED: do not request administrator privileges.
PrivilegesRequired=lowest
UninstallDisplayIcon={app}\app_icon.ico
SetupLogging=yes
CloseApplications=yes
RestartIfNeededByRun=no
DirExistsWarning=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; MODIFIED: per-user desktop shortcut option, enabled by default on first install.
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: checkedonce

[Files]
; MODIFIED: excludes local data, secrets, logs, Git metadata, and installer build artifacts.
Source: "{#SourceDir}\*"; DestDir: "{app}"; Excludes: "{#PayloadExcludes}"; Flags: ignoreversion recursesubdirs createallsubdirs
; MODIFIED: install the same icon so shortcuts can reference it reliably.
Source: "{#AppIconSourcePath}"; DestDir: "{app}"; DestName: "app_icon.ico"; Flags: ignoreversion

[InstallDelete]
Type: filesandordirs; Name: "{app}\chat_history"
Type: filesandordirs; Name: "{app}\conversations"
Type: filesandordirs; Name: "{app}\user_data"
Type: filesandordirs; Name: "{app}\history"
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{app}\runtime\temp"
Type: files; Name: "{app}\.env"
Type: files; Name: "{app}\config.local.json"
Type: files; Name: "{app}\*.key"
Type: files; Name: "{app}\*.log"

[Dirs]
Name: "{userappdata}\CosmiusHermes\data"
Name: "{userappdata}\CosmiusHermes\config"

[Icons]
; MODIFIED: per-user Start Menu shortcut with app_icon.ico.
Name: "{userprograms}\Cosmius Hermes"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"
; MODIFIED: per-user Desktop shortcut with app_icon.ico.
Name: "{userdesktop}\Cosmius Hermes"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; IconFilename: "{app}\app_icon.ico"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#MyAppName}}"; Flags: nowait postinstall skipifsilent unchecked

[Code]
procedure EnsureDirExists(Path: String);
begin
  if not DirExists(Path) then
    ForceDirectories(Path);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    EnsureDirExists(ExpandConstant('{userappdata}\CosmiusHermes\data'));
    EnsureDirExists(ExpandConstant('{userappdata}\CosmiusHermes\config'));
  end;
end;
