#####################################################################
# show_properties.tcl - 属性自动显示工具
# 描述: 放置元器件后，自动显示封装(PCB Footprint)和耐压值(Voltage)
#       支持当前页/全设计/选中元件三种模式
#####################################################################

# 加载公共工具
set scriptDir [file dirname [info script]]
source [file join $scriptDir compat.tcl]
::OrcadTools::sourceScript [file join $scriptDir utils.tcl]

namespace eval ::OrcadTools::ShowProps {

    # 默认要显示的属性列表（可根据 CIS 数据库实际名称修改）
    variable PROP_LIST {
        "PCB Footprint"
        "VOLTAGE_RATING"
    }

    # 属性显示类型: 0=不显示, 1=仅显示值, 2=显示名称和值, 3=仅显示名称
    variable DISPLAY_TYPE 1
    # 0 = derive line spacing from the existing Value text; positive = override.
    if {![info exists LINE_SPACING]} { variable LINE_SPACING 0 }

    # Return a single unambiguous voltage token, or empty when none/conflicting.
    proc parseVoltage {description} {
        set values {}
        set pattern {(?i)(?:^|[^[:alnum:].])([0-9]+(?:\.[0-9]+)?)[ ]*(k?)[ ]*v(?:dc|ac)?(?![[:alnum:].])}
        foreach {match number kilo} [regexp -all -inline -- $pattern $description] {
            scan $number %f number
            if {$number <= 0} { continue }
            lappend values "[format %g $number][string toupper $kilo]V"
        }
        set pattern {(?i)(?:^|[^[:alnum:].])([0-9]+)v([0-9]+)(?![[:alnum:].])}
        foreach {match whole fraction} [regexp -all -inline -- $pattern $description] {
            set number "$whole.$fraction"
            scan $number %f number
            if {$number > 0} { lappend values "[format %g $number]V" }
        }
        set values [lsort -unique $values]
        if {[llength $values] == 1} { return [lindex $values 0] }
        return ""
    }

    proc isCapacitor {part refdes} {
        if {[regexp -nocase {^C[0-9]+$} $refdes]} { return 1 }
        if {[regexp -nocase {^R[0-9]+$} $refdes]} { return 0 }
        set type [::OrcadTools::getPartPropValue $part "Part Type"]
        return [regexp -nocase {^CAP(?:$|[^[:alnum:]])} $type]
    }

    proc populateVoltage {part refdes} {
        if {![isCapacitor $part $refdes]} { return "" }
        set existing [::OrcadTools::getPartPropValue $part VOLTAGE_RATING]
        if {[string trim $existing] ne ""} { return $existing }
        # A voltage in an IC description may be a supply range, not a rating.
        set description [::OrcadTools::getPartPropValue $part Description]
        set voltage [parseVoltage $description]
        if {$voltage eq ""} {
            ::OrcadTools::logWarn "${refdes}: Description has no unambiguous voltage; skipped."
            return ""
        }
        if {[::OrcadTools::setPartPropValue $part VOLTAGE_RATING $voltage] != 0} {
            error "OrCAD Tools: failed to store VOLTAGE_RATING for $refdes"
        }
        ::OrcadTools::log "${refdes}: Description -> VOLTAGE_RATING=$voltage"
        return $voltage
    }

    proc usesCombinedLabel {part refdes} {
        variable PROP_LIST
        return [expr {[isCapacitor $part $refdes] &&
            [lsearch -exact $PROP_LIST "PCB Footprint"] >= 0 &&
            [lsearch -exact $PROP_LIST VOLTAGE_RATING] >= 0}]
    }

    proc displayNames {part refdes} {
        variable PROP_LIST
        if {[usesCombinedLabel $part $refdes] &&
            [::OrcadTools::getPartPropValue $part CAP_PACKAGE_VOLTAGE] ne ""} {
            set names {}
            foreach name $PROP_LIST {
                if {$name eq "PCB Footprint"} { lappend names CAP_PACKAGE_VOLTAGE
                } elseif {$name ne "VOLTAGE_RATING"} { lappend names $name }
            }
            return $names
        }
        return $PROP_LIST
    }

    proc prepareCombinedLabel {part refdes status} {
        if {![usesCombinedLabel $part $refdes]} { return }
        set voltage [populateVoltage $part $refdes]
        set footprint [::OrcadTools::getPartPropValue $part "PCB Footprint"]
        if {$voltage eq "" || $footprint eq ""} { return }
        set value "$footprint/$voltage"
        if {[::OrcadTools::setPartPropValue $part CAP_PACKAGE_VOLTAGE $value] != 0} {
            error "OrCAD Tools: failed to store combined label for $refdes"
        }
        foreach name {"PCB Footprint" VOLTAGE_RATING} {
            set display [$part GetDisplayProp [::OrcadTools::makeCString $name] $status]
            if {$display ne "NULL" && $display ne ""} { $display SetDisplayType 0 }
        }
        ::OrcadTools::log "${refdes}: CAP_PACKAGE_VOLTAGE=$value"
    }

    #---------------------------------------------------------------
    # 为单个元件显示指定属性
    #---------------------------------------------------------------
    proc showPropsForPart {partInst} {
        variable PROP_LIST
        variable DISPLAY_TYPE
        set lStatus [DboState]
        set refdes [::OrcadTools::getRefDes $partInst]
        set shown 0
        set slot 0

        prepareCombinedLabel $partInst $refdes $lStatus
        foreach propName [displayNames $partInst $refdes] {
            if {$propName eq "VOLTAGE_RATING" && ![isCapacitor $partInst $refdes]} {
                # Hide old voltage text on resistors without deleting its data.
                set display [$partInst GetDisplayProp [::OrcadTools::makeCString $propName] $lStatus]
                if {$display ne "NULL" && $display ne ""} { $display SetDisplayType 0 }
                continue
            }
            incr slot
            if {$propName eq "VOLTAGE_RATING"} { populateVoltage $partInst $refdes }
            set lPropCStr [::OrcadTools::makeCString $propName]

            # 尝试获取 DisplayProp 对象
            set lDispProp [$partInst GetDisplayProp $lPropCStr $lStatus]

            if {$lDispProp != "NULL"} {
                # 属性存在，设置显示类型
                set currentType [$lDispProp GetDisplayType $lStatus]
                if {$currentType != $DISPLAY_TYPE} {
                    # 当前不显示，改为显示
                    $lDispProp SetDisplayType $DISPLAY_TYPE
                    ::OrcadTools::log "${refdes}: 显示属性 '$propName'"
                    incr shown
                } else {
                    ::OrcadTools::log "${refdes}: 属性 '$propName' 已在显示状态"
                }
            } else {
                # DisplayProp 不存在，尝试通过 EffectiveProp 获取值
                set propValue [::OrcadTools::getPartPropValue $partInst $propName]
                if {$propValue ne ""} {
                    # 属性有值但没有 DisplayProp，需要创建
                    # 使用 NewDisplayProp 添加显示属性
                    set lNewDisp [newDisplayProp $partInst $lPropCStr $lStatus $slot]
                    if {$lNewDisp != "NULL"} {
                        $lNewDisp SetDisplayType $DISPLAY_TYPE
                        ::OrcadTools::log "${refdes}: 创建并显示属性 '$propName' = $propValue"
                        incr shown
                    } else {
                        ::OrcadTools::log "${refdes}: 无法为 '$propName' 创建显示属性" "WARN"
                    }
                } else {
                    ::OrcadTools::log "${refdes}: 属性 '$propName' 不存在，跳过" "WARN"
                }
            }
        }
        return $shown
    }

    # Reuse a display-property anchor: a placed instance bounding box is in
    # page coordinates, while its display text uses symbol-local coordinates.
    proc displayLayout {partInst status slot} {
        variable LINE_SPACING
        foreach anchorName {Value "Part Reference" Reference} {
            set name [::OrcadTools::makeCString $anchorName]
            set anchor [$partInst GetDisplayProp $name $status]
            if {$anchor ne "NULL" && $anchor ne ""} {
                set point [$anchor GetLocation $status]
                set x [DboTclHelper_sGetCPointX $point]
                set y [DboTclHelper_sGetCPointY $point]
                set rotation [$anchor GetRotation $status]
                set box [$anchor GetBoundingBox]
                set tl [DboTclHelper_sGetCRectTopLeft $box]
                set br [DboTclHelper_sGetCRectBottomRight $box]
                set width [expr {abs([DboTclHelper_sGetCPointX $br] - [DboTclHelper_sGetCPointX $tl])}]
                set height [expr {abs([DboTclHelper_sGetCPointY $br] - [DboTclHelper_sGetCPointY $tl])}]
                set spacing $LINE_SPACING
                if {$spacing == 0} {
                    # The smaller bounding-box dimension is the text height
                    # for horizontal or vertical labels. Leave half a line gap.
                    set spacing [expr {max(10, int(ceil(min($width, $height) * 1.5)))}]
                }
                set offset [expr {(max($width, $height) + $spacing) * $slot}]
                # Keep each part's added labels on its existing text line:
                # horizontal labels extend right/left, vertical labels down.
                switch -- $rotation {
                    0 { incr x $offset }
                    1 { incr y $offset }
                    2 { incr x -$offset }
                    3 { incr y $offset }
                    default { error "OrCAD Tools: unsupported text rotation $rotation" }
                }
                set font [DboDisplayProp_sGetFont $anchor $status]
                return [list [DboTclHelper_sMakeCPoint $x $y] $rotation $font]
            }
        }
        error "OrCAD Tools: no Value/Reference display anchor; position the property manually."
    }

    # Explicit repair for selected parts only. Ordinary display calls keep
    # existing positions, including positions adjusted manually by the user.
    proc repositionSelected {} {
        variable PROP_LIST
        set status [DboState]
        set count 0
        foreach part [::OrcadTools::getSelectedParts] {
            set slot 0
            foreach name [displayNames $part [::OrcadTools::getRefDes $part]] {
                if {$name eq "VOLTAGE_RATING" && ![isCapacitor $part [::OrcadTools::getRefDes $part]]} {
                    continue
                }
                incr slot
                set display [$part GetDisplayProp [::OrcadTools::makeCString $name] $status]
                if {$display eq "NULL" || $display eq ""} { continue }
                foreach {location rotation font} [displayLayout $part $status $slot] { break }
                $display SetRotation $rotation
                $display SetFont $font
                $display SetLocation $location
                incr count
            }
        }
        ::OrcadTools::log "Repositioned $count display properties on selected parts."
        return $count
    }

    # Capture requires a position, rotation, font and color when creating text.
    proc newDisplayProp {partInst name status slot} {
        foreach {location rotation font} [displayLayout $partInst $status $slot] { break }
        set color 48
        if {[info exists ::DboValue_DEFAULT_OBJECT_COLOR]} {
            set color $::DboValue_DEFAULT_OBJECT_COLOR
        }
        return [$partInst NewDisplayProp $status $name $location $rotation $font $color]
    }

    #---------------------------------------------------------------
    # 对当前页面的所有元件执行属性显示
    #---------------------------------------------------------------
    proc showPropsCurrentPage {} {
        set lDesign [::OrcadTools::getActiveDesign]
        if {$lDesign == "NULL"} {
            ::OrcadTools::msgBoxWarn "错误" "没有打开的设计文件！"
            return
        }

        set lStatus [DboState]
        set totalParts 0
        set totalShown 0

        # 获取当前活动页面
        set lPage [GetActivePage]
        if {$lPage == "NULL"} {
            ::OrcadTools::msgBoxWarn "错误" "无法获取当前页面！"
            return
        }

        ::OrcadTools::log "=== 开始处理当前页面 ==="

        ::OrcadTools::forEachPart $lPage [list apply {{partInst} {
            upvar totalParts tp totalShown ts
            incr tp
            set count [::OrcadTools::ShowProps::showPropsForPart $partInst]
            set ts [expr {$ts + $count}]
        }}]

        set msg "当前页面处理完成！\n元件总数: $totalParts\n新显示属性: $totalShown"
        ::OrcadTools::log $msg
        ::OrcadTools::msgBox "属性显示" $msg
    }

    #---------------------------------------------------------------
    # 对全设计所有元件执行属性显示
    #---------------------------------------------------------------
    proc showPropsAllPages {} {
        set lDesign [::OrcadTools::getActiveDesign]
        if {$lDesign == "NULL"} {
            ::OrcadTools::msgBoxWarn "错误" "没有打开的设计文件！"
            return
        }

        set confirm [::OrcadTools::msgBoxConfirm "确认" "将对全部原理图页面执行属性显示，是否继续？"]
        if {$confirm ne "yes"} { return }

        set totalParts 0
        set totalShown 0

        ::OrcadTools::log "=== 开始处理全部页面 ==="

        ::OrcadTools::forEachPage $lDesign [list apply {{page pageIndex} {
            upvar totalParts tp totalShown ts
            ::OrcadTools::log "--- 处理第 [expr {$pageIndex + 1}] 页 ---"

            ::OrcadTools::forEachPart $page [list apply {{partInst} {
                upvar tp tp2 ts ts2
                incr tp2
                set count [::OrcadTools::ShowProps::showPropsForPart $partInst]
                set ts2 [expr {$ts2 + $count}]
            }}]
        }}]

        set msg "全设计处理完成！\n元件总数: $totalParts\n新显示属性: $totalShown"
        ::OrcadTools::log $msg
        ::OrcadTools::msgBox "属性显示" $msg
    }

    #---------------------------------------------------------------
    # 对选中的元件执行属性显示
    #---------------------------------------------------------------
    proc showPropsSelected {} {
        set selectedParts [::OrcadTools::getSelectedParts]
        if {[llength $selectedParts] == 0} {
            ::OrcadTools::msgBoxWarn "提示" "请先选中要处理的元件！"
            return
        }

        set totalShown 0
        ::OrcadTools::log "=== 处理选中的 [llength $selectedParts] 个元件 ==="

        foreach partInst $selectedParts {
            set count [showPropsForPart $partInst]
            set totalShown [expr {$totalShown + $count}]
        }

        set msg "处理完成！\n选中元件: [llength $selectedParts]\n新显示属性: $totalShown"
        ::OrcadTools::log $msg
        ::OrcadTools::msgBox "属性显示" $msg
    }

    #---------------------------------------------------------------
    # GUI 界面
    #---------------------------------------------------------------
    proc showGUI {} {
        ::OrcadTools::ensureTk
        variable PROP_LIST
        variable DISPLAY_TYPE

        # 创建或激活窗口
        set w .showPropsGUI
        if {[winfo exists $w]} {
            wm deiconify $w
            raise $w
            return
        }

        toplevel $w
        wm title $w "显示封装/耐压属性"
        wm geometry $w 400x380
        wm resizable $w 0 0

        # === 属性配置区 ===
        labelframe $w.props -text "要显示的属性" -padx 10 -pady 5
        pack $w.props -fill x -padx 10 -pady 5

        set idx 0
        foreach prop $PROP_LIST {
            set varName "::OrcadTools::ShowProps::propCheck_$idx"
            set $varName 1
            checkbutton $w.props.cb$idx -text $prop -variable $varName
            pack $w.props.cb$idx -anchor w
            incr idx
        }

        # 自定义属性输入
        frame $w.props.custom
        pack $w.props.custom -fill x -pady 3
        label $w.props.custom.lbl -text "自定义属性:"
        entry $w.props.custom.entry -textvariable ::OrcadTools::ShowProps::customProp -width 25
        button $w.props.custom.add -text "添加" -command {
            if {$::OrcadTools::ShowProps::customProp ne ""} {
                lappend ::OrcadTools::ShowProps::PROP_LIST $::OrcadTools::ShowProps::customProp
                set ::OrcadTools::ShowProps::customProp ""
                destroy .showPropsGUI
                ::OrcadTools::ShowProps::showGUI
            }
        }
        pack $w.props.custom.lbl -side left
        pack $w.props.custom.entry -side left -padx 5
        pack $w.props.custom.add -side left

        # === 显示方式 ===
        labelframe $w.disptype -text "显示方式" -padx 10 -pady 5
        pack $w.disptype -fill x -padx 10 -pady 5

        radiobutton $w.disptype.r1 -text "仅显示值 (推荐)" -variable ::OrcadTools::ShowProps::DISPLAY_TYPE -value 1
        radiobutton $w.disptype.r2 -text "显示名称和值" -variable ::OrcadTools::ShowProps::DISPLAY_TYPE -value 2
        radiobutton $w.disptype.r3 -text "仅显示名称" -variable ::OrcadTools::ShowProps::DISPLAY_TYPE -value 3
        pack $w.disptype.r1 -anchor w
        pack $w.disptype.r2 -anchor w
        pack $w.disptype.r3 -anchor w

        # === 操作按钮 ===
        labelframe $w.actions -text "应用范围" -padx 10 -pady 5
        pack $w.actions -fill x -padx 10 -pady 10

        button $w.actions.selected -text "选中元件" -width 15 \
            -command { ::OrcadTools::ShowProps::updatePropList; ::OrcadTools::ShowProps::showPropsSelected }
        button $w.actions.page -text "当前页面" -width 15 \
            -command { ::OrcadTools::ShowProps::updatePropList; ::OrcadTools::ShowProps::showPropsCurrentPage }
        button $w.actions.all -text "全部页面" -width 15 \
            -command { ::OrcadTools::ShowProps::updatePropList; ::OrcadTools::ShowProps::showPropsAllPages }

        pack $w.actions.selected -side left -padx 5 -pady 5
        pack $w.actions.page -side left -padx 5 -pady 5
        pack $w.actions.all -side left -padx 5 -pady 5

        # 关闭按钮
        button $w.close -text "关闭" -command "destroy $w" -width 10
        pack $w.close -pady 10
    }

    #---------------------------------------------------------------
    # 根据 GUI checkbox 更新属性列表
    #---------------------------------------------------------------
    proc updatePropList {} {
        variable PROP_LIST
        set newList {}
        set idx 0
        foreach prop $PROP_LIST {
            set varName "::OrcadTools::ShowProps::propCheck_$idx"
            if {[info exists $varName] && [set $varName]} {
                lappend newList $prop
            }
            incr idx
        }
        set PROP_LIST $newList
    }
}

# 提供快捷命令
proc ShowProperties {} { ::OrcadTools::ShowProps::showGUI }

::OrcadTools::log "属性显示工具 (show_properties.tcl) 已加载 - 输入 ShowProperties 打开界面"

proc RepositionProperties {{spacing ""}} {
    if {$spacing ne ""} {
        if {![string is integer -strict $spacing] || $spacing < 0} {
            error "Usage: RepositionProperties ?nonnegative line spacing? (0 = automatic)"
        }
        set ::OrcadTools::ShowProps::LINE_SPACING $spacing
    }
    ::OrcadTools::ShowProps::repositionSelected
}
