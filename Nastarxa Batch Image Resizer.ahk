#Requires AutoHotkey v2.0
#SingleInstance Force
TraySetIcon "Resizer.ico"

global _PRESETS_FILE := A_ScriptDir "\Nastarxa Batch Image Resizer Presets.ini"
global _SETTINGS_FILE := A_ScriptDir "\Nastarxa Batch Image Resizer Settings.ini"

CreateDefaultPresets()

CreateGUI()

CreateDefaultPresets() {
    if FileExist(_PRESETS_FILE)
        return
    p := _PRESETS_FILE
    IniWrite(25, p, "Thumbnail", "Scale")
    IniWrite(72, p, "Thumbnail", "Dpi")
    IniWrite(60, p, "Thumbnail", "Quality")
    IniWrite("JPEG", p, "Thumbnail", "Format")

    IniWrite(50, p, "Web Small", "Scale")
    IniWrite(72, p, "Web Small", "Dpi")
    IniWrite(75, p, "Web Small", "Quality")
    IniWrite("PNG", p, "Web Small", "Format")

    IniWrite(75, p, "Web Standard", "Scale")
    IniWrite(96, p, "Web Standard", "Dpi")
    IniWrite(80, p, "Web Standard", "Quality")
    IniWrite("JPEG", p, "Web Standard", "Format")

    IniWrite(100, p, "Print High", "Scale")
    IniWrite(300, p, "Print High", "Dpi")
    IniWrite(95, p, "Print High", "Quality")
    IniWrite("TIFF", p, "Print High", "Format")

    IniWrite(100, p, "Social Media", "Scale")
    IniWrite(150, p, "Social Media", "Dpi")
    IniWrite(85, p, "Social Media", "Quality")
    IniWrite("JPEG", p, "Social Media", "Format")

    IniWrite(75, p, "Anime Keyframe", "Scale")
    IniWrite(150, p, "Anime Keyframe", "Dpi")
    IniWrite(100, p, "Anime Keyframe", "Quality")
    IniWrite("JPEG", p, "Anime Keyframe", "Format")
}

CreateGUI() {

    g := Gui("+MinSize360x360 +E0x10", "Nastarxa Batch Image Resizer")

    g.BackColor := "2B2D31"
    g.SetFont("s9", "Segoe UI")

    g.MarginX := 14
    g.MarginY := 12

    rowGap := 14
    labelColor := "cCFCFCF"

    ; =========================================================
    ; INPUT
    ; =========================================================

    g.AddText(labelColor, "Input Folder")

    g.inputEdit := g.AddEdit(
        "xm y+4 w320 h24 BackgroundFFFFFF c000000",
        A_ScriptDir "\input"
    )

    g.btnInput := g.AddButton(
        "x+6 yp-1 w72 h26",
        "Browse"
    )

    ; =========================================================
    ; OUTPUT
    ; =========================================================

    g.AddText("xm y+" rowGap " " labelColor, "Output Folder")

    g.outputEdit := g.AddEdit(
        "xm y+4 w320 h24 BackgroundFFFFFF c000000",
        A_ScriptDir "\input\DPI_150"
    )

    g.btnOutput := g.AddButton(
        "x+6 yp-1 w72 h26",
        "Browse"
    )

    ; =========================================================
    ; SETTINGS
    ; =========================================================

    ; =========================================================
    ; MODE TOGGLE + FORMAT
    ; =========================================================

    g.usePxCheck := g.AddCheckBox(
        "xm y+" rowGap " " labelColor " vUsePxMode",
        "Pixel Size"
    )
    g.usePxCheck.OnEvent("Click", (*) => TogglePxMode(g))

    g.AddText("x+24 yp+3 " labelColor, "Format")

    g.formatDropdown := g.AddDropDownList(
        "x+6 yp-2 w120",
        ["Keep Original", "PNG", "JPEG", "BMP", "TIFF"]
    )

    ; =========================================================
    ; SCALE / DPI
    ; =========================================================

    g.scaleLabel := g.AddText("xm y+" rowGap " " labelColor " vScaleLabel", "Scale")

    g.scaleEdit := g.AddEdit(
        "x+6 yp-2 w52 h24 Number Center BackgroundFFFFFF c000000 vScaleEdit",
        "100"
    )

    g.lockIndicator := g.AddText("x+6 yp+1 w20 h20 Center +0x200 c4CAF50 vScaleLock", "🔗")
    g.lockIndicator.SetFont("s10", "Segoe UI")
    g.lockIndicator.OnEvent("Click", (*) => ToggleLock(g))

    g.dpiLabel := g.AddText("x+4 yp+2 " labelColor " vDpiLabel", "DPI")

    g.dpiEdit := g.AddEdit(
        "x+6 yp-2 w58 h24 Number Center BackgroundFFFFFF c000000 vDpiEdit",
        "150"
    )

    ; =========================================================
    ; QUICK DPI
    ; =========================================================

    g.quickDpiLabel := g.AddText("xm y+" rowGap " " labelColor " vQuickDpiLabel", "Quick DPI")

    dpiButtonVals := [72, 96, 150, 300, 600]
    g._dpiButtons := []

    for dpi in dpiButtonVals {

        btn := g.AddButton(
            (A_Index = 1 ? "x+8 yp-1 " : "x+4 yp ")
            "w42 h22",
            dpi
        )

        btn.OnEvent("Click", SetQuickDpi.Bind(g, dpi))
        g._dpiButtons.Push(btn)
    }

    g.btnReset := g.AddButton(
        "x+12 yp w52 h22",
        "Reset"
    )
    g.btnReset.OnEvent("Click", ResetToSource.Bind(g))

    ; =========================================================
    ; WIDTH / HEIGHT
    ; =========================================================

    g.pxWidthLabel := g.AddText("xm y+" rowGap " " labelColor " vPxWidthLabel", "Width")
    g.pxWidthLabel.Enabled := 0

    g.pxWidth := g.AddEdit(
        "x+6 yp-2 w64 h24 Number Center BackgroundFFFFFF c000000 vPxWidth",
        "1920"
    )
    g.pxWidth.Enabled := 0
    g.pxWidth.OnEvent("Change", OnPxWidthChange.Bind(g))

    g.pxLockIndicator := g.AddText("x+6 yp+1 w20 h20 Center +0x200 c4CAF50 vPxLock", "🔗")
    g.pxLockIndicator.SetFont("s10", "Segoe UI")
    g.pxLockIndicator.Enabled := 0
    g.pxLockIndicator.OnEvent("Click", (*) => TogglePxLock(g))

    g.pxHeightLabel := g.AddText("x+4 yp+2 " labelColor " vPxHeightLabel", "Height")
    g.pxHeightLabel.Enabled := 0

    g.pxHeight := g.AddEdit(
        "x+6 yp-2 w80 h28 Number Center BackgroundFFFFFF c000000 vPxHeight",
        "1080"
    )
    g.pxHeight.Enabled := 0
    g.pxHeight.OnEvent("Change", OnPxHeightChange.Bind(g))

    ; =========================================================
    ; ASPECT RATIO
    ; =========================================================

    g.pxRatioLabel := g.AddText("xm y+" rowGap " " labelColor " vPxRatioLabel", "Aspect Ratio")
    g.pxRatioLabel.Enabled := 0

    g.pxRatio := g.AddEdit(
        "x+6 yp-2 w72 h24 Center BackgroundFFFFFF c000000 vPxRatio",
        "1:1"
    )
    g.pxRatio.Enabled := 0
    g.pxRatio.ToolTip := "Enter W:H ratio (e.g. 16:9), or leave empty for original"
    g.pxRatio.OnEvent("Change", (*) => ApplyRatioFromInput(g))

    g.pxRatioOrig := g.AddButton("x+4 yp w42 h22 vPxRatioOrig", "Orig")
    g.pxRatioOrig.Enabled := 0
    g.pxRatioOrig.OnEvent("Click", (*) => (
        g.pxRatio.Value := "Original",
        ApplyRatioFromInput(g)
    ))

    g.pxRatio16_9 := g.AddButton("x+4 yp w42 h22 vPxRatio16_9", "16:9")
    g.pxRatio16_9.Enabled := 0
    g.pxRatio16_9.OnEvent("Click", (*) => (
        g.pxRatio.Value := "16:9",
        ApplyRatioFromInput(g)
    ))

    g.pxRatio4_3 := g.AddButton("x+4 yp w42 h22 vPxRatio4_3", "4:3")
    g.pxRatio4_3.Enabled := 0
    g.pxRatio4_3.OnEvent("Click", (*) => (
        g.pxRatio.Value := "4:3",
        ApplyRatioFromInput(g)
    ))

    g.pxRatio1_1 := g.AddButton("x+4 yp w42 h22 vPxRatio1_1", "1:1")
    g.pxRatio1_1.Enabled := 0
    g.pxRatio1_1.OnEvent("Click", (*) => (
        g.pxRatio.Value := "1:1",
        ApplyRatioFromInput(g)
    ))

    ; =========================================================
    ; SECURE PIXEL MODE
    ; =========================================================

    g.pxSecureLabel := g.AddText("xm y+" rowGap " " labelColor " vPxSecureLabel", "Secure")
    g.pxSecureLabel.Enabled := 0

    g.pxSecureDropdown := g.AddDropDownList(
        "x+6 yp-2 w130 vPxSecureMode Choose1",
        ["Auto", "Secure Height", "Secure Width"]
    )
    g.pxSecureDropdown.Enabled := 0
    g.pxSecureDropdown.OnEvent("Change", (*) => OnPxSecureChange(g))

    g.pxResetBtn := g.AddButton("x+12 yp w52 h22 vPxResetBtn", "Reset")
    g.pxResetBtn.Enabled := 0
    g.pxResetBtn.OnEvent("Click", (*) => ResetPxToSource(g))

    ; =========================================================
    ; QUALITY
    ; =========================================================

    g.AddText("xm y+" rowGap " " labelColor, "JPEG Quality")

    g.jpegQuality := g.AddSlider(
        "xm y+4 w340 h18 Range1-100 ToolTip Thick20",
        85
    )

    g.jpegValueText := g.AddText(
        "x+10 yp+1 w30 cCFCFCF",
        g.jpegQuality.Value "%"
    )

    g.jpegQuality.OnEvent("Change", (*) => (
        g.jpegValueText.Text := g.jpegQuality.Value "%"
    ))

    ; =========================================================
    ; PATTERN
    ; =========================================================

    g.AddText("xm y+" rowGap " " labelColor, "Filename Pattern")

    g.patternEdit := g.AddEdit(
        "xm y+4 w378 h24 BackgroundFFFFFF c000000",
        "{name}{ext}"
    )

    ; =========================================================
    ; OPTIONS
    ; =========================================================

    g.overwriteCheck := g.AddCheckBox(
        "xm y+" rowGap " " labelColor,
        "Overwrite"
    )

    g.recursiveCheck := g.AddCheckBox(
        "x+18 yp Checked " labelColor,
        "Subfolders"
    )

    g.dpiFolderCheck := g.AddCheckBox(
        "x+18 yp Checked " labelColor,
        "Make Folder"
    )

    ; =========================================================
    ; PRESETS
    ; =========================================================

    g.AddText("xm y+" rowGap " " labelColor, "Preset")

    g.presetsDropdown := g.AddDropDownList(
        "xm y+4 w250",
        GetPresetNames()
    )

    g.btnSavePreset := g.AddButton(
        "x+6 yp-1 w56 h24",
        "Save"
    )

    g.btnDeletePreset := g.AddButton(
        "x+4 yp w56 h24",
        "Delete"
    )

    ; =========================================================
    ; STATUS
    ; =========================================================

    g.fileCount := g.AddText(
        "xm y+" rowGap " w378 c808080 +0x100",
        "0 images found"
    )
    g.fileCount.SetFont("s9 underline", "Segoe UI")
    g.fileCount.ToolTip := "Click to view file list"
    g.fileCount.OnEvent("Click", (*) => ShowFileList(g))

    ; Flat progress bar style
    g.progressBg := g.AddText(
        "xm y+6 w378 h8 Background23262C"
    )

    g.progressFill := g.AddText(
        "xp yp w0 h8 BackgroundE8A93A"
    )

    g.status := g.AddText(
        "xm y+8 w378 cA8A8A8",
        "Ready"
    )

    ; =========================================================
    ; BUTTONS
    ; =========================================================

    g.btnStart := g.AddButton(
        "xm y+14 w124 h30",
        "Start"
    )

    g.btnOpenOutput := g.AddButton(
        "x+10 yp w124 h30",
        "Open Output"
    )

    g.btnGuide := g.AddButton(
        "x+10 yp w124 h30",
        "Guide"
    )
    g.btnGuide.OnEvent("Click", (*) => ShowGuide(g))

    ; =========================================================
    ; EVENTS
    ; =========================================================

    g.inputEdit.OnEvent("Change", (*) => UpdateFileCount(g))

    g.lockOn := 1
    g._lockBusy := 0
    g._lockRatio := 0
    g._lockSuspended := 0
    g.pxLockOn := 1
    g._pxAspect := 1.0

    g.dpiEdit.OnEvent("Change", OnDpiChanged.Bind(g))
    g.scaleEdit.OnEvent("Change", OnScaleChanged.Bind(g))

    g.recursiveCheck.OnEvent("Click", (*) => UpdateFileCount(g))

    g.dpiFolderCheck.OnEvent("Click", (*) => UpdateOutputPath(g))

    g.outputEdit.OnEvent("Change", OnOutputChange)

    g.presetsDropdown.OnEvent("Change", (*) => LoadPresetToGui(g))

    g.btnSavePreset.OnEvent("Click", (*) => SavePresetFromGui(g))

    g.btnDeletePreset.OnEvent("Click", (*) => DeletePresetFromGui(g))

    g.btnInput.OnEvent("Click", (*) => SelectInput(g))

    g.btnOutput.OnEvent("Click", (*) => SelectOutput(g))

    g.btnStart.OnEvent("Click", (*) => StartBatch(g))

    g.btnOpenOutput.OnEvent("Click", (*) => Run(g.outputEdit.Value))

    g.OnEvent("Close", OnClose.Bind(g))

    g.OnEvent("Size", GuiResize.Bind(g))

    ; =========================================================
    ; DRAG DROP
    ; =========================================================

    g._dropHandler := OnDropFiles.Bind(g)
    OnMessage(0x0233, g._dropHandler)

    ; =========================================================
    ; SHOW
    ; =========================================================

    g.Show("w420 h670 Center")

    if FileExist(_SETTINGS_FILE)
        RestoreSession(g)

    if !g.HasProp("_restored") || !g._restored {
        EnsureAnimeKeyframeExists()
        ReloadPresetsDropdown(g)
        g.presetsDropdown.Choose("No Preset")
    }

    UpdateFileCount(g)

    SyncLock(g)
}
GetPresetNames() {
    names := ["No Preset"]
    if FileExist(_PRESETS_FILE) {
        sections := IniRead(_PRESETS_FILE)
        for s in StrSplit(sections, "`n")
            names.Push(s)
    }
    return names
}

LoadPresetToGui(g) {
    name := g.presetsDropdown.Text
    if name = "" || name = "No Preset"
        return
    if g.usePxCheck.Value {
        g.status.Text := "Presets not available in Pixel Size mode."
        return
    }
    scale := IniRead(_PRESETS_FILE, name, "Scale")
    dpi := IniRead(_PRESETS_FILE, name, "Dpi")
    quality := IniRead(_PRESETS_FILE, name, "Quality")
    format := IniRead(_PRESETS_FILE, name, "Format")
    savedLock := g.lockOn
    g._lockSuspended := 1
    if scale != ""
        g.scaleEdit.Value := scale
    if dpi != ""
        g.dpiEdit.Value := dpi
    if quality != ""
        g.jpegQuality.Value := quality
    if format != ""
        g.formatDropdown.Choose(GetFormatIndex(format))
    g._lockSuspended := 0
    if savedLock
        SyncLock(g)
    UpdateOutputPath(g)
    g.status.Text := "Loaded: " name
}

SavePresetFromGui(g) {
    ib := InputBox("Enter a name for the new preset:", "Save Preset")
    if ib.Result = "Cancel" || Trim(ib.Value) = ""
        return
    name := Trim(ib.Value)
    if name = "No Preset" {
        g.status.Text := "Cannot overwrite 'No Preset'."
        return
    }
    if FileExist(_PRESETS_FILE) {
        sections := IniRead(_PRESETS_FILE)
        for section in StrSplit(sections, "`n") {
            if section = name {
                mb := MsgBox("Preset '" name "' already exists. Overwrite?", "Confirm Overwrite", 4 + 48)
                if mb = "No"
                    return
                break
            }
        }
    }
    sv := Trim(g.scaleEdit.Value)
    IniWrite(sv != "" ? Integer(sv) : 100, _PRESETS_FILE, name, "Scale")
    dv := Trim(g.dpiEdit.Value)
    IniWrite(dv != "" ? Integer(dv) : 150, _PRESETS_FILE, name, "Dpi")
    IniWrite(g.jpegQuality.Value, _PRESETS_FILE, name, "Quality")
    IniWrite(g.formatDropdown.Text, _PRESETS_FILE, name, "Format")
    ReloadPresetsDropdown(g)
    g.presetsDropdown.Choose(name)
    g.status.Text := "Saved: " name
}

DeletePresetFromGui(g) {
    name := g.presetsDropdown.Text
    if name = "" || name = "No Preset" {
        g.status.Text := "No preset selected to delete."
        return
    }
    IniDelete(_PRESETS_FILE, name)
    ReloadPresetsDropdown(g)
    g.status.Text := "Deleted: " name
}

ReloadPresetsDropdown(g) {
    g.presetsDropdown.Delete()
    for name in GetPresetNames()
        g.presetsDropdown.Add([name])
    g.presetsDropdown.Choose(0)
}

GetFormatIndex(format) {
    formats := ["Keep Original", "PNG", "JPEG", "BMP", "TIFF"]
    for i, f in formats {
        if f = format
            return i
    }
    return 1
}

GetFormatExt(format) {
    if format = "PNG"
        return ".png"
    if format = "JPEG"
        return ".jpg"
    if format = "BMP"
        return ".bmp"
    if format = "TIFF"
        return ".tif"
    return ""
}

OnDropFiles(g, wParam, lParam, msg, hwnd) {
    if hwnd != g.Hwnd
        return
    count := DllCall("shell32\DragQueryFileW", "Ptr", wParam, "UInt", 0xFFFFFFFF, "Ptr", 0, "UInt", 0)
    if !count
        return
    length := DllCall("shell32\DragQueryFileW", "Ptr", wParam, "UInt", 0, "Ptr", 0, "UInt", 0) + 1
    buf := Buffer(length * 2)
    DllCall("shell32\DragQueryFileW", "Ptr", wParam, "UInt", 0, "Ptr", buf, "UInt", length)
    path := StrGet(buf)
    DllCall("shell32\DragFinish", "Ptr", wParam)
    if DirExist(path) {
        g.inputEdit.Value := path
        SyncFromSource(g)
    }
    else {
        SplitPath(path, , &fileDir)
        g.inputEdit.Value := fileDir
        SyncFromSource(g)
    }
    UpdateOutputPath(g, true)
    UpdateFileCount(g)
    return 1
}

OnClose(g, *) {
    SaveSession(g)
    ExitApp()
}

SaveSession(g) {
    s := _SETTINGS_FILE
    IniWrite(g.scaleEdit.Value, s, "LastSession", "Scale")
    IniWrite(g.dpiEdit.Value, s, "LastSession", "Dpi")
    IniWrite(g.jpegQuality.Value, s, "LastSession", "Quality")
    IniWrite(g.formatDropdown.Text, s, "LastSession", "Format")
    IniWrite(g.inputEdit.Value, s, "LastSession", "InputPath")
    IniWrite(g.outputEdit.Value, s, "LastSession", "OutputPath")
    IniWrite(g.recursiveCheck.Value, s, "LastSession", "Recursive")
    IniWrite(g.dpiFolderCheck.Value, s, "LastSession", "DpiFolder")
    IniWrite(g.lockOn, s, "LastSession", "LockCheck")
    IniWrite(g.patternEdit.Value, s, "LastSession", "Pattern")
    IniWrite(g.usePxCheck.Value, s, "LastSession", "UsePxMode")
    IniWrite(g.pxWidth.Value, s, "LastSession", "PxWidth")
    IniWrite(g.pxHeight.Value, s, "LastSession", "PxHeight")
    IniWrite(g.pxRatio.Value, s, "LastSession", "PxRatio")
    IniWrite(g.pxSecureDropdown.Text, s, "LastSession", "PxSecureMode")
    g.GetPos(&wx, &wy, &ww, &wh)
    IniWrite(wx, s, "Window", "X")
    IniWrite(wy, s, "Window", "Y")
    IniWrite(ww, s, "Window", "W")
    IniWrite(wh, s, "Window", "H")
}

RestoreSession(g) {
    s := _SETTINGS_FILE
    if !FileExist(s)
        return
    g._lockSuspended := 1
    try g.scaleEdit.Value := IniRead(s, "LastSession", "Scale")
    try g.dpiEdit.Value := IniRead(s, "LastSession", "Dpi")
    try g.jpegQuality.Value := IniRead(s, "LastSession", "Quality")
    try {
        fmt := IniRead(s, "LastSession", "Format")
        g.formatDropdown.Choose(GetFormatIndex(fmt))
    }
    try g.dpiFolderCheck.Value := IniRead(s, "LastSession", "DpiFolder")
    try g.outputEdit.Value := IniRead(s, "LastSession", "OutputPath")
    try g.inputEdit.Value := IniRead(s, "LastSession", "InputPath")
    try g.recursiveCheck.Value := IniRead(s, "LastSession", "Recursive")
    try g.patternEdit.Value := IniRead(s, "LastSession", "Pattern")
    try g.pxWidth.Value := IniRead(s, "LastSession", "PxWidth")
    try g.pxHeight.Value := IniRead(s, "LastSession", "PxHeight")
    try g.pxRatio.Value := IniRead(s, "LastSession", "PxRatio")
    try g.pxSecureDropdown.Value := IniRead(s, "LastSession", "PxSecureMode")
    try g.usePxCheck.Value := IniRead(s, "LastSession", "UsePxMode")
    g._lockSuspended := 0

    try g.lockOn := IniRead(s, "LastSession", "LockCheck", "0")
    if g.lockOn
        SyncLock(g)

    ; Apply PX mode visibility if saved state is PX
    if g.usePxCheck.Value
        TogglePxMode(g)

    ; sync output path with checkbox
    UpdateOutputPath(g)
    try {
        wx := IniRead(s, "Window", "X", "")
        wy := IniRead(s, "Window", "Y", "")
        if wx != "" && wy != ""
            g.Move(wx, wy)
    }
    g._restored := true
}

EnsureAnimeKeyframeExists() {
    if !FileExist(_PRESETS_FILE) {
        CreateDefaultPresets()
        return
    }
    sections := IniRead(_PRESETS_FILE)
    for section in StrSplit(sections, "`n") {
        if section = "Anime Keyframe"
            return
    }
    IniWrite(75, _PRESETS_FILE, "Anime Keyframe", "Scale")
    IniWrite(150, _PRESETS_FILE, "Anime Keyframe", "Dpi")
    IniWrite(100, _PRESETS_FILE, "Anime Keyframe", "Quality")
    IniWrite("JPEG", _PRESETS_FILE, "Anime Keyframe", "Format")
}

UpdateFileCount(g) {
    inputFolder := Trim(g.inputEdit.Value)
    if !DirExist(inputFolder) {
        g.fileCount.Text := ""
        return
    }
    recursive := g.recursiveCheck.Value
    extensions := ["png", "jpg", "jpeg", "bmp", "webp", "tif"]
    count := 0
    for ext in extensions {
        mode := recursive ? "R" : ""
        Loop Files inputFolder "\*." ext, mode
            count += 1
    }
    g.fileCount.Text := count " image" (count = 1 ? "" : "s") " found"
}

ToggleLock(g) {
    g.lockOn := !g.lockOn
    SyncLock(g)
}

SyncLock(g) {
    scale := Trim(g.scaleEdit.Value)
    dpi := Trim(g.dpiEdit.Value)
    g._lockRatio := g.lockOn && scale != "" && dpi != ""
        ? Max(Integer(scale), 1) / Max(Integer(dpi), 1)
        : 0
    g.lockIndicator.Opt(g.lockOn ? "c4CAF50" : "c666666")
}

SetQuickDpi(g, value, *) {
    if g.lockOn && g._lockRatio {
        g._lockBusy := 1
        g.scaleEdit.Value := Round(g._lockRatio * value)
        g.scaleEdit.Redraw()
        g._lockBusy := 0
    }
    g.dpiEdit.Value := value
    UpdateOutputPath(g)
}

OnDpiChanged(g, *) {
    if g._lockSuspended
        return
    UpdateOutputPath(g)
    if g.lockOn && !g._lockBusy && g._lockRatio {
        g._lockBusy := 1
        dpi := Trim(g.dpiEdit.Value)
        if dpi != "" {
            dpi := Max(Integer(dpi), 1)
            g.scaleEdit.Value := Round(g._lockRatio * dpi)
            g.scaleEdit.Redraw()
        }
        g._lockBusy := 0
    }
}

OnScaleChanged(g, *) {
    if g._lockSuspended
        return
    if g.lockOn && !g._lockBusy && g._lockRatio {
        g._lockBusy := 1
        scale := Trim(g.scaleEdit.Value)
        if scale != "" {
            scale := Max(Integer(scale), 1)
            g.dpiEdit.Value := Round(scale / g._lockRatio)
            g.dpiEdit.Redraw()
        }
        g._lockBusy := 0
    }
}

TogglePxMode(g) {
    isPx := g.usePxCheck.Value
    for _, name in ["ScaleLabel", "ScaleEdit", "ScaleLock", "DpiLabel", "DpiEdit"
        , "QuickDpiLabel"] {
        ctrl := g[name]
        if ctrl.HasProp("Enabled")
            ctrl.Enabled := !isPx
    }
    for _, name in ["PxWidthLabel", "PxWidth", "PxLock", "PxHeightLabel", "PxHeight"
        , "PxRatioLabel", "PxRatio", "PxRatioOrig", "PxRatio16_9", "PxRatio4_3", "PxRatio1_1"
        , "PxSecureLabel", "PxSecureMode", "PxResetBtn"] {
        ctrl := g[name]
        if ctrl.HasProp("Enabled")
            ctrl.Enabled := isPx
    }
    ; Quick DPI buttons and Reset
    g.quickDpiLabel.Enabled := !isPx
    for btn in g._dpiButtons
        btn.Enabled := !isPx
    g.btnReset.Enabled := !isPx
    if isPx
        OnPxSecureChange(g)
    UpdateOutputPath(g)
}

TogglePxLock(g) {
    if g.pxSecureDropdown.Text != "Auto"
        return
    g.pxLockOn := !g.pxLockOn
    g.pxLockIndicator.Opt(g.pxLockOn ? "c4CAF50" : "c666666")
}

OnPxSecureChange(g) {
    mode := g.pxSecureDropdown.Text
    g.pxLockOn := 1
    g.pxLockIndicator.Opt("c4CAF50")
    if mode = "Secure Height" {
        g.pxHeight.Enabled := 0
        g.pxWidth.Enabled := 1
        g.pxWidthLabel.Enabled := 1
        g.pxHeightLabel.Enabled := 0
        ; auto-calc height from current width
        w := Integer(Trim(g.pxWidth.Value))
        if w > 0
            g.pxHeight.Value := Round(w / g._pxAspect)
    } else if mode = "Secure Width" {
        g.pxWidth.Enabled := 0
        g.pxHeight.Enabled := 1
        g.pxWidthLabel.Enabled := 0
        g.pxHeightLabel.Enabled := 1
        ; auto-calc width from current height
        h := Integer(Trim(g.pxHeight.Value))
        if h > 0
            g.pxWidth.Value := Round(h * g._pxAspect)
    } else {
        ; Auto — both editable
        g.pxWidth.Enabled := 1
        g.pxHeight.Enabled := 1
        g.pxWidthLabel.Enabled := 1
        g.pxHeightLabel.Enabled := 1
    }
    UpdateOutputPath(g)
}

UpdatePxRatio(g) {
    w := Integer(Trim(g.pxWidth.Value))
    h := Integer(Trim(g.pxHeight.Value))
    g._pxAspect := (w > 0 && h > 0) ? w / h : 1.0
}

ApplyRatioFromInput(g) {
    ratioStr := Trim(g.pxRatio.Value)
    if ratioStr = "Original"
        ratioStr := ""
    if ratioStr != "" && RegExMatch(ratioStr, "(\d+)\s*:\s*(\d+)", &m) {
        aw := Integer(m[1])
        ah := Integer(m[2])
        if aw > 0 && ah > 0
            g._pxAspect := aw / ah
    } else {
        ; empty or invalid — derive from current W/H
        UpdatePxRatio(g)
    }
    UpdateOutputPath(g)
}

OnPxWidthChange(g, *) {
    if !g.pxLockOn || !g.usePxCheck.Value
        return
    ; In Secure Width mode, width is locked (auto from height)
    if g.pxSecureDropdown.Text = "Secure Width"
        return
    wVal := Trim(g.pxWidth.Value)
    if wVal = "" || Integer(wVal) < 1
        return
    w := Integer(wVal)
    if !g.HasOwnProp("_pxAspect") || g._pxAspect <= 0
        UpdatePxRatio(g)
    g.pxHeight.Value := Round(w / g._pxAspect)
    UpdateOutputPath(g)
}

OnPxHeightChange(g, *) {
    if !g.pxLockOn || !g.usePxCheck.Value
        return
    ; In Secure Height mode, height is locked (auto from width)
    if g.pxSecureDropdown.Text = "Secure Height"
        return
    hVal := Trim(g.pxHeight.Value)
    if hVal = "" || Integer(hVal) < 1
        return
    h := Integer(hVal)
    if !g.HasOwnProp("_pxAspect") || g._pxAspect <= 0
        UpdatePxRatio(g)
    g.pxWidth.Value := Round(h * g._pxAspect)
    UpdateOutputPath(g)
}

UpdateOutputPath(g, forceBase := false) {
    current := Trim(g.outputEdit.Value)
    ; strip DPI or PX suffix
    base := RegExReplace(current, "\\DPI_\d+$", "")
    base := RegExReplace(base, "\\[WH]\d+(?:_H\d+)?$", "")
    ; only auto-set base when forced (initial input select)
    if forceBase || base = "" {
        inputPath := Trim(g.inputEdit.Value)
        if inputPath = ""
            return
        base := inputPath
    }
    dpiVal := Trim(g.dpiEdit.Value)
    usePx := g.usePxCheck.Value
    if g.dpiFolderCheck.Value {
        if usePx {
            wVal := Trim(g.pxWidth.Value)
            hVal := Trim(g.pxHeight.Value)
            if wVal != "" {
                secureMode := g.pxSecureDropdown.Text
                if secureMode = "Secure Width"
                    g.outputEdit.Value := base "\H" hVal
                else if secureMode = "Secure Height"
                    g.outputEdit.Value := base "\W" wVal
                else
                    g.outputEdit.Value := base "\W" wVal "_H" hVal
            } else
                g.outputEdit.Value := base
        } else {
            g.outputEdit.Value := dpiVal != "" ? base "\DPI_" dpiVal : base
        }
    } else
        g.outputEdit.Value := base
}
OnOutputChange(ctrl, *) {
    static busy := false
    if busy
        return
    busy := true
    g := ctrl.Gui
    if !g.dpiFolderCheck.Value {
        busy := false
        return
    }
    current := Trim(g.outputEdit.Value)
    dpiVal := Trim(g.dpiEdit.Value)
    usePx := g.usePxCheck.Value
    if usePx {
        wVal := Trim(g.pxWidth.Value)
        hVal := Trim(g.pxHeight.Value)
        secureMode := g.pxSecureDropdown.Text
        if secureMode = "Secure Width" {
            if !RegExMatch(current, "\\H\d+$")
                g.outputEdit.Value := RTrim(current, "\") "\H" hVal
        } else if secureMode = "Secure Height" {
            if !RegExMatch(current, "\\W\d+$")
                g.outputEdit.Value := RTrim(current, "\") "\W" wVal
        } else {
            if !RegExMatch(current, "\\W\d+_H\d+$")
                g.outputEdit.Value := RTrim(current, "\") "\W" wVal "_H" hVal
        }
    } else {
        if dpiVal != "" && !RegExMatch(current, "\\DPI_\d+$")
            g.outputEdit.Value := RTrim(current, "\") "\DPI_" dpiVal
    }
    busy := false
}

ResetToSource(g, *) {
    inputFolder := RTrim(Trim(g.inputEdit.Value), "\")
    if !DirExist(inputFolder) {
        MsgBox("No input folder selected.")
        return
    }
    extList := ["png", "jpg", "jpeg", "bmp", "webp", "tif"]
    firstFile := ""
    for ext in extList {
        Loop Files inputFolder "\*." ext, "F" {
            firstFile := A_LoopFileFullPath
            break 2
        }
    }
    if firstFile = "" {
        MsgBox("No images found in input folder.")
        return
    }
    g.scaleEdit.Value := 100
    try {
        img := ComObject("WIA.ImageFile")
        img.LoadFile(firstFile)
        g.dpiEdit.Value := Round(img.HorizontalResolution)
        if g.usePxCheck.Value {
            g.pxWidth.Value := img.Width
            g.pxHeight.Value := img.Height
            g.pxRatio.Value := "Original"
            UpdatePxRatio(g)
        }
        img := ""
    } catch
        g.dpiEdit.Value := 72
    UpdateOutputPath(g)
}

ResetPxToSource(g, *) {
    inputFolder := RTrim(Trim(g.inputEdit.Value), "\")
    if !DirExist(inputFolder) {
        MsgBox("No input folder selected.")
        return
    }
    extList := ["png", "jpg", "jpeg", "bmp", "webp", "tif"]
    firstFile := ""
    for ext in extList {
        Loop Files inputFolder "\*." ext, "F" {
            firstFile := A_LoopFileFullPath
            break 2
        }
    }
    if firstFile = "" {
        MsgBox("No images found in input folder.")
        return
    }
    try {
        img := ComObject("WIA.ImageFile")
        img.LoadFile(firstFile)
        g.pxWidth.Value := img.Width
        g.pxHeight.Value := img.Height
        g.pxRatio.Value := "Original"
        UpdatePxRatio(g)
        img := ""
    } catch
        MsgBox("Could not read image dimensions.")
    UpdateOutputPath(g)
}

GuiResize(g, GuiObj, MinMax, Width, Height) {
    if MinMax = -1
        return
    if !g.HasProp("inputEdit")
        return
    m := g.MarginX
    editW := Width - m * 3 - 72
    g.inputEdit.Move(,, editW)
    g.inputEdit.GetPos(&ix)
    g.btnInput.Move(ix + editW + 6)
    g.outputEdit.Move(,, editW)
    g.outputEdit.GetPos(&ox)
    g.btnOutput.Move(ox + editW + 6)
    barW := Width - m * 2
    g.fileCount.Move(,, barW)
    g.progressBg.Move(,, barW)
    g.status.Move(,, barW)
    g.jpegQuality.Move(,, barW - 42)
    g.jpegQuality.GetPos(&jqx)
    g.jpegValueText.Move(jqx + barW - 42 + 10)
    third := Floor((barW - 20) / 3)
    g.btnStart.Move(,, third)
    g.btnStart.GetPos(&sx)
    g.btnOpenOutput.Move(sx + third + 10,, third)
    g.btnOpenOutput.GetPos(&ox)
    g.btnGuide.Move(ox + third + 10,, third)
}

IsValidFile(path) {
    SplitPath(path, , , &ext)
    ext := "." StrLower(ext)
    static valid := ["png", "jpg", "jpeg", "bmp", "tif", "tiff", "webp", "gif", "mp4"]
    for v in valid {
        if ext = "." v
            return true
    }
    return false
}


SelectInput(g) {
    dir := FileSelect("D", , "Select Input Folder")
    if dir = ""
        return
    files := CollectMediaFromFolder(dir)
    if files.Length = 0
        return
    g.inputEdit.Value := dir
    SyncFromSource(g)
    UpdateOutputPath(g, true)
    UpdateFileCount(g)
}

SelectOutput(g) {
    dir := FileSelect("D", , "Select Output Folder")
    if dir = ""
        return
    g.outputEdit.Value := dir
}

SyncFromSource(g) {
    inputFolder := RTrim(Trim(g.inputEdit.Value), "\")
    if !DirExist(inputFolder)
        return
    static valid := ["png", "jpg", "jpeg", "bmp", "tif", "tiff", "webp"]
    firstFile := ""
    for v in valid {
        Loop Files inputFolder "\*." v, "F" {
            firstFile := A_LoopFileFullPath
            break 2
        }
    }
    if firstFile = ""
        return
    try {
        img := ComObject("WIA.ImageFile")
        img.LoadFile(firstFile)
        dpi := Round(img.HorizontalResolution)
        if g.usePxCheck.Value {
            g.pxWidth.Value := img.Width
            g.pxHeight.Value := img.Height
            g.pxRatio.Value := "Original"
            UpdatePxRatio(g)
        }
        img := ""
    } catch
        dpi := 72
    g._lockBusy := 1
    g.scaleEdit.Value := 100
    g.dpiEdit.Value := dpi
    g._lockBusy := 0
    if g.lockOn
        SyncLock(g)
    UpdateOutputPath(g)
}

CollectMediaFromFolder(dir) {
    files := []
    Loop Files, dir "\*.*", "F" {
        if IsValidFile(A_LoopFileFullPath)
            files.Push(A_LoopFileFullPath)
    }
    return SortPathsNaturally(files)
}

SortPathsNaturally(paths) {
    sorted := paths.Clone()
    Loop sorted.Length {
        swapped := false
        Loop sorted.Length - 1 {
            if StrCompare(sorted[A_Index], sorted[A_Index + 1]) > 0 {
                tmp := sorted[A_Index]
                sorted[A_Index] := sorted[A_Index + 1]
                sorted[A_Index + 1] := tmp
                swapped := true
            }
        }
        if !swapped
            break
    }
    return sorted
}

StartBatch(g) {
    inputFolder := RTrim(Trim(g.inputEdit.Value), "\")
    outputFolder := RTrim(Trim(g.outputEdit.Value), "\")
    ; ensure DPI or PX suffix if checkbox is checked
    if g.dpiFolderCheck.Value {
        if g.usePxCheck.Value {
            wVal := Trim(g.pxWidth.Value)
            hVal := Trim(g.pxHeight.Value)
            secureMode := g.pxSecureDropdown.Text
            if secureMode = "Secure Width" {
                pxSuffix := "\H" hVal
                if !RegExMatch(outputFolder, "\\H\d+$")
                    outputFolder .= pxSuffix
            } else if secureMode = "Secure Height" {
                pxSuffix := "\W" wVal
                if !RegExMatch(outputFolder, "\\W\d+$")
                    outputFolder .= pxSuffix
            } else {
                pxSuffix := "\W" wVal "_H" hVal
                if !RegExMatch(outputFolder, "\\W\d+_H\d+$")
                    outputFolder .= pxSuffix
            }
        } else {
            dpiSuffix := "\DPI_" Trim(g.dpiEdit.Value)
            if !RegExMatch(outputFolder, "\\DPI_\d+$")
                outputFolder .= dpiSuffix
        }
    }
    usePx := g.usePxCheck.Value
    sv := Trim(g.scaleEdit.Value)
    scale := sv != "" ? Max(Integer(sv), 1) : 100
    dv := Trim(g.dpiEdit.Value)
    dpi := dv != "" ? Max(Integer(dv), 1) : 150
    jpegQuality := g.jpegQuality.Value
    formatChoice := g.formatDropdown.Text
    formatExt := GetFormatExt(formatChoice)
    overwrite := g.overwriteCheck.Value
    recursive := g.recursiveCheck.Value
    maxConcurrent := 4

    ; PX mode params
    if usePx {
        pxWidth := Max(Integer(Trim(g.pxWidth.Value)), 1)
        pxHeight := Max(Integer(Trim(g.pxHeight.Value)), 1)
        ratioStr := Trim(g.pxRatio.Value)
        if ratioStr = "Original"
            ratioStr := ""
        aspectW := 0
        aspectH := 0
        if ratioStr != "" {
            if RegExMatch(ratioStr, "(\d+)\s*:\s*(\d+)", &m) {
                aspectW := Integer(m[1])
                aspectH := Integer(m[2])
                if aspectW < 1 || aspectH < 1
                    aspectW := aspectH := 0
            }
        }
    }

    if !DirExist(inputFolder) {
        MsgBox("Input folder not found.")
        return
    }

    if (!overwrite && !DirExist(outputFolder))
        DirCreate(outputFolder)

    extensions := ["png", "jpg", "jpeg", "bmp", "webp", "tif"]
    files := []
    for ext in extensions {
        mode := recursive ? "R" : ""
        Loop Files inputFolder "\*." ext, mode
            files.Push({path: A_LoopFileFullPath, name: A_LoopFileName})
    }

    total := files.Length
    if (total = 0) {
        MsgBox("No images found.")
        return
    }

    psScript := A_ScriptDir "\Nastarxa Batch Image Resizer.ps1"
    pattern := g.patternEdit.Text
    g.progressFill.Move(,, 0)
    g.progressBg.GetPos(&_, &_, &barW)
    processed := 0
    finished := 0
    failedFiles := []
    active := []
    fileIndex := 1
    counter := 0

    while fileIndex <= total || active.Length > 0 {
        while fileIndex <= total && active.Length < maxConcurrent {
            f := files[fileIndex]
            filePath := f.path
            fileName := f.name
            SplitPath(filePath, , &dir)
            counter++

            if overwrite {
                outputPath := filePath
            } else {
                relative := SubStr(dir, StrLen(inputFolder) + 1)
                relative := Trim(relative, "\")
                outDir := relative != "" ? outputFolder "\" relative : outputFolder
                if !DirExist(outDir)
                    DirCreate(outDir)
                outputPath := outDir "\" fileName
            }

            if pattern != "" {
                SplitPath(filePath, , , &origExt, &stem)
                outExt := formatExt != "" ? formatExt : "." origExt
                outName := pattern
                outName := StrReplace(outName, "{name}", stem)
                outName := StrReplace(outName, "{ext}", outExt)
                outName := StrReplace(outName, "{counter}", counter)
                SplitPath(outputPath, , &outDir)
                outputPath := outDir "\" outName
            } else if formatExt != "" {
                SplitPath(outputPath, , &outDir, , &nameNoExt)
                outputPath := outDir "\" nameNoExt formatExt
            }

            if usePx {
                secureMode := g.pxSecureDropdown.Text
                if secureMode = "Secure Width" {
                    cmd := Format(
                        'powershell -NoProfile -ExecutionPolicy Bypass -File "{1}" -InputPath "{2}" -OutputPath "{3}" -Height {4} -Dpi {5} -JpegQuality {6} -UsePixelSize',
                        psScript, filePath, outputPath, pxHeight, dpi, jpegQuality
                    )
                } else {
                    cmd := Format(
                        'powershell -NoProfile -ExecutionPolicy Bypass -File "{1}" -InputPath "{2}" -OutputPath "{3}" -Width {4} -Dpi {5} -JpegQuality {6} -UsePixelSize',
                        psScript, filePath, outputPath, pxWidth, dpi, jpegQuality
                    )
                }
                if aspectW > 0
                    cmd .= ' -AspectW ' aspectW ' -AspectH ' aspectH
            } else {
                cmd := Format(
                    'powershell -NoProfile -ExecutionPolicy Bypass -File "{1}" -InputPath "{2}" -OutputPath "{3}" -Scale {4} -Dpi {5} -JpegQuality {6}',
                    psScript, filePath, outputPath, scale, dpi, jpegQuality
                )
            }

            Run(A_ComSpec ' /c ' cmd, , "Hide", &pid)
            active.Push({pid: pid, name: fileName})
            fileIndex++
        }

        loopLen := active.Length
        Loop loopLen {
            i := loopLen - A_Index + 1
            job := active[i]
            if !ProcessExist(job.pid) {
                exitCode := ProcessWaitClose(job.pid, 0)
                if exitCode != 0
                    failedFiles.Push(job.name)
                processed++
                active.RemoveAt(i)
                finished++
                progressPercent := Round((finished / total) * 100)
                g.progressFill.Move(,, Round(barW * progressPercent / 100))
                g.status.Text := Format("{1}/{2} : {3}", finished, total, job.name)
            }
        }

        Sleep 50
    }

    g.progressFill.Move(,, Round(barW))
    failedCount := failedFiles.Length
    successCount := processed - failedCount
    msg := Format("Processed {1} image(s).", processed)
    if failedCount > 0 {
        msg .= "`n`nFailed (" failedCount "):`n"
        for name in failedFiles
            msg .= "  " name "`n"
    }
    g.status.Text := Format("{1} done, {2} failed.", successCount, failedCount)
    MsgBox(msg)
}

ShowGuide(g) {
    static guideGui := ""
    if guideGui && WinExist(guideGui) {
        WinActivate(guideGui)
        return
    }
    guideGui := Gui("+Owner" g.Hwnd, "Guide — Nastarxa Batch Image Resizer")
    guideGui.BackColor := "2B2D31"
    guideGui.SetFont("s9", "Segoe UI")
    guideGui.MarginX := 14
    guideGui.MarginY := 12

    txt := "
    (
Nastarxa Batch Image Resizer

DPI MODE (default):
  Scale — percentage of original size.
  DPI — target DPI (dot per inch) for output.
  Quick DPI — one-click preset DPI buttons.
  Lock (🔗) — keep Scale and DPI proportional.

PIXEL SIZE MODE (check "Pixel Size"):
  Width / Height — fixed pixel dimensions.
  Aspect Ratio — constrain proportions (e.g. 16:9).
    "1:1" forces square; "Orig" uses original image ratio.
  Secure — choose which dimension is locked:
    Auto — both editable.
    Secure Height — height auto-calculated from width.
    Secure Width — width auto-calculated from height.

OUTPUT:
  Format — convert to PNG / JPEG / BMP / TIFF.
  JPEG Quality — compression level (1–100).
  Filename Pattern — rename using {name}, {ext}, {counter}.
  Overwrite — replace source files (no backup folder).
  Subfolders — include files in subdirectories.
  Make Folder — auto-name output folder by DPI or WxH.

PRESETS:
  Save and load DPI-mode settings presets.
  Not available in Pixel Size mode.
    )"

    guideGui.AddText("cCFCFCF", txt)
    guideGui.AddButton("xm y+12 w100 h26 Default", "OK").OnEvent(
        "Click", (*) => guideGui.Destroy()
    )
    guideGui.Show("w480 h460 Center")
}

ShowFileList(g) {
    inputDir := RTrim(Trim(g.inputEdit.Value), "\")
    if !DirExist(inputDir) {
        MsgBox("Input folder not found.")
        return
    }
    extensions := ["png", "jpg", "jpeg", "bmp", "webp", "tif"]
    files := []
    for ext in extensions {
        mode := g.recursiveCheck.Value ? "R" : ""
        Loop Files inputDir "\*." ext, mode
            files.Push(A_LoopFileName)
    }
    total := files.Length
    if total = 0 {
        MsgBox("No image files found in input folder.")
        return
    }

    listGui := Gui("+Owner" g.Hwnd, "File List — " total " image(s)")
    listGui.BackColor := "2B2D31"
    listGui.SetFont("s9", "Segoe UI")
    listGui.MarginX := 10
    listGui.MarginY := 10

    lv := listGui.AddListView("w500 h400 cCFCFCF Background1E1E1E", ["#", "Filename"])
    lv.SetFont("s9", "Segoe UI")
    lv.OnEvent("DoubleClick", OpenFileFromList.Bind(inputDir, lv))
    for i, name in files
        lv.Add("", i, name)

    listGui.AddButton("xm y+10 w80 h26 Default", "Close").OnEvent(
        "Click", (*) => listGui.Destroy()
    )
    listGui.Show("w520 h450 Center")
}

OpenFileFromList(inputDir, lv, *) {
    row := lv.GetNext()
    if row = 0
        return
    name := lv.GetText(row)
    try Run('explorer /select,"' inputDir '\' name '"')
}