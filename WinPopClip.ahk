#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#InstallMouseHook
AutoTrim, Off
CoordMode, Mouse, Screen
ListLines Off
SendMode, Input ; Recommended for new scripts due to its superior speed and reliability.
SetBatchLines -1
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run *RunAs "%A_ScriptFullPath%" /restart
        else
            Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%"
    }
    ExitApp
}

; MsgBox A_IsAdmin: %A_IsAdmin%`nCommand line: %full_command_line%

winTitle:="WinClipTitle"
dpiRatio:=A_ScreenDPI/96
controlHight:=25
winHeightPx:=controlHight*dpiRatio
bGColor:="000000"
fontColor:="ffffff"
ver:="0.1"
fontSize:=12
fontFamily:="微软雅黑"

Loop, read, %A_ScriptDir%/White List.txt
{
    GroupAdd, whiteList, ahk_exe %A_LoopReadLine%
}

Menu, tray, NoStandard
Menu, tray, add, 更新 | Ver %ver%, UpdateScrit
Menu, tray, add, 反馈 | Issues, Issues
;Menu, tray, add, 暂停 | Pause, PauseScrit
Menu, tray, add
Menu, tray, add, 重置 | Reload, ReloadScrit
Menu, tray, add, 退出 | Exit, ExitScrit
Return

ReloadScrit:
Reload
Return

PauseScrit:
Pause, Toggle, 1
Return

UpdateScrit:
Run, https://github.com/millionart/WinClip.ahk/releases
Return

Issues:
Run, https://github.com/millionart/WinClip.ahk/issues
Return

ExitScrit:
^#p::
ExitApp
Return

#IfWinNotActive, ahk_group whiteList
~LButton::
Gui,Destroy
Return
#IfWinNotActive

#IfWinActive, ahk_group whiteList
; 如果不在脚本界面状态下
$LButton::
    ; ToolTip, %win% %A_TickCount%, 0,0
    ; 获得鼠标当前坐标
    MouseGetPos, perPosX, perPosY
    ; 获得当前时间
    preTime:=A_TickCount
    If (A_Cursor="IBeam")
        winClipToggle:=1
        
    Send, {LButton Down}
    KeyWait, LButton

    Send, {LButton Up}

    If (A_Cursor="IBeam")
        winClipToggle:=1

    If !WinActive(winTitle)
    {
        win:= WinExist("A")
        ShowMainGui(perPosX,perPosY,preTime)   
    }
Return
#IfWinActive

ShowMainGui(perPosX,perPosY,preTime)
{
    global
    ; 获得当前时间
    curTime:=A_TickCount
    ; 当前时间减去之前时间
    lButtonDownDelay:=curTime-preTime

    ; 获得鼠标当前坐标
    MouseGetPos, curPosX, curPosY

    guiShowX:=curPosX
    guiShowY:=curPosY-winHeightPx*2 ;*dpiRatio

    If (A_TimeSincePriorHotkey < 500)
    {
        GetSelectText()
        ShowWinclip()
    }
    Else if (lButtonDownDelay > 250 && winClipToggle=1) || (lButtonDownDelay > 350)
    {
        ; 当前坐标剪去先前坐标
        moveX:=abs(curPosX-perPosX)
        moveY:=abs(curPosY-perPosY)

        ; 如果X大于10，Y大于10, 在当前坐标弹出界面
        If (moveX>10) || (moveY>10)
        {
            GetSelectText()
            ShowWinclip()
        }
    }
    Else
    {
        Gui, Destroy
    }

    winClipToggle:=0
}

GetSelectText()
{
    global
    ClipSaved:=ClipBoardAll
    ClipBoard:=""
    Send, {CtrlDown}c
    ClipWait 0.4, 1
    Send, {CtrlUp}
    selectText:=ClipBoard
    ClipBoard:=""
    ClipBoard:=ClipSaved
    ; 处理协议地址
    linkText:=""
    RegExMatch(selectText, "(https?|ftp|file|ed2k|thunder)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]+[-A-Za-z0-9+&@#/%=~_|]", linkText)
}

ShowWinclip()
{
    global
    local x,y,w,h,winMoveX,winMoveY
    ;ToolTip, %selectText%
    Gui, Destroy
    Gui, +ToolWindow -Caption +AlwaysOnTop ; -DPIScale
    Gui, Color, %bGColor%
    Gui, font, s%fontSize% c%fontColor%, %fontFamily%
    Gui, Add, Text, x0 y0 w0 h%controlHight% -Wrap, ; 初始定位

    If selectText in ,%A_Space%,%A_Tab%,`r`n,`r,`n
    {
        Gui, Add, Button, x+0 yp hp -Wrap vselectAll gSelectAll, ` ` 全选` ` ` 
        If (winClipToggle=1)
        Gui, Add, Button, x+0 yp hp -Wrap vpaste gPaste, ` ` 粘贴` ` ` 
    }
    Else
    {
        Gui, Add, Button, x+0 yp hp -Wrap vsearch gGoogleSearch, ` 🔍` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vselectAll gSelectAll, ` ` 全选` ` ` 
        If (winClipToggle=1)
        {
            Gui, Add, Button, x+0 yp hp -Wrap vcut gCut, ` ` 剪切` ` `
        Gui, Add, Button, x+0 yp hp -Wrap vcopy gCopy, ` ` 复制` ` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vpaste gPaste, ` ` 粘贴` ` ` 
        }
        Else
        {
            Gui, Add, Button, x+0 yp hp -Wrap vcopy gCopy, ` ` 复制` ` ` 
        }
        If (linkText!="")
            Gui, Add, Button, x+0 yp hp -Wrap vlink gLink, ` ` 链接` ` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vtranslate gGoogleTranslate, ` ` 翻译` ` ` 
    }

    Gui, font
    Gui, Show, NA AutoSize x%guiShowX% y%guiShowY%, %winTitle%
    WinGetPos , x, y, w, h, %winTitle%

    winMoveX:=Max(x-w/2,0)
    If (winMoveX > A_ScreenWidth-w+15*dpiRatio)
        winMoveX:=A_ScreenWidth-w+15*dpiRatio

    winMoveY:=Max(y,0)

    WinMove, %winTitle%, , winMoveX, winMoveY, w-15*dpiRatio, %winHeightPx%
}

GoogleSearch:
    Gui, Destroy
    Run, https://www.google.com/search?ie=utf-8&oe=utf-8&q=%selectText%
Return

SelectAll:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    Click, %perPosX%, %perPosY%
    Send, {CtrlDown}a
    Sleep, 100
    Send, {CtrlUp}
    GetSelectText()
    ShowWinclip()
Return

Copy:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    ClipBoard:=""
    ClipBoard:=selectText
Return

Cut:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    Send, {Del}
    ClipBoard:=""
    ClipBoard:=selectText
Return

Paste:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    Send, {CtrlDown}v
    Sleep, 100
    Send, {CtrlUp}
Return

Link:
    Gui, Destroy
    Try
    Run, %linkText%
Return

GoogleTranslate:
    Gui, Destroy
    transText:=UriEncode(selectText)
    Run, https://translate.google.cn/#auto/zh-CN/%transText%
Return

; from http://the-automator.com/parse-url-parameters/
UriEncode(Uri, RE="[0-9A-Za-z]"){
    VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
    While Code:=NumGet(Var,A_Index-1,"UChar")
    Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)
    Return,Res
}