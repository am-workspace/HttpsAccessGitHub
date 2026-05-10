
# GitHub Connectivity Monitor (HTTPS real accessibility check)
# Checks if github.com is actually reachable via HTTPS every 60 seconds.
# Notifies only when GitHub transitions from inaccessible -> accessible.

Add-Type -AssemblyName System.Windows.Forms

$url = "https://github.com"
$checkInterval = 180
$cooldownAfterNotify = 300
$script:lastNotifyTime = 0
$script:wasAccessible = $null
$script:notifyIcon = $null
$script:timer = $null
$script:form = $null

# Force TLS 1.2 (required for GitHub; older Windows may not have it enabled)
[System.Net.ServicePointManager]::SecurityProtocol =
    [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

$logFile = Join-Path $PSScriptRoot "monitor.log"
if (Test-Path $logFile) { Clear-Content $logFile }
function Write-Log {
    param([string]$msg)
    "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') $msg" | Out-File -FilePath $logFile -Append -Encoding utf8
}

$iconPath = Join-Path $PSScriptRoot "GitHub_Invertocat_Black.png"
$script:defaultIcon = $null
if (Test-Path $iconPath) {
    $bitmap = [System.Drawing.Bitmap]::FromFile($iconPath)
    $script:defaultIcon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
    $bitmap.Dispose()
}

function Show-TrayIcon {
    $trayIcon = New-Object System.Windows.Forms.NotifyIcon
    $trayIcon.Text = "GitHub Monitor - 检查中..."
    if ($script:defaultIcon) {
        $trayIcon.Icon = $script:defaultIcon
    } else {
        $trayIcon.Icon = [System.Drawing.SystemIcons]::Information
    }
    $trayIcon.Visible = $true

    $menu = New-Object System.Windows.Forms.ContextMenuStrip

    $testItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $testItem.Text = "立即检测"
    $testItem.Add_Click({ Do-Check })
    [void]$menu.Items.Add($testItem)

    [void]$menu.Items.Add("-")

    $exitItem = New-Object System.Windows.Forms.ToolStripMenuItem
    $exitItem.Text = "退出"
    $exitItem.Add_Click({ Cleanup-Exit })
    [void]$menu.Items.Add($exitItem)

    $trayIcon.ContextMenuStrip = $menu
    $script:notifyIcon = $trayIcon
    return $trayIcon
}

function Show-Notification {
    param([string]$title, [string]$text, [int]$durationSec = 10)
    $script:notifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $script:notifyIcon.BalloonTipTitle = $title
    $script:notifyIcon.BalloonTipText = $text
    $script:notifyIcon.ShowBalloonTip($durationSec * 1000)
}

function Test-GitHubAccess {
    try {
        # Use GET (not HEAD) to fetch actual page body.
        # HEAD-only checks can be fooled: GFW may hijack the TCP stream,
        # return a fake 200 header, then block real data transfer.
        # GET + content validation catches the "false 200" scenario.
        $response = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -TimeoutSec 10

        # Real github.com homepage is tens of KB; fake/blocked responses are tiny or empty
        if ($response.Content.Length -lt 500) {
            return $false
        }

        # Verify the body actually contains GitHub content (not a block page or empty response)
        return ($response.Content -match 'github\.com')
    } catch {
        return $false
    }
}

function Do-Check {
    try {
        $accessible = Test-GitHubAccess
        $now = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())

        if ($accessible) {
            $script:notifyIcon.Text = "GitHub Monitor - 可访问"
        } else {
            $script:notifyIcon.Text = "GitHub Monitor - 无法访问"
        }

        if ($script:wasAccessible -eq $null) {
            # First check at startup
            if ($accessible) {
                Show-Notification -title "GitHub Monitor" -text "GitHub 现在可以访问了! 快去使用吧." -durationSec 5
            } else {
                Show-Notification -title "GitHub Monitor" -text "GitHub 无法访问. 恢复时会通知." -durationSec 10
            }
        } elseif ($script:wasAccessible -eq $false -and $accessible) {
            if (($now - $script:lastNotifyTime) -gt $cooldownAfterNotify) {
                Show-Notification -title "GitHub Recovered" -text "GitHub 现在可以访问了! 快去使用吧." -durationSec 15
                $script:lastNotifyTime = $now
            }
        }

        $script:wasAccessible = $accessible
        Write-Log "Check complete, accessible: $accessible"
    } catch {
        Write-Log "Do-Check error: $_"
    }
}

function Cleanup-Exit {
    $script:notifyIcon.Visible = $false
    $script:timer.Stop()
    $script:timer.Dispose()
    $script:notifyIcon.Dispose()
    $script:form.Close()
}

# ---- Single instance check ----
$mutexName = "Global\GitHubMonitor_SingleInstance"
$mutex = New-Object System.Threading.Mutex($true, $mutexName, [ref]$false)
if (-not $mutex.WaitOne(0, $false)) {
    Write-Host "GitHub Monitor is already running."
    exit 0
}

# ---- Main ----
try {
    Write-Log "Starting monitor..."
    [System.Windows.Forms.Application]::EnableVisualStyles()

    Write-Log "Creating tray icon..."
    Show-TrayIcon | Out-Null

    # Hidden form to provide a proper Windows message pump
    Write-Log "Creating hidden form..."
    $script:form = New-Object System.Windows.Forms.Form
    $script:form.ShowInTaskbar = $false
    $script:form.WindowState = "Minimized"
    $script:form.FormBorderStyle = "FixedToolWindow"
    $script:form.Opacity = 0
    $script:form.Size = New-Object System.Drawing.Size(0, 0)
    $script:form.Add_Shown({ try { $script:form.Hide() } catch { Write-Log "Hide form failed: $_" } })

    Write-Log "Starting timer..."
    $script:timer = New-Object System.Windows.Forms.Timer
    $script:timer.Interval = $checkInterval * 1000
    $script:timer.Add_Tick({
        try {
            Do-Check
        } catch {
            Write-Log "Timer tick error: $_"
        }
    })
    $script:timer.Start()

    # Run an immediate check at startup
    Write-Log "Queuing initial check..."
    Do-Check

    Write-Log "Entering message loop..."
    [System.Windows.Forms.Application]::Run($script:form)
} catch {
    Write-Log "FATAL: $_"
} finally {
    Write-Log "Monitor stopped."
}
