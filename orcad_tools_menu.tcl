source [file join [file dirname [info script]] compat.tcl]
#####################################################################
# orcad_tools_menu.tcl - 统一菜单集成入口
# 描述: 将所有自定义 TCL 工具注册到 OrCAD Capture 菜单中
#       放置到 $CDSROOT\tools\capture\tclscripts\capAutoLoad\ 目录
#       即可在 Capture 启动时自动加载
#####################################################################

# 获取脚本所在目录
set ::OrcadToolsDir [file dirname [info script]]

# 加载所有工具脚本
proc ::LoadOrcadTools {} {
    set toolDir $::OrcadToolsDir

    # 加载各工具模块
    set tools {
        utils.tcl
        show_properties.tcl
        bulk_replace_part.tcl
        dnp_annotator.tcl
    }

    foreach tool $tools {
        set toolPath [file join $toolDir $tool]
        if {[file exists $toolPath]} {
            ::OrcadTools::sourceScript $toolPath
            puts "  ✓ 已加载: $tool"
        } else {
            puts "  ✗ 未找到: $toolPath"
        }
    }
}

# ---------------------------------------------------------------
# 注册自定义菜单
# ---------------------------------------------------------------
# Keep successful registrations across repeated sourcing; failed steps can retry.
namespace eval ::OrcadTools::Menu {
    if {![info exists installed]} { variable installed {} }
    proc enabled {args} { return 1 }
    proc invoke {command args} { uplevel #0 [list $command] }
    proc once {key script} {
        variable installed
        if {[lsearch -exact $installed $key] < 0} {
            uplevel #0 $script
            lappend installed $key
        }
    }
}

proc ::RegisterOrcadToolsMenu {} {
    foreach command {InsertXMLMenu RegisterAction} {
        if {![llength [info commands ::$command]]} {
            puts "OrCAD Tools: $command unavailable. Use ShowProperties, BulkReplace, DNPTool, DNPToggle, DNPMark, DNPUnmark; retry RegisterOrcadToolsMenu after Capture initialization."
            return 0
        }
    }
    if {[catch {
        ::OrcadTools::Menu::once update {
            RegisterAction OrcadToolsUpdate ::OrcadTools::Menu::enabled "" ::OrcadTools::Menu::enabled ""
        }
        # ASCII menu labels avoid Capture 17.2 native menu code-page conversion.
        ::OrcadTools::Menu::once root {
            InsertXMLMenu [list [list OrcadToolsMenu] "" "" [list popup "OrCAD &Tools" "" "" "" "" ""] ""]
        }
        ::OrcadTools::Menu::once dnp {
            InsertXMLMenu [list [list OrcadToolsMenu DNP] "" "" [list popup "DNP" "" "" "" "" ""] ""]
        }
        foreach {command label parent} {
            ShowProperties "Show Footprint / Voltage..." OrcadToolsMenu
            BulkReplace "Bulk Replace..." OrcadToolsMenu
            DNPTool "DNP Panel..." {OrcadToolsMenu DNP}
            DNPToggle "Toggle DNP (selection)" {OrcadToolsMenu DNP}
            DNPMark "Mark DNP (selection)" {OrcadToolsMenu DNP}
            DNPUnmark "Unmark DNP (selection)" {OrcadToolsMenu DNP}
            ShowAboutOrcadTools "About OrCAD Tools..." OrcadToolsMenu
        } {
            set action OrcadTools_$command
            ::OrcadTools::Menu::once action_$command [list RegisterAction $action ::OrcadTools::Menu::enabled "" [list ::OrcadTools::Menu::invoke ::$command] ""]
            ::OrcadTools::Menu::once menu_$command [list InsertXMLMenu [list [concat $parent [list $command]] "" "" [list action $label 0 $action OrcadToolsUpdate "" "" "" $label] ""]]
        }
    } reason]} {
        puts "OrCAD Tools: menu registration failed: $reason. Command shortcuts remain available; retry RegisterOrcadToolsMenu."
        return 0
    }
    return 1
}

# ---------------------------------------------------------------
# 关于信息
# ---------------------------------------------------------------
proc ::ShowAboutOrcadTools {} {
    ::OrcadTools::ensureTk
    set msg "OrCAD 自定义工具集 v1.0.0\n\n"
    append msg "包含工具:\n"
    append msg "  1. 属性显示 (封装/耐压)\n"
    append msg "  2. 批量物料替换\n"
    append msg "  3. DNP 不上件标注\n\n"
    append msg "快捷命令:\n"
    append msg "  ShowProperties / BulkReplace\n"
    append msg "  DNPTool / DNPToggle / DNPMark / DNPUnmark"

    tk_messageBox -title "关于 OrCAD 自定义工具" -message $msg -type ok -icon info
}

# ---------------------------------------------------------------
# 主入口: 加载并注册
# ---------------------------------------------------------------
puts ""
puts "╔══════════════════════════════════════════╗"
puts "║   OrCAD 自定义工具集 v1.0.0 加载中...    ║"
puts "╚══════════════════════════════════════════╝"
puts ""

::LoadOrcadTools

puts ""
puts "正在注册菜单..."
::RegisterOrcadToolsMenu

puts ""
puts "╔══════════════════════════════════════════╗"
puts "║   ✓ 所有工具加载完成！                    ║"
puts "║                                          ║"
puts "║   快捷命令:                               ║"
puts "║     ShowProperties  显示封装/耐压属性      ║"
puts "║     BulkReplace     批量物料替换          ║"
puts "║     DNPTool         DNP 标注面板          ║"
puts "║     DNPToggle       Toggle DNP            ║"
puts "╚══════════════════════════════════════════╝"
puts ""
