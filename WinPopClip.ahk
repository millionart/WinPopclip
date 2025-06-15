#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#InstallMouseHook
AutoTrim, Off
CoordMode, Mouse, Screen
DetectHiddenWindows, On
ListLines Off
SendMode, Input ; Recommended for new scripts due to its superior speed and reliability.
SetBatchLines -1
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

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

winTitle:="WinClipTitle"
dpiRatio:=A_ScreenDPI/96
controlHight:=25
winHeightPx:=controlHight*dpiRatio
bGColor:="000000"
fontColor:="ffffff"
ver:="0.92"
fontSize:=12
fontFamily:="微软雅黑"
userLanguage:="zh-CN"
userLanguageDeepL:="zh-hans"
SyncPath:="E:\Dropbox"
SysGet, VirtualWidth, 78
SysGet, VirtualHeight, 79

; *** NEW: 初始化一个全局时间戳，用于冷却机制 ***
global g_lastActionTime := 0

Loop, read, %A_ScriptDir%/WhiteList.txt
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
    Run, https://github.com/millionart/WinPopclip/releases
Return

Issues:
    Run, https://github.com/millionart/WinPopclip/issues
Return

ExitScrit:
^#p::
ExitApp
Return

; =================================================================================
; ========================  核心逻辑修改：统一的全局热键  ========================
; =================================================================================

global selectionStartedAsIBeam := false

~LButton::
    ; *** FIX: 引入冷却时间，防止高频操作导致的状态冲突 ***
    ; 如果距离上一次成功弹出菜单的时间太短，则忽略本次点击。
    if (A_TickCount - g_lastActionTime < 250)
        return

    if WinExist(winTitle)
    {
        MouseGetPos, ,, hwndUnderMouse
        if (hwndUnderMouse == WinExist(winTitle))
            return
        Gui, Destroy
    }

    if (A_TimeSincePriorHotkey < 400 and A_Cursor = "IBeam")
    {
        dragInProgress := false 
        Sleep, 50 
        GetSelectText()
        If (selectText != "")
        {
            MouseGetPos, curPosX, curPosY
            guiShowX:=curPosX
            guiShowY:=curPosY-winHeightPx*2
            ShowWinclip()
        }
        return
    }

    if WinActive("ahk_group whiteList")
    {
        dragInProgress := true
        MouseGetPos, perPosX, perPosY
        selectionStartedAsIBeam := (A_Cursor = "IBeam")
    }
Return

; =================================================================================

#IfWinActive, ahk_group whiteList
    global dragInProgress := false

    ~LButton Up::
        If !dragInProgress
            return
        dragInProgress := false
        win := WinExist("A")
        ShowMainGui(perPosX, perPosY)
        Return
#IfWinActive

ShowMainGui(perPosX,perPosY)
{
    global
    MouseGetPos, curPosX, curPosY
    moveX:=abs(curPosX-perPosX)
    moveY:=abs(curPosY-perPosY)
    
    If (moveX > 10) || (moveY > 10)
    {
        GetSelectText()
        If (selectText != "")
        {
            guiShowX:=curPosX
            guiShowY:=curPosY-winHeightPx*2
            ShowWinclip()
        }
    }
    Else
    {
        Gui, Destroy
    }
}

GetSelectText()
{
    global
    ClipSaved:=ClipBoardAll
    ClipBoard:=""
    Send, ^c
    ClipWait, 0.5
    selectText:=ClipBoard
    ClipBoard:=""
    ClipBoard:=ClipSaved
    ClipSaved:=""

    If (selectText = "")
        Return

    linkText:=""
    linkButton:="🔗"
    urlRegEx:="(?:(?:https?|ftp|file|ed2k|steam|thunder)://)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)(?:\.(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)*(?:\.(?:[a-z\x{00a1}-\x{ffff}]{2,})))(?::\d{2,5})?(?:/[^\s]*)?"
    RegExMatch(selectText, urlRegEx, linkText)
    urlRegEx:="(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])"
    RegExMatch(selectText, urlRegEx, ipText)
    If (linkText="")
    {
        urlRegEx:="(?i)\b((?:https?://|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'.,<>?«»“”‘’]))"
        RegExMatch(selectText, urlRegEx, linkText)
        urlRegEx:="av\d+"
        RegExMatch(selectText, urlRegEx, bilibili)
        If (linkText!="")
            linkText:="http://" . linkText
        Else If (bilibili!="")
        {
            linkText:="https://www.bilibili.com/video/" . bilibili
            linkButton:="` BiliBili` "
        }
    }
}

ShowWinclip()
{
    global
    local x,y,w,h,winMoveX,winMoveY
    Gui, Destroy
    Gui, +ToolWindow -Caption +AlwaysOnTop -DPIScale
    Gui, Color, %bGColor%
    Gui, font, s%fontSize% c%fontColor%, %fontFamily%
    Gui, Add, Text, x0 y0 w0 h%controlHight% -Wrap,

    isEditableContext := (selectionStartedAsIBeam or (A_Cursor = "IBeam"))

    If selectText in ,%A_Space%,%A_Tab%,`r`n,`r,`n
    {
        If (isEditableContext)
        {
            Gui, Add, Button, x+0 yp hp -Wrap vselectAll gSelectAll, ` ` 全选` ` `
            Gui, Add, Button, x+0 yp hp -Wrap vpaste gPaste, ` ` 粘贴` ` `
        }
    }
    Else
    {
        Gui, Add, Button, x+0 yp hp -Wrap vsearch gGoogleSearch, ` 🔍` `
        If (linkText!="")
            Gui, Add, Button, x+0 yp hp -Wrap gLink, ` %linkButton%` `
        Gui, Add, Button, x+0 yp hp -Wrap vselectAll gSelectAll, ` ` 全选` ` `
        If (isEditableContext)
        {
            Gui, Add, Button, x+0 yp hp -Wrap vcut gCut, ` ` 剪切` ` `
            Gui, Add, Button, x+0 yp hp -Wrap vcopy gCopy, ` ` 复制` ` `
            Gui, Add, Button, x+0 yp hp -Wrap vpaste gPaste, ` ` 粘贴` ` `
        }
        Else
        {
            Gui, Add, Button, x+0 yp hp -Wrap vcopy gCopy, ` ` 复制` ` `
        }
        Gui, Add, Button, x+0 yp hp -Wrap vdTranslate gDeepLTranslate, ` ` D 翻译` ` `
    }

    Gui, font
    Gui, Show, NA AutoSize x%guiShowX% y%guiShowY%, %winTitle%
    
    ; *** NEW: 当菜单成功显示前，更新时间戳，启动冷却 ***
    g_lastActionTime := A_TickCount
    
    WinGetPos , winX, winY, winW, winH, %winTitle%
    MouseGetPos, mouseX, mouseY
    targetCenterX := winX + winW/2 - winW/2
    targetCenterY := mouseY - winH/2
    If (targetCenterX - winW/2 < 0)
        targetCenterX := winW/2
    If (targetCenterX + winW/2 > VirtualWidth)
        targetCenterX := VirtualWidth - winW/2
    If (targetCenterY - winH/2 < 0)
        targetCenterY := winH/2
    If (targetCenterY + winH/2 > VirtualHeight)
        targetCenterY := VirtualHeight - winH/2
    WinMove, %winTitle%, , targetCenterX - winW/2, targetCenterY - winH/2, winW-15*dpiRatio, %winHeightPx%
}

GoogleSearch:
    Gui, Destroy
    urlEncodedText:=UriEncode(selectText)
    Run, https://www.google.com/search?ie=utf-8&oe=utf-8&q=%urlEncodedText%
Return

SelectAll:
    Gui, Destroy
    WinActivate, ahk_id %win%
    WinWaitActive, ahk_id %win%
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
    If (FileExist(SyncPath))
    {
        FileSetAttrib, -R, %SyncPath%\WinPopclip
        FileDelete, %SyncPath%\WinPopclip
        FileAppend, %selectText%, %SyncPath%\WinPopclip
    }
Return

Cut:
    Gosub, Copy
    Send, {Del}
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

DeepLTranslate:
    Gui, Destroy
    selectText:=UriEncode(selectText,1)
    Run, https://www.deepl.com/translator#en/%userLanguageDeepL%/%selectText%
Return

UriEncode(Uri, Mode := 0, RE="[0-9A-Za-z]"){
    VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
    While Code:=NumGet(Var,A_Index-1,"UChar")
        Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)
    Res:=StrReplace(Res, "&", "%26")
    Res:=StrReplace(Res, "`n", "%0A")
    If (Mode==1)
        Res:=StrReplace(Res, "%2F", "%5C%2F")
    Return,Res
}

TransBox(text,originalLang,tragetLang) {
    pwb := ComObjCreate("InternetExplorer.Application")
    pwb.Visible := False
    pwb.Navigate("https://translate.google.com/#view=home&op=translate&sl=" . originalLang . "&tl=" . tragetLang . "&text=" text)
    Loop {
        IfWinExist, ahk_exe iexplorer.exe
            Process, Close, iexplorer.exe
        else
            break
    } While pwb.readyState != 4 || pwb.document.readyState != "complete" || pwb.busy
    Sleep, 1
    result := pwb.document.all.result_box.InnerText
    pwb.Quit
    return, result
}