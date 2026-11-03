<# :
@echo off
set "SAM_SOURCE=%~f0"
start "" powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create((Get-Content -LiteralPath $env:SAM_SOURCE -Raw)))"
exit /b
#>
param([switch]$Watch)

$ErrorActionPreference = 'Stop'
$installDir = Join-Path $env:LOCALAPPDATA 'SonarAppMuter'
$installedScript = Join-Path $installDir 'SonarAppMuter.ps1'
$configPath = Join-Path $installDir 'config.json'
$logPath = Join-Path $installDir 'errors.log'
$shortcutPath = Join-Path ([Environment]::GetFolderPath('Startup')) 'Sonar App Muter.lnk'
$powershellPath = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$watchArguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installedScript`" -Watch"

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace SonarAppMuter
{
    [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
    class MMDeviceEnumeratorComObject { }

    [ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceEnumerator
    {
        int EnumAudioEndpoints(int dataFlow, int stateMask, out IMMDeviceCollection devices);
    }

    [ComImport, Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDeviceCollection
    {
        int GetCount(out int count);
        int Item(int index, out IMMDevice device);
    }

    [ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IMMDevice
    {
        int Activate(ref Guid iid, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object instance);
        int OpenPropertyStore(int access, out IPropertyStore store);
    }

    [ComImport, Guid("886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IPropertyStore
    {
        int GetCount(out int count);
        int GetAt(int index, out PropertyKey key);
        int GetValue(ref PropertyKey key, out PropVariant value);
    }

    [StructLayout(LayoutKind.Sequential)]
    struct PropertyKey
    {
        public Guid FormatId;
        public int PropertyId;
    }

    [StructLayout(LayoutKind.Explicit, Size = 24)]
    struct PropVariant
    {
        [FieldOffset(0)] public short VariantType;
        [FieldOffset(8)] public IntPtr Pointer;
    }

    [ComImport, Guid("77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionManager2
    {
        int GetAudioSessionControl(IntPtr sessionGuid, int flags, out IntPtr control);
        int GetSimpleAudioVolume(IntPtr sessionGuid, int flags, out IntPtr volume);
        int GetSessionEnumerator(out IAudioSessionEnumerator sessions);
    }

    [ComImport, Guid("E2F5BB11-0570-40CA-ACDD-3AA01277DEE8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionEnumerator
    {
        int GetCount(out int count);
        int GetSession(int index, out IAudioSessionControl2 session);
    }

    [ComImport, Guid("BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface IAudioSessionControl2
    {
        int GetState(out int state);
        int GetDisplayName(out IntPtr name);
        int SetDisplayName(IntPtr name, IntPtr eventContext);
        int GetIconPath(out IntPtr path);
        int SetIconPath(IntPtr path, IntPtr eventContext);
        int GetGroupingParam(out Guid groupingId);
        int SetGroupingParam(IntPtr groupingId, IntPtr eventContext);
        int RegisterAudioSessionNotification(IntPtr client);
        int UnregisterAudioSessionNotification(IntPtr client);
        int GetSessionIdentifier(out IntPtr id);
        int GetSessionInstanceIdentifier(out IntPtr id);
        int GetProcessId(out int processId);
    }

    [ComImport, Guid("87CE5498-68D6-44E5-9215-6DA47EF883D8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    interface ISimpleAudioVolume
    {
        int SetMasterVolume(float level, ref Guid eventContext);
        int GetMasterVolume(out float level);
    }

    public static class AudioSessions
    {
        [DllImport("ole32.dll")]
        static extern int PropVariantClear(ref PropVariant value);

        static IEnumerable<IMMDevice> ActiveRenderDevices()
        {
            var enumerator = (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();
            IMMDeviceCollection devices;
            Marshal.ThrowExceptionForHR(enumerator.EnumAudioEndpoints(0, 1, out devices));
            int count;
            Marshal.ThrowExceptionForHR(devices.GetCount(out count));
            for (int i = 0; i < count; i++)
            {
                IMMDevice device;
                Marshal.ThrowExceptionForHR(devices.Item(i, out device));
                yield return device;
            }
        }

        static IEnumerable<IAudioSessionControl2> Sessions(IMMDevice device)
        {
            var managerId = typeof(IAudioSessionManager2).GUID;
            object manager;
            Marshal.ThrowExceptionForHR(device.Activate(ref managerId, 23, IntPtr.Zero, out manager));
            IAudioSessionEnumerator sessions;
            Marshal.ThrowExceptionForHR(((IAudioSessionManager2)manager).GetSessionEnumerator(out sessions));
            int count;
            Marshal.ThrowExceptionForHR(sessions.GetCount(out count));
            for (int i = 0; i < count; i++)
            {
                IAudioSessionControl2 session;
                Marshal.ThrowExceptionForHR(sessions.GetSession(i, out session));
                yield return session;
            }
        }

        static string FriendlyName(IMMDevice device)
        {
            IPropertyStore store;
            Marshal.ThrowExceptionForHR(device.OpenPropertyStore(0, out store));
            var key = new PropertyKey { FormatId = new Guid("A45C254E-DF1C-4EFD-8020-67D146A850E0"), PropertyId = 14 };
            PropVariant value;
            Marshal.ThrowExceptionForHR(store.GetValue(ref key, out value));
            var name = Marshal.PtrToStringUni(value.Pointer);
            PropVariantClear(ref value);
            return name ?? string.Empty;
        }

        static string ProcessName(IAudioSessionControl2 session)
        {
            int processId;
            Marshal.ThrowExceptionForHR(session.GetProcessId(out processId));
            if (processId == 0)
                return null;
            try { return Process.GetProcessById(processId).ProcessName; }
            catch (ArgumentException) { return null; }
        }

        static bool Contains(string[] names, string name)
        {
            return Array.Exists(names, candidate => string.Equals(candidate, name, StringComparison.OrdinalIgnoreCase));
        }

        public static string[] DeviceNames()
        {
            var names = new List<string>();
            foreach (var device in ActiveRenderDevices())
                names.Add(FriendlyName(device));
            return names.ToArray();
        }

        public static string[] ProcessNames()
        {
            var names = new List<string>();
            foreach (var device in ActiveRenderDevices())
                foreach (var session in Sessions(device))
                {
                    var name = ProcessName(session);
                    if (name != null)
                        names.Add(name);
                }
            return names.ToArray();
        }

        public static void Mute(string[] deviceNames, string[] processNames)
        {
            foreach (var device in ActiveRenderDevices())
            {
                if (!Contains(deviceNames, FriendlyName(device)))
                    continue;
                foreach (var session in Sessions(device))
                {
                    var name = ProcessName(session);
                    if (name == null || !Contains(processNames, name))
                        continue;
                    var volume = (ISimpleAudioVolume)session;
                    float level;
                    Marshal.ThrowExceptionForHR(volume.GetMasterVolume(out level));
                    if (level == 0f)
                        continue;
                    var eventContext = Guid.Empty;
                    Marshal.ThrowExceptionForHR(volume.SetMasterVolume(0f, ref eventContext));
                }
            }
        }
    }
}
'@

if ($Watch) {
    $mutex = New-Object System.Threading.Mutex($false, 'Local\SonarAppMuterWatcher')
    if (-not $mutex.WaitOne(0)) { return }
    $lastError = $null
    while (Test-Path -LiteralPath $configPath) {
        try {
            $config = Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json
            [SonarAppMuter.AudioSessions]::Mute(@($config.Devices), @($config.Apps))
            $lastError = $null
        }
        catch {
            if ("$_" -ne $lastError) {
                $lastError = "$_"
                Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format s) $lastError"
            }
        }
        Start-Sleep -Seconds 3
    }
    return
}

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function New-Label($text) {
    New-Object System.Windows.Forms.Label -Property @{ Text = $text; AutoSize = $true; Margin = New-Object System.Windows.Forms.Padding(0, 8, 0, 4) }
}

function New-CheckedList($names, $checkedNames) {
    $list = New-Object System.Windows.Forms.CheckedListBox -Property @{ Dock = 'Fill'; CheckOnClick = $true; IntegralHeight = $false }
    foreach ($name in ($names | Where-Object { $_ } | Sort-Object -Unique)) { [void]$list.Items.Add($name, ($checkedNames -contains $name)) }
    $list
}

function Show-Message($text, $icon) {
    [void][System.Windows.Forms.MessageBox]::Show($text, 'Sonar App Muter', 'OK', $icon)
}

$saved = if (Test-Path -LiteralPath $configPath) { Get-Content -LiteralPath $configPath -Raw | ConvertFrom-Json }
$deviceNames = [SonarAppMuter.AudioSessions]::DeviceNames()
$checkedApps = if ($saved) { @($saved.Apps) } else { @('Discord') }
$checkedDevices = if ($saved) { @($saved.Devices) } else { @('Microphone', 'Stream') | ForEach-Object { "SteelSeries Sonar - $_ (SteelSeries Sonar Virtual Audio Device)" } }

$form = New-Object System.Windows.Forms.Form -Property @{
    Text = 'Sonar App Muter'
    ClientSize = New-Object System.Drawing.Size(460, 560)
    MinimumSize = New-Object System.Drawing.Size(360, 420)
    StartPosition = 'CenterScreen'
    Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
}

$appList = New-CheckedList (@($checkedApps) + [SonarAppMuter.AudioSessions]::ProcessNames()) $checkedApps
$deviceList = New-CheckedList (@($checkedDevices) + $deviceNames) $checkedDevices

$appInput = New-Object System.Windows.Forms.TextBox -Property @{ Dock = 'Fill' }
$addButton = New-Object System.Windows.Forms.Button -Property @{ Text = 'Add app'; AutoSize = $true }
$addRow = New-Object System.Windows.Forms.TableLayoutPanel -Property @{ Dock = 'Fill'; AutoSize = $true; ColumnCount = 2; Margin = New-Object System.Windows.Forms.Padding(0, 4, 0, 0) }
[void]$addRow.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('Percent', 100)))
[void]$addRow.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle('AutoSize')))
$addRow.Controls.Add($appInput, 0, 0)
$addRow.Controls.Add($addButton, 1, 0)

$saveButton = New-Object System.Windows.Forms.Button -Property @{ Text = 'Save and run at startup'; AutoSize = $true }
$removeButton = New-Object System.Windows.Forms.Button -Property @{ Text = 'Remove'; AutoSize = $true }
$buttonRow = New-Object System.Windows.Forms.FlowLayoutPanel -Property @{ Dock = 'Fill'; AutoSize = $true; FlowDirection = 'RightToLeft'; Margin = New-Object System.Windows.Forms.Padding(0, 12, 0, 0) }
$buttonRow.Controls.AddRange(@($saveButton, $removeButton))

$layout = New-Object System.Windows.Forms.TableLayoutPanel -Property @{ Dock = 'Fill'; ColumnCount = 1; Padding = New-Object System.Windows.Forms.Padding(12) }
foreach ($row in @(
        @((New-Label "Apps to keep at 0 volume (not listed? type its name below):"), 'AutoSize'),
        @($appList, 60),
        @($addRow, 'AutoSize'),
        @((New-Label 'On these output devices:'), 'AutoSize'),
        @($deviceList, 40),
        @($buttonRow, 'AutoSize'))) {
    $style = if ($row[1] -eq 'AutoSize') { New-Object System.Windows.Forms.RowStyle('AutoSize') } else { New-Object System.Windows.Forms.RowStyle('Percent', $row[1]) }
    [void]$layout.RowStyles.Add($style)
    $layout.Controls.Add($row[0], 0, $layout.RowStyles.Count - 1)
}
$form.Controls.Add($layout)
$form.AcceptButton = $addButton

$addButton.Add_Click({
        $name = $appInput.Text.Trim() -replace '\.exe$', ''
        $appInput.Clear()
        if (-not $name) { return }
        $index = $appList.FindStringExact($name)
        if ($index -lt 0) { $index = $appList.Items.Add($name) }
        $appList.SetItemChecked($index, $true)
    })

$saveButton.Add_Click({
        try {
            New-Item -ItemType Directory -Force -Path $installDir | Out-Null
            [IO.File]::WriteAllText($installedScript, (Get-Content -LiteralPath $env:SAM_SOURCE -Raw))
            @{ Apps = @($appList.CheckedItems); Devices = @($deviceList.CheckedItems) } | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8
            $shortcut = (New-Object -ComObject WScript.Shell).CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $powershellPath
            $shortcut.Arguments = $watchArguments
            $shortcut.WindowStyle = 7
            $shortcut.Save()
            Start-Process -FilePath $powershellPath -ArgumentList $watchArguments -WindowStyle Hidden
            Show-Message "Saved. The checked apps will stay at 0 volume on the checked devices, now and every time Windows starts.`n`nRun this file again to change the list or remove it." 'Information'
            $form.Close()
        }
        catch { Show-Message "Could not save: $_" 'Error' }
    })

$removeButton.Add_Click({
        try {
            @($shortcutPath, $installDir) | Where-Object { Test-Path -LiteralPath $_ } | ForEach-Object { Remove-Item -LiteralPath $_ -Recurse -Force }
            Show-Message "Removed. Apps that were set to 0 stay at 0 until you raise them in the volume mixer (Win+R, sndvol)." 'Information'
            $form.Close()
        }
        catch { Show-Message "Could not remove: $_" 'Error' }
    })

[void]$form.ShowDialog()
