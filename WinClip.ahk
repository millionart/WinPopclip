#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#InstallMouseHook
AutoTrim, Off
CoordMode, Mouse, Screen
ListLines Off
SendMode, Input ; Recommended for new scripts due to its superior speed and reliability.
SetBatchLines -1
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

winTitle:="WinClipTitle"
dpiRatio:=A_ScreenDPI/96
controlHight:=25
winHeightPx:=controlHight*dpiRatio
bGColor:="000000"
ver:="0.1"

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
    guiShowY:=curPosY-winHeightPx*1.5 ;*dpiRatio

    If (A_PriorHotkey = "$LButton" and A_TimeSincePriorHotkey < 500 and A_Cursor="IBeam")
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

ShowWinclip()
{
    global
    local x,y,w,h
    ;ToolTip, %selectText%
    Gui, Destroy
    Gui, +ToolWindow -Caption +AlwaysOnTop ; -DPIScale
    Gui, Color, %bGColor%
    Gui, font, s12 cffffff, 微软雅黑
    Gui, Add, Button, x0 y0 h%controlHight% -Wrap vsearch gGoogleSearch, ` 🔍` ` 
    Gui, Add, Button, x+0 yp h%controlHight% -Wrap vselectAll gSelectAll, ` ` 全选` ` ` 

    If selectText in ,%A_Space%,%A_Tab%,`r`n,`r,`n
    {
        Gui, Add, Button, x+0 yp h%controlHight% -Wrap vpaste gPaste, ` ` 粘贴` ` ` 
    }
    Else
    {
        Gui, Add, Button, x+0 yp h%controlHight% -Wrap vcopy gCopy, ` ` 复制` ` ` 
        Gui, Add, Button, x+0 yp h%controlHight% -Wrap vpaste gPaste, ` ` 粘贴` ` ` 
        ;Gui, Add, Button, x+0 yp h%controlHight% -Wrap vlink gLink, ` ` 链接` ` ` 
        Gui, Add, Button, x+0 yp h%controlHight% -Wrap vtranslate gGoogleTranslate, ` ` 翻译` ` ` 
    }
    Gui, font
    Gui, Show, NA AutoSize x%guiShowX% y%guiShowY%, %winTitle%
    WinGetPos , x, y, w, h, %winTitle%
    WinMove, %winTitle%, , x-w/2, y, w-15*dpiRatio, %winHeightPx%
}

GetSelectText()
{
    global
    ClipSaved:=ClipBoardAll
    ClipBoard:=""
    Send, {CtrlDown}c
    ClipWait 1, 1
    Send, {CtrlUp}
    selectText:=ClipBoard
    ClipBoard:=""
    ClipBoard:=ClipSaved
    ; ToolTip,[%selectText%]
}

GoogleSearch:
    Run, https://www.google.com/search?ie=utf-8&oe=utf-8&q=%selectText%
    Gosub, RestoreClipBoard
Return

SelectAll:
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
    Send, {CtrlDown}a
    Sleep, 100
    Send, {CtrlUp}
    Gosub, RestoreClipBoard
Return

Copy:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
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
    Run, https://www.google.com/search?ie=utf-8&oe=utf-8&q=%selectText%
    Gosub, RestoreClipBoard
Return

GoogleTranslate:
; https%3A%2F%2Ftranslate.google.cn%2F%23auto%2Fzh-CN%2F%25ClipBoard%25
    Run, https://translate.google.cn/#auto/zh-CN/%selectText%
    Gosub, RestoreClipBoard
Return

RestoreClipBoard:
    ClipBoard:=""
    ClipBoard:=ClipSaved
    Gui, Destroy
Return

; working...
URLEncoding(string)
{
    string:=StrReplace(string, SearchText , ReplaceText)
}