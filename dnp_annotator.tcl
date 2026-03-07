#####################################################################
# dnp_annotator.tcl - DNP 不上件快捷标注工具
# 作者: Jerry Silicon
# 日期: 2026-03-06
# 描述: 选中元件后一键在 Value 属性前添加/移除 * 号标记 DNP
#       支持 Toggle 模式、批量操作
#####################################################################

# 加载公共工具
set scriptDir [file dirname [info script]]
source [file join $scriptDir utils.tcl]

namespace eval ::OrcadTools::DNP {

    # DNP 标记前缀
    variable DNP_PREFIX "*"

    # 是否同时添加/移除 DNP 自定义属性
    variable ADD_DNP_PROP 1

    #---------------------------------------------------------------
    # 检查元件是否已标记为 DNP
    #---------------------------------------------------------------
    proc isDNP {partInst} {
        variable DNP_PREFIX
        set value [::OrcadTools::getPartPropValue $partInst "Value"]
        if {[string index $value 0] eq $DNP_PREFIX} {
            return 1
        }
        return 0
    }

    #---------------------------------------------------------------
    # 标记单个元件为 DNP (添加 * 前缀)
    #---------------------------------------------------------------
    proc markDNP {partInst} {
        variable DNP_PREFIX
        variable ADD_DNP_PROP
        set lStatus [DboState]
        set refdes [::OrcadTools::getRefDes $partInst]
        set value [::OrcadTools::getPartPropValue $partInst "Value"]

        if {[string index $value 0] eq $DNP_PREFIX} {
            ::OrcadTools::log "$refdes: 已是 DNP 状态，跳过"
            return 0
        }

        # 添加 * 前缀
        set newValue "${DNP_PREFIX}${value}"
        set result [::OrcadTools::setPartPropValue $partInst "Value" $newValue]

        if {$result == 0} {
            ::OrcadTools::log "$refdes: 标记 DNP -> Value=\"$newValue\""

            # 可选：添加 DNP 自定义属性
            if {$ADD_DNP_PROP} {
                ::OrcadTools::setPartPropValue $partInst "DNP" "YES"
            }
            return 1
        } else {
            ::OrcadTools::logError "$refdes: DNP 标记失败 (错误码: $result)"
            return 0
        }
    }

    #---------------------------------------------------------------
    # 取消单个元件的 DNP 标记 (移除 * 前缀)
    #---------------------------------------------------------------
    proc unmarkDNP {partInst} {
        variable DNP_PREFIX
        variable ADD_DNP_PROP
        set lStatus [DboState]
        set refdes [::OrcadTools::getRefDes $partInst]
        set value [::OrcadTools::getPartPropValue $partInst "Value"]

        if {[string index $value 0] ne $DNP_PREFIX} {
            ::OrcadTools::log "$refdes: 不是 DNP 状态，跳过"
            return 0
        }

        # 移除 * 前缀
        set newValue [string range $value 1 end]
        set result [::OrcadTools::setPartPropValue $partInst "Value" $newValue]

        if {$result == 0} {
            ::OrcadTools::log "$refdes: 取消 DNP -> Value=\"$newValue\""

            # 可选：移除 DNP 自定义属性
            if {$ADD_DNP_PROP} {
                ::OrcadTools::setPartPropValue $partInst "DNP" ""
            }
            return 1
        } else {
            ::OrcadTools::logError "$refdes: 取消 DNP 失败 (错误码: $result)"
            return 0
        }
    }

    #---------------------------------------------------------------
    # Toggle DNP 状态 (选中元件)
    #---------------------------------------------------------------
    proc toggleSelectedDNP {} {
        set selectedParts [::OrcadTools::getSelectedParts]
        if {[llength $selectedParts] == 0} {
            ::OrcadTools::msgBoxWarn "提示" "请先选中要标注的元件！\n\n使用方法：\n1. 在原理图中选中一个或多个元件\n2. 再次点击此按钮"
            return
        }

        set markedCount 0
        set unmarkedCount 0
        set totalCount [llength $selectedParts]

        ::OrcadTools::log "=== DNP Toggle: 处理 $totalCount 个元件 ==="

        foreach partInst $selectedParts {
            if {[isDNP $partInst]} {
                # 已标记，取消
                set result [unmarkDNP $partInst]
                if {$result} { incr unmarkedCount }
            } else {
                # 未标记，添加
                set result [markDNP $partInst]
                if {$result} { incr markedCount }
            }
        }

        set msg "DNP Toggle 完成！\n\n"
        append msg "处理元件: $totalCount\n"
        if {$markedCount > 0} {
            append msg "新标记 DNP: $markedCount\n"
        }
        if {$unmarkedCount > 0} {
            append msg "取消 DNP: $unmarkedCount\n"
        }

        ::OrcadTools::log $msg
        ::OrcadTools::msgBox "DNP 标注" $msg
    }

    #---------------------------------------------------------------
    # 批量标记 DNP (选中元件)
    #---------------------------------------------------------------
    proc markSelectedDNP {} {
        set selectedParts [::OrcadTools::getSelectedParts]
        if {[llength $selectedParts] == 0} {
            ::OrcadTools::msgBoxWarn "提示" "请先选中要标注 DNP 的元件！"
            return
        }

        set count 0
        ::OrcadTools::log "=== 批量标记 DNP: [llength $selectedParts] 个元件 ==="

        foreach partInst $selectedParts {
            set result [markDNP $partInst]
            if {$result} { incr count }
        }

        set msg "批量标记完成！\n成功标记 $count / [llength $selectedParts] 个元件为 DNP"
        ::OrcadTools::log $msg
        ::OrcadTools::msgBox "DNP 标注" $msg
    }

    #---------------------------------------------------------------
    # 批量取消 DNP (选中元件)
    #---------------------------------------------------------------
    proc unmarkSelectedDNP {} {
        set selectedParts [::OrcadTools::getSelectedParts]
        if {[llength $selectedParts] == 0} {
            ::OrcadTools::msgBoxWarn "提示" "请先选中要取消 DNP 的元件！"
            return
        }

        set count 0
        ::OrcadTools::log "=== 批量取消 DNP: [llength $selectedParts] 个元件 ==="

        foreach partInst $selectedParts {
            set result [unmarkDNP $partInst]
            if {$result} { incr count }
        }

        set msg "批量取消完成！\n成功取消 $count / [llength $selectedParts] 个元件的 DNP"
        ::OrcadTools::log $msg
        ::OrcadTools::msgBox "DNP 标注" $msg
    }

    #---------------------------------------------------------------
    # 扫描全设计，统计 DNP 元件
    #---------------------------------------------------------------
    proc scanAllDNP {} {
        set lDesign [::OrcadTools::getActiveDesign]
        if {$lDesign == "NULL"} {
            ::OrcadTools::msgBoxWarn "错误" "没有打开的设计文件！"
            return
        }

        set lStatus [DboState]
        set dnpList {}
        set normalList {}

        set lSchematicIter [$lDesign GetSchematicsIter $lStatus]
        while {$lSchematicIter != "NULL"} {
            set lSchematic $lSchematicIter
            set lPageIter [$lSchematic GetPagesIter $lStatus]
            while {$lPageIter != "NULL"} {
                set lPage $lPageIter
                set lPageName [::OrcadTools::getCString [$lPage GetName]]

                set lPartInst [$lPage GetPartInstsIter $lStatus]
                while {$lPartInst != "NULL"} {
                    set refdes [::OrcadTools::getRefDes $lPartInst]
                    set value [::OrcadTools::getPartPropValue $lPartInst "Value"]

                    if {[isDNP $lPartInst]} {
                        lappend dnpList [list $refdes $lPageName $value]
                    }
                    set lPartInst [$lPage GetPartInstsIterNext $lStatus]
                }
                set lPageIter [$lSchematic GetPagesIterNext $lStatus]
            }
            set lSchematicIter [$lDesign GetSchematicsIterNext $lStatus]
        }

        return $dnpList
    }

    #---------------------------------------------------------------
    # GUI 界面
    #---------------------------------------------------------------
    proc showGUI {} {
        variable DNP_PREFIX
        variable ADD_DNP_PROP

        set w .dnpGUI
        if {[winfo exists $w]} {
            wm deiconify $w
            raise $w
            return
        }

        toplevel $w
        wm title $w "DNP 不上件标注"
        wm geometry $w 450x450
        wm resizable $w 0 0

        # === 快捷操作区 ===
        labelframe $w.quick -text "快捷操作 (对选中元件)" -padx 10 -pady 8
        pack $w.quick -fill x -padx 10 -pady 5

        button $w.quick.toggle -text "⚡ Toggle DNP (推荐)" -width 20 -height 2 \
            -command { ::OrcadTools::DNP::toggleSelectedDNP }
        pack $w.quick.toggle -pady 5

        frame $w.quick.btns
        pack $w.quick.btns -fill x -pady 3
        button $w.quick.btns.mark -text "➕ 批量标记 DNP" -width 18 \
            -command { ::OrcadTools::DNP::markSelectedDNP }
        button $w.quick.btns.unmark -text "➖ 批量取消 DNP" -width 18 \
            -command { ::OrcadTools::DNP::unmarkSelectedDNP }
        pack $w.quick.btns.mark -side left -padx 5
        pack $w.quick.btns.unmark -side left -padx 5

        # === 设置区 ===
        labelframe $w.settings -text "设置" -padx 10 -pady 5
        pack $w.settings -fill x -padx 10 -pady 5

        frame $w.settings.prefix
        pack $w.settings.prefix -fill x -pady 3
        label $w.settings.prefix.lbl -text "DNP 前缀符号:" -width 14 -anchor e
        entry $w.settings.prefix.entry -textvariable ::OrcadTools::DNP::DNP_PREFIX -width 5
        label $w.settings.prefix.hint -text "(默认: * 星号)" -foreground gray
        pack $w.settings.prefix.lbl -side left
        pack $w.settings.prefix.entry -side left -padx 5
        pack $w.settings.prefix.hint -side left

        checkbutton $w.settings.addprop -text "同时添加/移除 DNP 自定义属性 (便于 BOM 过滤)" \
            -variable ::OrcadTools::DNP::ADD_DNP_PROP
        pack $w.settings.addprop -anchor w -pady 3

        # === 全设计 DNP 统计 ===
        labelframe $w.scan -text "全设计 DNP 统计" -padx 10 -pady 5
        pack $w.scan -fill both -expand 1 -padx 10 -pady 5

        button $w.scan.btn -text "📊 扫描全设计 DNP 元件" -command {
            ::OrcadTools::DNP::doScanGUI
        }
        pack $w.scan.btn -pady 3

        text $w.scan.text -width 50 -height 8 \
            -yscrollcommand "$w.scan.sb set" -wrap none -state disabled \
            -font {Courier 9}
        scrollbar $w.scan.sb -command "$w.scan.text yview"
        pack $w.scan.sb -side right -fill y
        pack $w.scan.text -side left -fill both -expand 1

        # === 使用说明 ===
        label $w.hint -text "使用方法: 在原理图中选中元件 → 点击 Toggle/标记/取消" \
            -foreground gray -font {TkDefaultFont 9}
        pack $w.hint -pady 3

        # 关闭
        button $w.close -text "关闭" -command "destroy $w" -width 10
        pack $w.close -pady 5
    }

    #---------------------------------------------------------------
    # GUI: 扫描全设计 DNP
    #---------------------------------------------------------------
    proc doScanGUI {} {
        set dnpList [scanAllDNP]
        set count [llength $dnpList]

        set w .dnpGUI
        set txt $w.scan.text
        $txt configure -state normal
        $txt delete 1.0 end

        if {$count == 0} {
            $txt insert end "全设计中没有 DNP 标记的元件\n"
        } else {
            $txt insert end "共找到 $count 个 DNP 元件:\n"
            $txt insert end [string repeat "-" 55]
            $txt insert end "\n"
            $txt insert end [format "%-12s %-20s %-20s\n" "REFDES" "页面" "Value"]
            $txt insert end [string repeat "-" 55]
            $txt insert end "\n"
            foreach item $dnpList {
                set refdes [lindex $item 0]
                set pageName [lindex $item 1]
                set value [lindex $item 2]
                $txt insert end [format "%-12s %-20s %-20s\n" $refdes $pageName $value]
            }
        }

        $txt configure -state disabled
    }
}

# 提供快捷命令
proc DNPToggle {} { ::OrcadTools::DNP::toggleSelectedDNP }
proc DNPMark {}   { ::OrcadTools::DNP::markSelectedDNP }
proc DNPUnmark {} { ::OrcadTools::DNP::unmarkSelectedDNP }
proc DNPTool {}   { ::OrcadTools::DNP::showGUI }

::OrcadTools::log "DNP 标注工具 (dnp_annotator.tcl) 已加载"
::OrcadTools::log "  快捷命令: DNPToggle / DNPMark / DNPUnmark / DNPTool"
