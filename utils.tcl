source [file join [file dirname [info script]] compat.tcl]
#####################################################################
# utils.tcl - OrCAD Capture 17.2 CIS TCL 公共工具函数
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
        if {![info exists ::DboSession_s_pDboSession]} {
            error "OrCAD Tools: Capture session variable DboSession_s_pDboSession is unavailable."
        }
        set lSession $::DboSession_s_pDboSession
        if {$lSession == "NULL"} {
            logError "无法获取 Session 实例"
            return "NULL"
        }
        DboSession -this $lSession
        set lDesign [$lSession GetActiveDesign]
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
        set views [$design NewViewsIter $lStatus $::IterDefs_SCHEMATICS]
        set pages NULL
        set code [catch {
            set view [$views NextView $lStatus]
            while {$view ne "NULL"} {
                set schematic [DboViewToDboSchematic $view]
                set pages [$schematic NewPagesIter $lStatus]
                set page [$pages NextPage $lStatus]
                while {$page ne "NULL"} {
                    uplevel 1 [concat $callback [list $page $pageIndex]]
                    incr pageIndex
                    set page [$pages NextPage $lStatus]
                }
                delete_DboSchematicPagesIter $pages
                set pages NULL
                set view [$views NextView $lStatus]
            }
        } result options]
        if {$pages ne "NULL"} { delete_DboSchematicPagesIter $pages }
        delete_DboLibViewsIter $views
        if {$code} { return -options $options $result }
        return $pageIndex
    }

    #---------------------------------------------------------------
    # 遍历页面中所有元件实例
    # 回调函数签名: proc callback {partInst}
    #---------------------------------------------------------------
    proc forEachPart {page callback} {
        set lStatus [DboState]
        set count 0
        set iter [$page NewPartInstsIter $lStatus]
        set code [catch {
            set lPartInst [$iter NextPartInst $lStatus]
            while {$lPartInst != "NULL"} {
                uplevel 1 [concat $callback [list $lPartInst]]
                incr count
                set lPartInst [$iter NextPartInst $lStatus]
            }
        } result options]
        delete_DboPagePartInstsIter $iter
        if {$code} { return -options $options $result }
        return $count
    }

    #---------------------------------------------------------------
    # 获取元件的属性值
    #---------------------------------------------------------------
    proc getPartPropValue {partInst propName} {
        set lCStr [makeCString ""]
        set lPropCStr [makeCString $propName]
        # The return is a DboState wrapper, not an integer success code.
        # The actual property value is written into the output CString.
        $partInst GetEffectivePropStringValue $lPropCStr $lCStr
        return [getCString $lCStr]
    }

    #---------------------------------------------------------------
    # 设置元件的属性值
    #---------------------------------------------------------------
    proc setPartPropValue {partInst propName newValue} {
        set lPropCStr [makeCString $propName]
        set lValCStr [makeCString $newValue]
        set state [$partInst SetEffectivePropStringValue $lPropCStr $lValCStr]
        # Keep the tools' existing 0=success contract.
        return [expr {![$state OK]}]
    }

    #---------------------------------------------------------------
    # 获取元件的 REFDES
    #---------------------------------------------------------------
    proc getRefDes {partInst} {
        set value [makeCString ""]
        $partInst GetReferenceDesignator $value
        return [getCString $value]
    }

    #---------------------------------------------------------------
    # 获取当前选中的对象列表
    #---------------------------------------------------------------
    proc getSelectedParts {} {
        set selectedParts {}
        foreach lObj [GetSelectedObjects] {
            if {$lObj eq "NULL" || $lObj eq ""} { continue }
            # 检查是否为 PartInst 类型
            set lObjType [$lObj GetObjectType]
            if {$lObjType == $::DboBaseObject_PLACED_INSTANCE} {
                lappend selectedParts $lObj
            }
        }
        return $selectedParts
    }

    #---------------------------------------------------------------
    # 弹出简单消息框
    #---------------------------------------------------------------
    proc msgBox {title message {type "ok"}} {
        ::OrcadTools::ensureTk
        tk_messageBox -title $title -message $message -type $type -icon info
    }

    proc msgBoxWarn {title message} {
        ::OrcadTools::ensureTk
        tk_messageBox -title $title -message $message -type ok -icon warning
    }

    proc msgBoxConfirm {title message} {
        ::OrcadTools::ensureTk
        return [tk_messageBox -title $title -message $message -type yesno -icon question]
    }
}

# 确保加载成功
::OrcadTools::log "公共工具模块 (utils.tcl v$::OrcadTools::VERSION) 已加载"
