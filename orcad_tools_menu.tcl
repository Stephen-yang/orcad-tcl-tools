#####################################################################
# orcad_tools_menu.tcl - 统一菜单集成入口
# 作者: Jerry Silicon
# 日期: 2026-03-06
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
            source $toolPath
            puts "  ✓ 已加载: $tool"
        } else {
            puts "  ✗ 未找到: $toolPath"
        }
    }
}

# ---------------------------------------------------------------
# 注册自定义菜单
# ---------------------------------------------------------------
proc ::RegisterOrcadToolsMenu {} {
    # 方式一：使用 InsertXMLMenu（推荐，兼容性好）
    # 需要先创建 XML 菜单描述文件

    # 方式二：使用 capTCLMenu 方式添加菜单
    # 以下是通过 TCL 命令直接添加菜单项

    set menuXML {
<Menu>
    <popup name="自定义工具(&T)">
        <menuitem name="显示封装/耐压属性..." command="ShowProperties"/>
        <separator/>
        <menuitem name="批量物料替换..." command="BulkReplace"/>
        <separator/>
        <popup name="DNP 不上件标注">
            <menuitem name="DNP 工具面板..." command="DNPTool"/>
            <separator/>
            <menuitem name="Toggle DNP (选中元件)" command="DNPToggle"/>
            <menuitem name="标记 DNP (选中元件)" command="DNPMark"/>
            <menuitem name="取消 DNP (选中元件)" command="DNPUnmark"/>
        </popup>
        <separator/>
        <menuitem name="关于自定义工具..." command="::ShowAboutOrcadTools"/>
    </popup>
</Menu>
    }

    # 将 XML 写入临时文件
    set xmlFile [file join $::OrcadToolsDir "_menu_temp.xml"]
    set f [open $xmlFile w]
    puts $f $menuXML
    close $f

    # 尝试插入菜单
    if {[catch {InsertXMLMenu $xmlFile} err]} {
        puts "警告: InsertXMLMenu 失败，尝试备用方式: $err"
        # 备用方式：使用 capAddMenu
        catch {
            # 如果 InsertXMLMenu 不可用，提供手动菜单说明
            puts ""
            puts "========================================="
            puts "  请手动添加菜单或使用以下快捷命令:"
            puts "========================================="
            puts "  ShowProperties  - 显示封装/耐压属性"
            puts "  BulkReplace     - 批量物料替换"
            puts "  DNPTool         - DNP 标注面板"
            puts "  DNPToggle       - Toggle DNP (选中元件)"
            puts "========================================="
        }
    }

    # 清理临时文件
    catch { file delete $xmlFile }
}

# ---------------------------------------------------------------
# 关于信息
# ---------------------------------------------------------------
proc ::ShowAboutOrcadTools {} {
    set msg "OrCAD 自定义工具集 v1.0.0\n\n"
    append msg "包含工具:\n"
    append msg "  1. 属性显示 (封装/耐压)\n"
    append msg "  2. 批量物料替换\n"
    append msg "  3. DNP 不上件标注\n\n"
    append msg "作者: Jerry Silicon\n"
    append msg "日期: 2026-03-06\n\n"
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
