#####################################################################
# bulk_replace_part.tcl - 批量物料替换工具
# 描述: 一键将原理图中所有相同物料（Value 或 Part Number）
#       替换为新的物料，保留 REFDES 和位置
#####################################################################

# 加载公共工具
set scriptDir [file dirname [info script]]
source [file join $scriptDir compat.tcl]
::OrcadTools::sourceScript [file join $scriptDir utils.tcl]

namespace eval ::OrcadTools::BulkReplace {

    # 替换日志
    variable replaceLog {}

    #---------------------------------------------------------------
    # 扫描全设计，查找匹配的元件
    # matchProp: 匹配的属性名 (Value / Part Number / PCB Footprint)
    # matchValue: 要匹配的值
    # 返回: {refdes page propValue} 的列表
    #---------------------------------------------------------------
    proc scanDesign {matchProp matchValue} {
        set lDesign [::OrcadTools::getActiveDesign]
        if {$lDesign == "NULL"} { return {} }

        set results {}
        ::OrcadTools::forEachPage $lDesign [list apply {{matchProp matchValue page pageIndex} {
            upvar 1 results results
            set name [::OrcadTools::makeCString ""]
            $page GetName $name
            set pageName [::OrcadTools::getCString $name]
            ::OrcadTools::forEachPart $page [list apply {{matchProp matchValue pageName part} {
                upvar 1 results results
                set value [::OrcadTools::getPartPropValue $part $matchProp]
                if {$value eq $matchValue} {
                    lappend results [list [::OrcadTools::getRefDes $part] $pageName $value $part]
                }
            }} $matchProp $matchValue $pageName]
        }} $matchProp $matchValue]
        return $results
    }

    #---------------------------------------------------------------
    # 执行批量替换
    # matchProp: 匹配的属性名
    # oldValue: 旧值
    # newValue: 新值
    # replaceProp: 要替换的属性名（可以与 matchProp 不同）
    #---------------------------------------------------------------
    proc executeReplace {matchProp oldValue newValue {replaceProp ""}} {
        variable replaceLog

        if {$replaceProp eq ""} {
            set replaceProp $matchProp
        }

        set results [scanDesign $matchProp $oldValue]
        if {[llength $results] == 0} {
            ::OrcadTools::msgBoxWarn "未找到匹配" "未找到 $matchProp = \"$oldValue\" 的元件"
            return 0
        }

        set replaceLog {}
        set successCount 0
        set failCount 0

        foreach item $results {
            set refdes [lindex $item 0]
            set pageName [lindex $item 1]
            set partInst [lindex $item 3]

            set failed [catch {
                set result [::OrcadTools::setPartPropValue $partInst $replaceProp $newValue]
            } reason]
            if {$failed} { set result $reason }
            if {!$failed && $result == 0} {
                incr successCount
                lappend replaceLog [list $refdes $pageName $oldValue $newValue "成功"]
                ::OrcadTools::log "$refdes ($pageName): $replaceProp \"$oldValue\" -> \"$newValue\" 成功"
            } else {
                incr failCount
                lappend replaceLog [list $refdes $pageName $oldValue $newValue "失败"]
                ::OrcadTools::logError "$refdes ($pageName): 替换失败 (错误码: $result)"
            }
        }

        return $successCount
    }

    #---------------------------------------------------------------
    # 导出替换日志
    #---------------------------------------------------------------
    proc exportLog {filename} {
        variable replaceLog
        if {[llength $replaceLog] == 0} {
            ::OrcadTools::msgBoxWarn "提示" "没有可导出的替换记录"
            return
        }

        set f [open $filename w]
        puts $f "REFDES,页面,旧值,新值,状态"
        foreach entry $replaceLog {
            puts $f [join $entry ","]
        }
        close $f
        ::OrcadTools::log "替换日志已导出: $filename"
        ::OrcadTools::msgBox "导出成功" "替换日志已保存至:\n$filename"
    }

    #---------------------------------------------------------------
    # GUI 界面
    #---------------------------------------------------------------
    proc showGUI {} {
        ::OrcadTools::ensureTk
        set w .bulkReplaceGUI
        if {[winfo exists $w]} {
            wm deiconify $w
            raise $w
            return
        }

        toplevel $w
        wm title $w "批量物料替换"
        wm geometry $w 500x510
        wm resizable $w 0 0

        # === 匹配模式 ===
        labelframe $w.mode -text "匹配模式" -padx 10 -pady 5
        pack $w.mode -fill x -padx 10 -pady 5

        set ::OrcadTools::BulkReplace::matchMode "Value"
        radiobutton $w.mode.r1 -text "按 Value 匹配 (如: 100nF/25V)" \
            -variable ::OrcadTools::BulkReplace::matchMode -value "Value"
        radiobutton $w.mode.r2 -text "按 Part Number 匹配 (如: CL05A104KP5NNNC)" \
            -variable ::OrcadTools::BulkReplace::matchMode -value "Part Number"
        radiobutton $w.mode.r3 -text "按 PCB Footprint 匹配 (如: CC0805)" \
            -variable ::OrcadTools::BulkReplace::matchMode -value "PCB Footprint"
        pack $w.mode.r1 -anchor w
        pack $w.mode.r2 -anchor w
        pack $w.mode.r3 -anchor w

        # === 输入区 ===
        labelframe $w.input -text "替换参数" -padx 10 -pady 5
        pack $w.input -fill x -padx 10 -pady 5

        frame $w.input.old
        pack $w.input.old -fill x -pady 3
        label $w.input.old.lbl -text "旧物料值:" -width 12 -anchor e
        entry $w.input.old.entry -textvariable ::OrcadTools::BulkReplace::oldVal -width 35
        pack $w.input.old.lbl -side left
        pack $w.input.old.entry -side left -padx 5 -fill x -expand 1

        frame $w.input.new
        pack $w.input.new -fill x -pady 3
        label $w.input.new.lbl -text "新物料值:" -width 12 -anchor e
        entry $w.input.new.entry -textvariable ::OrcadTools::BulkReplace::newVal -width 35
        pack $w.input.new.lbl -side left
        pack $w.input.new.entry -side left -padx 5 -fill x -expand 1

        # === 操作按钮 ===
        frame $w.buttons
        pack $w.buttons -fill x -padx 10 -pady 5

        button $w.buttons.scan -text "扫描匹配" -width 15 -command {
            ::OrcadTools::BulkReplace::doScan
        }
        button $w.buttons.replace -text "执行替换" -width 15 -command {
            ::OrcadTools::BulkReplace::doReplace
        }
        button $w.buttons.export -text "导出日志" -width 15 -command {
            ::OrcadTools::BulkReplace::doExport
        }

        pack $w.buttons.scan -side left -padx 5
        pack $w.buttons.replace -side left -padx 5
        pack $w.buttons.export -side left -padx 5

        # === 结果列表 ===
        labelframe $w.results -text "匹配结果" -padx 10 -pady 5
        pack $w.results -fill both -expand 1 -padx 10 -pady 5

        # 创建 Treeview 风格的列表
        frame $w.results.list
        pack $w.results.list -fill both -expand 1

        text $w.results.list.text -width 55 -height 10 \
            -yscrollcommand "$w.results.list.sb set" -wrap none -state disabled \
            -font {Courier 9}
        scrollbar $w.results.list.sb -command "$w.results.list.text yview"
        pack $w.results.list.sb -side right -fill y
        pack $w.results.list.text -side left -fill both -expand 1

        # 状态栏
        label $w.status -text "就绪" -relief sunken -anchor w
        pack $w.status -fill x -padx 10 -pady 5

        # 关闭按钮
        button $w.close -text "关闭" -command "destroy $w" -width 10
        pack $w.close -pady 5
    }

    #---------------------------------------------------------------
    # GUI 操作: 扫描
    #---------------------------------------------------------------
    proc doScan {} {
        variable ::OrcadTools::BulkReplace::matchMode
        variable ::OrcadTools::BulkReplace::oldVal

        if {$oldVal eq ""} {
            ::OrcadTools::msgBoxWarn "提示" "请输入旧物料值！"
            return
        }

        set results [scanDesign $matchMode $oldVal]
        set count [llength $results]

        # 更新结果列表
        set w .bulkReplaceGUI
        set txt $w.results.list.text
        $txt configure -state normal
        $txt delete 1.0 end

        if {$count == 0} {
            $txt insert end "未找到匹配的元件\n"
        } else {
            $txt insert end [format "%-12s %-20s %-25s\n" "REFDES" "页面" "$matchMode"]
            $txt insert end [string repeat "-" 60]
            $txt insert end "\n"
            foreach item $results {
                set refdes [lindex $item 0]
                set pageName [lindex $item 1]
                set propVal [lindex $item 2]
                $txt insert end [format "%-12s %-20s %-25s\n" $refdes $pageName $propVal]
            }
        }

        $txt configure -state disabled
        $w.status configure -text "扫描完成：找到 $count 个匹配元件"
    }

    #---------------------------------------------------------------
    # GUI 操作: 替换
    #---------------------------------------------------------------
    proc doReplace {} {
        variable ::OrcadTools::BulkReplace::matchMode
        variable ::OrcadTools::BulkReplace::oldVal
        variable ::OrcadTools::BulkReplace::newVal

        if {$oldVal eq ""} {
            ::OrcadTools::msgBoxWarn "提示" "请输入旧物料值！"
            return
        }
        if {$newVal eq ""} {
            ::OrcadTools::msgBoxWarn "提示" "请输入新物料值！"
            return
        }

        # 先扫描确认
        set results [scanDesign $matchMode $oldVal]
        set count [llength $results]

        if {$count == 0} {
            ::OrcadTools::msgBoxWarn "未找到" "未找到匹配的元件"
            return
        }

        set confirm [::OrcadTools::msgBoxConfirm "确认替换" \
            "将替换 $count 个元件的 $matchMode:\n\"$oldVal\" → \"$newVal\"\n\n是否继续？"]
        if {$confirm ne "yes"} { return }

        set successCount [executeReplace $matchMode $oldVal $newVal]

        set w .bulkReplaceGUI
        $w.status configure -text "替换完成：成功 $successCount / $count 个"

        ::OrcadTools::msgBox "替换完成" \
            "替换完成！\n成功: $successCount\n失败: [expr {$count - $successCount}]"

        # 刷新扫描结果
        doScan
    }

    #---------------------------------------------------------------
    # GUI 操作: 导出日志
    #---------------------------------------------------------------
    proc doExport {} {
        set filename [tk_getSaveFile -title "保存替换日志" \
            -defaultextension ".csv" \
            -filetypes {{"CSV 文件" ".csv"} {"所有文件" "*"}}]
        if {$filename ne ""} {
            exportLog $filename
        }
    }
}

# 提供快捷命令
proc BulkReplace {} { ::OrcadTools::BulkReplace::showGUI }

::OrcadTools::log "批量物料替换工具 (bulk_replace_part.tcl) 已加载 - 输入 BulkReplace 打开界面"
