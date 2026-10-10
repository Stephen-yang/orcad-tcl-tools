# OrCAD Capture Tcl 工具集

用于原理图设计的三个实用工具：显示封装和电容耐压、批量修改属性、标注 DNP 不上件。

[English](README.en.md) · [安装手册](install.md) · [使用说明](usage.md) · [Release Notes](RELEASE_NOTES.md)

## 功能概览

| 工具 | 典型需求 | 结果 |
|---|---|---|
| ShowProperties | 元件封装、耐压没有显示在原理图上 | 电阻显示 RC0402；电容显示 CC0805/6.3V |
| BulkReplace | 多个元件需要改成相同属性值 | 按 Value、Part Number 或 PCB Footprint 精确匹配并替换 |
| DNPTool | 临时取消装配但保留元件和连线 | Value 添加 / 取消 * 前缀，可同时设置 DNP 属性 |

**实测基准：OrCAD Capture CIS 17.4-2019 S037（4108587），Windows 64 位。** 其他版本的验证状态见本文末尾。工具菜单名称为 **OrCAD Tools**，面板为中文；提供中英文文档，不提供英文界面切换。

## 文件说明

```text
orcad-tcl-tools/
  orcad_tools_menu.tcl       # 手动加载入口和菜单注册
  orcad_tools_autoload.tcl   # 自动加载引导，部署到 capAutoLoad 顶层
  compat.tcl                # 显式编码加载、Tk 初始化
  utils.tcl                 # Capture 对象遍历和属性读写
  show_properties.tcl       # 封装、耐压、组合标签与排版
  bulk_replace_part.tcl     # 属性扫描、替换、日志导出
  dnp_annotator.tcl          # DNP 标记、取消和扫描
  README.md / README.en.md
  install.md / install.en.md
  usage.md / usage.en.md
  RELEASE_NOTES.md / RELEASE_NOTES.en.md
  LICENSE
```

发布 ZIP 不包含开发测试文件；从源码开发时还可使用 tests/ 和 tools/build_release.py。

## 快速安装

### 方法一：手动加载（首次使用推荐）

1. 下载仓库 dist 目录中的发布 ZIP，或使用仓库代码。
2. 解压到自选目录。下面以 `D:/orcad-tcl-tools/` 为**通用示例**；实际脚本目录可能在解压后的同名子目录中，需确认文件所在位置。
3. 保持入口、三个工具、utils.tcl、compat.tcl 在同一目录，全部保留原始 UTF-8 编码。
4. 打开 Capture，选择 **View → Command Window**。
5. 输入以下一行，替换为实际目录：

```tcl
source -encoding utf-8 "D:/orcad-tcl-tools/orcad_tools_menu.tcl"
```

6. 检查日志是否加载完成。菜单注册成功后出现 **OrCAD Tools**。若菜单暂未出现，可直接输入 `ShowProperties`、`BulkReplace`、`DNPTool`。

Command Window 已是 Tcl 环境，**不加 tcl 前缀，也不输入 Capture>**。路径使用正斜杠，双引号不能省略。使用工具不需要 Python。

### 方法二：启动自动加载

1. 找到实际 Capture 安装目录下的 `tools/capture/tclscripts/capAutoLoad/`。
2. 顶层只放 orcad_tools_autoload.tcl；其他脚本放在其 orcad-tcl-tools 子目录：

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

3. 重启 Capture，检查日志、菜单和三个面板。

引导文件为 ASCII，显式按 UTF-8 加载入口。不要把全部工具模块放到顶层，以免被 Capture 按系统编码重复加载。自动加载方式仍需在目标安装中验收。更新、卸载与 Big5 环境说明见 [安装手册](install.md)。

## 工具一：显示封装和电容耐压

### 打开与基本操作

菜单：**OrCAD Tools → Show Footprint / Voltage...**；或执行：

```tcl
ShowProperties
```

1. 打开设计副本和原理图页面，先在画布中选一个元件。
2. 默认勾选 **PCB Footprint** 与 **VOLTAGE_RATING**；使用“自定义属性”可添加其他属性名。
3. 显示方式选择 **仅显示值（推荐）**，也可选择“显示名称和值”或“仅显示名称”。
4. 点击“选中元件”验证效果；确认后再用“当前页面”或“全部页面”。全设计处理需要确认。
5. 查看 Command Window 日志及统计，核对位号、文字内容和位置。

选择对象应在原理图画布中完成，不是只选属性编辑器单元格。

### 默认显示效果

| 元件 | 原始属性 | 原理图新增显示 |
|---|---|---|
| 电阻 | PCB Footprint=RC0402 | RC0402 |
| 电容 | PCB Footprint=CC0805，VOLTAGE_RATING=6.3V | CC0805/6.3V |
| 电容缺少耐压属性 | Description 包含明确 6.3V | 提取并写入耐压，再显示组合标签 |

电容同时勾选两项时，组合文本存入 **CAP_PACKAGE_VOLTAGE**。源封装和耐压属性保留，旧的独立显示文字隐藏。电阻不显示默认耐压项，已有电压文字隐藏而数据保留。

### 从 Description 提取电压

例如：

```text
Description: CAP CER 47uF 20% 6.3V X5R
提取结果: VOLTAGE_RATING=6.3V
组合显示: CC0805/6.3V
```

支持 25V、25 VDC、1KV、2V5 等形式。已有 VOLTAGE_RATING 时保留，不覆盖。没有电压或有多个不同电压时跳过并记日志。电容依据 C 加数字的位号或 CAP 开头的 Part Type 判断；特殊命名需验证。

没有耐压值时不会拼出完整组合。只勾选单项也不等于删除旧组合文字，改变显示方案时需检查已有标签，必要时通过 Capture 的 Display Properties 隐藏旧条目。

### 调整文字位置

新文字继承 Value（其次 Reference）的字体、旋转和坐标锚点：横排沿同一行接排，竖排向下接排。普通显示操作保留已有位置。

选中需要整理的元件后执行：

```tcl
RepositionProperties 0
```

0 表示自动间距。若想调整空隙，可指定非负整数：

```tcl
RepositionProperties 4
```

这是图纸坐标单位，不是毫米。先验证一个元件，再批量处理；算法不检测其他元件和连线碰撞，密集区域仍可能需要手动微调。源属性改变后，重新执行 ShowProperties 更新组合值。

## 工具二：批量属性替换

菜单：**OrCAD Tools → Bulk Replace...**；或执行：

```tcl
BulkReplace
```

### 匹配模式

| 模式 | 旧值示例 | 新值示例 | 实际修改 |
|---|---|---|---|
| Value | 10K | 22K | Value 属性 |
| Part Number | DEMO-PART-001 | DEMO-PART-002 | Part Number 属性 |
| PCB Footprint | CC0805 | CC0603 | PCB Footprint 属性 |

### 操作步骤

1. 在设计副本中选择匹配模式，填写旧值和新值。
2. 点击 **扫描匹配**。扫描所有设计页面，区分大小写、完整字符串精确匹配。
3. 核对结果列表中的 **REFDES、页面、当前属性值** 和匹配总数。
4. 点击 **执行替换**，确认属性、旧值、新值及数量。执行时重新扫描全设计，不是只替换列表中某一行。
5. 核对原理图与属性编辑器中的结果；需要时点击 **导出日志** 保存 CSV。

本工具是属性修改，不是完整换料。改 Part Number 不会同步新料的 Value、Description、封装和厂商；改 PCB Footprint 不校验封装存在。符号图形和连线不会因属性修改自动换成新符号。CIS 完整换料入口已撤销。

Occurrence 覆盖可能与 instance 不同，核对时应检查两者。单个写入失败记录后继续，批次不是原子事务；Undo 未验证，不承诺 Ctrl+Z 能撤回全部修改。

CSV 含实际设计信息；导出使用简单逗号分隔，字段含逗号、换行、引号时请检查，不能用作自动回滚依据。

## 工具三：DNP 不上件标注

菜单：**OrCAD Tools → DNP → DNP Panel...**；或执行：

```tcl
DNPTool
```

### 面板操作

1. 在原理图画布中选中一个或多个元件。
2. 点击 **批量标记 DNP**：Value 前加前缀，默认 `*`。
3. 再次标记不会叠加 `*`。点击 **批量取消 DNP** 恢复原值。
4. **Toggle DNP** 对每个元件分别切换；混合选择中，已标记的取消、未标记的添加。
5. 点击 **扫描全设计 DNP 元件**，查看位号、页面、Value。

### 快捷命令与效果

```tcl
DNPMark
DNPUnmark
DNPToggle
```

| 操作 | 示例结果 |
|---|---|
| 标记 | 10K → *10K |
| 重复标记 | *10K 保持不变 |
| 取消 | *10K → 10K |

默认勾选“同时添加/移除 DNP 自定义属性”：标记写 DNP=YES，取消置空。不勾选则只改 Value，已有 DNP 属性不调整。可设置非空多字符前缀；判断状态依据 Value 的开头，而不是 DNP 属性。

DNP 不删除元件，不自动改变 CIS Variant 装配状态，也不自动从 BOM 排除元件。BOM 需按 DNP 属性或前缀配置过滤。Value 与 DNP 是独立写入，执行后核对二者及 occurrence 覆盖值。

## 常见问题

| 问题 | 处理 |
|---|---|
| invalid command name "tcl" | 只输入 source 或工具命令，不加 tcl |
| couldn't read file | 路径为示例，改成实际入口所在目录 |
| 菜单没有出现 | 看加载日志；初始化完成后执行 RegisterOrcadToolsMenu，或使用快捷命令 |
| invalid command name "winfo" | 关闭面板，确认全部新版文件已加载；Tk 会按需初始化 |
| Tk could not be loaded | 检查 Capture 自带 Tcl/Tk 与 auto_path，不用 Python Tk 替代 |
| 中文乱码 | 原始 UTF-8 文件配合 source -encoding utf-8，不改全局 encoding system |
| 属性不存在 | 核对真实属性名；Description 中的电压不等于已有耐压属性 |
| 修改后标签仍旧值 | 重新执行 ShowProperties 更新组合标签 |
| Invalid method | 重载全部新版，贴完整错误堆栈，不只贴方法列表 |

不要把时间戳或 Error 输出当作命令输入。17.2 繁中 Big5 的注意事项、更新和卸载见 [安装手册](install.md)。

## 快捷命令速查

| 命令 | 功能 |
|---|---|
| ShowProperties | 属性显示面板 |
| RepositionProperties 0 | 自动整理选中元件的目标文字 |
| BulkReplace | 批量属性替换面板 |
| DNPTool | DNP 面板 |
| DNPMark / DNPUnmark / DNPToggle | 标记 / 取消 / 切换选中元件 |
| RegisterOrcadToolsMenu | 重试菜单注册 |

## 验证基准

**OrCAD Capture CIS 17.4-2019 S037（4108587），Windows SPB 64-bit Edition，Tcl 8.6.5**。版本信息来自 About 窗口；验证日期：2026-10-10。

| 功能 | 验证状态 |
|---|---|
| 手动 UTF-8 加载、中文面板 | 已实机验证 |
| ShowProperties | 封装、电容电压提取、组合标签和文字定位已实机验证 |
| BulkReplace 扫描 | Part Number 扫描和结果列表已实机验证 |
| BulkReplace 写入、导出、PCB Footprint 模式 | 模拟测试或代码检查；仍需实机验收 |
| DNP | 批量标记、取消和全设计扫描已实机验证；Toggle 有回归测试 |
| 菜单点击、自动加载 | 尚待完整验收；命令打开面板已验证 |

模拟回归测试不是 Capture 实机测试。Undo 未验证，修改前使用设计副本。

## 兼容产品

| 产品 / 版本 | 状态 |
|---|---|
| Capture CIS 17.4-2019 S037 | 上表范围内的验证基准 |
| Capture CIS 17.2-2016 S079 / S083 | 曾报告菜单、Tk、乱码问题；已针对修复，尚未在这两个补丁实机复测 |
| 其他 Capture / CIS 17.4 补丁及 22.1 | 基于相近 Capture 接口的兼容候选，未验证 |
| Allegro Design Entry Capture / CIS | Capture 产品体系的兼容候选，未验证 |
| OrCAD X Capture / Capture CIS | 兼容候选，接口与上下文可能不同，未验证 |
| Capture 16.x 及更早 | 未验证，不承诺兼容 |
| Allegro PCB Editor、OrCAD X Presto、Design Entry HDL、独立 PSpice | 不是目标运行环境 |

兼容候选是接口体系推断，不是厂商认证。参考：[Cadence Capture Tcl/Tk 自动化](https://support1.cadence.com/public/docs/content/20469530.html)、[Capture API 文档](https://www.ema-eda.com/wp-content/uploads/files/resources/files/OrCAD_Capture_TclTk_Extensions.pdf)。

## 功能边界

批量替换仅修改 Value、Part Number 或 PCB Footprint 属性；不完整换料、不同步 CIS 数据库。实验性 CIS 入口已撤销。Occurrence 覆盖可能与 instance 属性不同，需核对。DNP 前缀和属性不控制 CIS Variant 装配状态。

## 发布与隐私

ZIP 白名单只包含运行脚本、中英文文档和 LICENSE，排除 Git 历史、测试、截图、设计、数据库、诊断、日志、缓存和真实机器路径。文档中的路径与数据为通用示例。ZIP 固定时间戳，无本机额外元数据。

脚本及 About 个人署名已移除；MIT 要求的原始版权声明保留于 LICENSE。发布包不含个人运行数据，但不是移除版权归属的匿名许可副本。运行日志和导出 CSV 可能包含实际位号、页面及属性，分享前请检查。

开发测试：`python -m unittest discover -s tests -v`（Python + tkinter）。打包：`python tools/build_release.py`。使用工具不需要 Python。[MIT](LICENSE)。
