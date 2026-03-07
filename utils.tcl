#####################################################################
# utils.tcl - OrCAD Capture 17.2 CIS TCL 公共工具函数
# 作者: Jerry Silicon
# 日期: 2026-03-06
# 描述: 提供字符串转换、设计遍历、日志等公共功能
#####################################################################

namespace eval ::OrcadTools {
    variable VERSION "1.0.0"
    variable LOG_ENABLED 1

    #---------------------------------------------------------------
    # 日志输出
    #---------------------------------------------------------------
    proc log {msg {level "INFO"}} {
        variable LOG_ENABLED
        if {$LOG_ENABLED} {
            set timestamp [clock format [clock seconds] -format "%H:%M:%S"]
            puts "\[$timestamp\] \[$level\] $msg"
        }
    }

    proc logWarn {msg} { log $msg "WARN" }
    proc logError {msg} { log $msg "ERROR" }

    #---------------------------------------------------------------
    # 字符串转换辅助
    # OrCAD 内部使用 CString，TCL 使用普通 string
    #---------------------------------------------------------------
    proc makeCString {str} {
        return [DboTclHelper_sMakeCString $str]
    }

    proc getCString {cstr} {
        return [DboTclHelper_sGetConstCharPtr $cstr]
    }

    #---------------------------------------------------------------
    # 获取当前活动设计
    #---------------------------------------------------------------
    proc getActiveDesign {} {
        set lStatus [DboState]
        set lSession [DboSession_sGetSessionInstance]
        if {$lSession == "NULL"} {
            logError "无法获取 Session 实例"
            return "NULL"
        }
        set lDesign [$lSession GetActiveDesign $lStatus]
        if {$lDesign == "NULL"} {
            logError "没有打开的设计文件"
            return "NULL"
        }
        return $lDesign
    }

    #---------------------------------------------------------------
    # 遍历设计中所有 Schematic 页面
    # 回调函数签名: proc callback {page pageIndex}
    #---------------------------------------------------------------
    proc forEachPage {design callback} {
        set lStatus [DboState]
        set pageIndex 0
        set lSchematicIter [$design GetSchematicsIter $lStatus]
        while {$lSchematicIter != "NULL"} {
            set lSchematic $lSchematicIter
            set lPageIter [$lSchematic GetPagesIter $lStatus]
            while {$lPageIter != "NULL"} {
                set lPage $lPageIter
                $callback $lPage $pageIndex
                incr pageIndex
                set lPageIter [$lSchematic GetPagesIterNext $lStatus]
            }
            set lSchematicIter [$design GetSchematicsIterNext $lStatus]
        }
        return $pageIndex
    }

    #---------------------------------------------------------------
    # 遍历页面中所有元件实例
    # 回调函数签名: proc callback {partInst}
    #---------------------------------------------------------------
    proc forEachPart {page callback} {
        set lStatus [DboState]
        set count 0
        set lPartInst [$page GetPartInstsIter $lStatus]
        while {$lPartInst != "NULL"} {
            $callback $lPartInst
            incr count
            set lPartInst [$page GetPartInstsIterNext $lStatus]
        }
        return $count
    }

    #---------------------------------------------------------------
    # 获取元件的属性值
    #---------------------------------------------------------------
    proc getPartPropValue {partInst propName} {
        set lStatus [DboState]
        set lCStr [makeCString ""]
        set lPropCStr [makeCString $propName]
        set lResult [$partInst GetEffectivePropStringValue $lPropCStr $lCStr]
        if {$lResult == 0} {
            return [getCString $lCStr]
        }
        return ""
    }

    #---------------------------------------------------------------
    # 设置元件的属性值
    #---------------------------------------------------------------
    proc setPartPropValue {partInst propName newValue} {
        set lStatus [DboState]
        set lPropCStr [makeCString $propName]
        set lValCStr [makeCString $newValue]
        set lResult [$partInst SetEffectivePropStringValue $lPropCStr $lValCStr $lStatus]
        return $lResult
    }

    #---------------------------------------------------------------
    # 获取元件的 REFDES
    #---------------------------------------------------------------
    proc getRefDes {partInst} {
        return [getPartPropValue $partInst "Reference"]
    }

    #---------------------------------------------------------------
    # 获取当前选中的对象列表
    #---------------------------------------------------------------
    proc getSelectedParts {} {
        set lStatus [DboState]
        set lDesign [getActiveDesign]
        if {$lDesign == "NULL"} { return {} }

        set selectedParts {}
        set lSelIter [$lDesign GetSelectedObjectsIter $lStatus]
        while {$lSelIter != "NULL"} {
            set lObj $lSelIter
            # 检查是否为 PartInst 类型
            set lObjType [$lObj GetObjectType]
            if {$lObjType == 26} {
                # 26 = DboPartInst
                lappend selectedParts $lObj
            }
            set lSelIter [$lDesign GetSelectedObjectsIterNext $lStatus]
        }
        return $selectedParts
    }

    #---------------------------------------------------------------
    # 弹出简单消息框
    #---------------------------------------------------------------
    proc msgBox {title message {type "ok"}} {
        tk_messageBox -title $title -message $message -type $type -icon info
    }

    proc msgBoxWarn {title message} {
        tk_messageBox -title $title -message $message -type ok -icon warning
    }

    proc msgBoxConfirm {title message} {
        return [tk_messageBox -title $title -message $message -type yesno -icon question]
    }
}

# 确保加载成功
::OrcadTools::log "公共工具模块 (utils.tcl v$::OrcadTools::VERSION) 已加载"
