# 安装手册

[English](install.en.md) · [使用说明](usage.md) · [验证与兼容性](README.md)

## 手动加载

首次验证推荐手动加载。解压后保留以下文件同目录、原始 UTF-8 编码：compat.tcl、utils.tcl、show_properties.tcl、bulk_replace_part.tcl、dnp_annotator.tcl、orcad_tools_menu.tcl。

打开 Capture → View → Command Window。以下是通用示例路径，必须替换为实际解压位置：

```tcl
source -encoding utf-8 "D:/orcad-tcl-tools/orcad_tools_menu.tcl"
```

不要加 `tcl` 或 `Capture>`。路径使用正斜杠并保留双引号。菜单为 **OrCAD Tools**，也可输入 ShowProperties、BulkReplace、DNPTool。运行需要 Capture 数据库接口及可加载的 Tk，不需要 Python。

## 自动加载

在实际安装目录找到 `<Capture安装根目录>/tools/capture/tclscripts/capAutoLoad/`，部署为：

```text
capAutoLoad/
  orcad_tools_autoload.tcl
  orcad-tcl-tools/
    compat.tcl
    utils.tcl
    show_properties.tcl
    bulk_replace_part.tcl
    dnp_annotator.tcl
    orcad_tools_menu.tcl
```

ASCII 引导文件显式用 UTF-8 加载子目录入口。不要把全部模块放在顶层，以免 Capture 用系统编码重复加载。需安装目录写权限。重启后检查日志、菜单和三个面板；自动加载尚待完整实机验收。

## 更新和卸载

关闭面板后一起替换全部脚本，再重启；临时验证可重新 source 入口并打开面板。部分默认设置会恢复，需重查勾选项、显示模式、DNP 前缀。

卸载时关闭 Capture，移除引导文件和工具子目录，再启动。手动加载模式重启后不再 source 即可。卸载不会还原已修改的原理图属性或文字位置。

## 故障排查

| 报错 / 现象 | 处理 |
|---|---|
| invalid command name "tcl" | 不加 tcl 前缀 |
| couldn't read file | 使用实际解压路径，示例目录不会自动创建 |
| 缺少 winfo | 加载全部新版文件；Tk 按需初始化 |
| Tk could not be loaded | 检查 Capture 自带 Tcl/Tk 与 auto_path，不用独立 Python Tk 替代 |
| 菜单未出现 | 看日志；初始化后执行 RegisterOrcadToolsMenu 或用快捷命令 |
| 中文乱码 | 保留 UTF-8，显式指定 source 编码，不改全局 encoding system |
| Invalid method | 关闭面板重载新版，收集完整 errorInfo 堆栈 |
| 空白 tk 窗口 | 新版隐藏工具初始化的根窗口；旧会话可 wm withdraw .，但先确认未用于其他工具 |

17.2 S079 繁中环境曾通过转 Big5 缓解乱码，但不能修复菜单和 Tk 问题。推荐重新使用原始 UTF-8。若全部非 ASCII 脚本确实转为 Big5，手动执行：

```tcl
namespace eval ::OrcadTools { variable SCRIPT_ENCODING big5 }
source -encoding big5 "D:/orcad-tcl-tools/orcad_tools_menu.tcl"
```

不要混合编码；默认自动引导只用于 UTF-8。Big5 不一定保留全部简体字及符号，17.2 仍待实机复测。

## 验收

用设计副本按使用说明逐项验证。不要把时间戳、Error 输出当命令输入。对外分享日志前移除设计相关信息。
