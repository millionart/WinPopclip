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

; MsgBox A_IsAdmin: %A_IsAdmin%`nCommand line: %full_command_line%

winTitle:="WinClipTitle"
dpiRatio:=A_ScreenDPI/96
controlHight:=25
winHeightPx:=controlHight*dpiRatio
bGColor:="000000"
fontColor:="ffffff"
ver:="0.7"
fontSize:=12
fontFamily:="微软雅黑"
userLanguage:="zh-CN"
SyncPath:="E:\Dropbox"

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
    Run, https://github.com/millionart/WinPopclip/releases
Return

Issues:
    Run, https://github.com/millionart/WinPopclip/issues
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
    
    If (A_TimeSincePriorHotkey < 410) && (A_Cursor="IBeam")
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
    ; PostMessage, 0x301, , , , ahk_id %win% 
    ; PostMessage WM_COPY not work for some windows (even steam or notepad and more), why?
    Send, {CtrlDown}c
    ClipWait 0.1, 1
    Send, {CtrlUp}
    selectText:=ClipBoard
    ClipBoard:=""
    ClipBoard:=ClipSaved
    ClipSaved:=""
    ; 处理协议地址
    linkText:=""
    linkButton:="🔗"
    ; https://gist.github.com/dperini/729294
    ; https://mathiasbynens.be/demo/url-regex
    urlRegEx:="(?:(?:https?|ftp|file|ed2k|steam|thunder)://)(?:\S+(?::\S*)?@)?(?:(?!10(?:\.\d{1,3}){3})(?!127(?:\.\d{1,3}){3})(?!169\.254(?:\.\d{1,3}){2})(?!192\.168(?:\.\d{1,3}){2})(?!172\.(?:1[6-9]|2\d|3[0-1])(?:\.\d{1,3}){2})(?:[1-9]\d?|1\d\d|2[01]\d|22[0-3])(?:\.(?:1?\d{1,2}|2[0-4]\d|25[0-5])){2}(?:\.(?:[1-9]\d?|1\d\d|2[0-4]\d|25[0-4]))|(?:(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)(?:\.(?:[a-z\x{00a1}-\x{ffff}0-9]+-?)*[a-z\x{00a1}-\x{ffff}0-9]+)*(?:\.(?:[a-z\x{00a1}-\x{ffff}]{2,})))(?::\d{2,5})?(?:/[^\s]*)?"
    RegExMatch(selectText, urlRegEx, linkText)
    
    urlRegEx:="(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])\.(\d{1,2}|1\d\d|2[0-4]\d|25[0-5])"
    RegExMatch(selectText, urlRegEx, ipText)
    
    If (linkText="")
    {
        ; https://daringfireball.net/2010/07/improved_regex_for_matching_urls
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
    ;ToolTip, %selectText%
    Gui, Destroy
    Gui, +ToolWindow -Caption +AlwaysOnTop ; -DPIScale
    Gui, Color, %bGColor%
    Gui, font, s%fontSize% c%fontColor%, %fontFamily%
    Gui, Add, Text, x0 y0 w0 h%controlHight% -Wrap, ; 初始定位
    
    If selectText in ,%A_Space%,%A_Tab%,`r`n,`r,`n
    {
        If (winClipToggle=1)
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
        Gui, Add, Button, x+0 yp hp -Wrap vgTranslate gGoogleTranslate, ` ` G 翻译` ` ` 
        Gui, Add, Button, x+0 yp hp -Wrap vdTranslate gDeepLTranslate, ` ` D 翻译` ` ` 
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
        FileAppend,
        (
        %selectText%
        ), %SyncPath%\WinPopclip
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

GoogleTranslate:
    Gui, Destroy
    selectText:=UriEncode(selectText)
    Run, https://translate.google.com/#view=home&op=translate&sl=auto&tl=%userLanguage%&text=%selectText%
Return

DeepLTranslate:
    Gui, Destroy
    selectText:=UriEncode(selectText)
    Run, https://www.deepl.com/translator#auto/%userLanguage%/%selectText%
Return

; from http://the-automator.com/parse-url-parameters/
UriEncode(Uri, RE="[0-9A-Za-z]"){
    VarSetCapacity(Var,StrPut(Uri,"UTF-8"),0),StrPut(Uri,&Var,"UTF-8")
    While Code:=NumGet(Var,A_Index-1,"UChar")
        Res.=(Chr:=Chr(Code))~=RE?Chr:Format("%{:02X}",Code)
    
    Res:=StrReplace(Res, "&", "%26")
    Res:=StrReplace(Res, "`n", "%0A")
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
