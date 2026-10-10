# 使用说明

[English](usage.en.md) · [安装](install.md) · [验证范围](README.md)

先打开设计副本及原理图页面；在画布中选择元件，而不是属性编辑器中的单元格。下面均为通用演示值。菜单路径名称为英文，面板按钮为中文。

## 命令速查

| 命令 | 功能 |
|---|---|
| ShowProperties | 属性显示面板 |
| RepositionProperties 0 | 选中元件的目标属性文字自动重新定位 |
| RepositionProperties 4 | 使用指定间隔；0 恢复自动计算 |
| BulkReplace | 属性批量替换面板 |
| DNPTool | DNP 面板 |
| DNPMark | 标记选中元件 |
| DNPUnmark | 取消选中元件标记 |
| DNPToggle | 每个选中元件分别切换标记状态 |
| RegisterOrcadToolsMenu | Capture 初始化后重试注册菜单 |

## 属性显示 ShowProperties

菜单 **OrCAD Tools → Show Footprint / Voltage...** 或命令 ShowProperties。

1. 默认勾选 PCB Footprint 与 VOLTAGE_RATING；可添加其他属性名，区分大小写。
2. 选择“仅显示值 / 显示名称和值 / 仅显示名称”。
3. 选择“选中元件 / 当前页面 / 全部页面”；全部页面会询问确认。
4. 查看日志和统计。缺失属性会跳过；日志指出具体位号和原因。

### 电阻与电容

- 电阻默认显示封装，如 RC0402，不显示 VOLTAGE_RATING；已有电压显示文字会隐藏，属性数据保留。自定义添加其他属性仍可显示。
- 电容同时勾选默认两项时，显示一条 `CC0805/6.3V`；组合值存入 **CAP_PACKAGE_VOLTAGE**。原 PCB Footprint、VOLTAGE_RATING 数据保留，原有独立显示文字隐藏。
- 耐压属性有值时优先保留该值，不从 Description 覆盖。
- 没有耐压值时，对电容从 Description 提取。例如 `CAP CER 47uF 20% 6.3V X5R` → `6.3V`，写入 VOLTAGE_RATING 后显示。
- 支持 25V、25 VDC、1KV、2V5 等形式。未识别电压或存在多个不同电压时跳过，避免猜测；同值重复可接受。
- 判定电容优先依据 C 加数字的位号，或 Part Type 以 CAP 开头；R 加数字的位号不会提取电压。特殊命名需验证。
- 两项不齐或缺少电压时不创建新的完整组合标签；只显示可用目标属性。若来源属性后来改变，重新执行显示更新组合值。

单独勾选某项不等于删除或隐藏之前的所有显示文字。切换显示方案前请检查已有组合标签与独立文字，必要时在 Capture 的 Display Properties 中手动隐藏不需要的条目。

### 文字排版

新文字沿用 Value（其次 Part Reference / Reference）的坐标锚点、旋转方向及字体。横排文字沿水平方向接排；竖排文字向下接排。普通显示保留已有位置。

要整理旧位置，选中目标元件后执行 `RepositionProperties 0`。想调整留白可用 `RepositionProperties 4` 等非负整数。数字表示图纸坐标单位的间隔，不是毫米；自动值由文字边界推算。设置保持到当前会话后续调用。

该算法不会检测其他元件、连线或边框碰撞。密集区域先测试单个元件，再批量整理；组合文字较长，必要时手动微调。没有 Value/Reference 文字锚点时会报错，不猜测位置。

## 属性批量替换 BulkReplace

菜单 **OrCAD Tools → Bulk Replace...** 或命令 BulkReplace。

1. 选择 Value、Part Number 或 PCB Footprint 模式。
2. 输入旧值与新值。例如 PCB Footprint：CC0805 → CC0603。
3. 点击“扫描匹配”：扫描全部设计页面，按完整字符串精确匹配，区分大小写；查看位号、页面和属性。
4. 确认范围后点击“执行替换”，确认提示中的数量及属性。执行会重新扫描，不是只替换结果列表中某一行。
5. 核对原理图、属性表及日志；需要时“导出日志”保存 CSV。

只修改匹配模式对应的属性，不改变符号图形，不自动校验封装可用性，也不会同步数据库的 Value、Description、厂商等其他字段。Part Number 模式不是完整 CIS 换料。Occurrence 覆盖值可能仍与 instance 不同。

修改源属性后，CAP_PACKAGE_VOLTAGE 可能还是旧值；需要重新执行 ShowProperties 更新。单个写入失败会记录并继续，批次并非全有或全无事务。不要假定 Ctrl+Z 可以撤销全部操作，建议保留原设计副本。

CSV 含实际设计信息；当前使用简单逗号分隔，字段若含逗号、换行或引号需检查输出，不能作为可靠的自动回滚文件。

## DNP 不上件标注

菜单 **OrCAD Tools → DNP → DNP Panel...** 或命令 DNPTool。

选中测试元件后：

- DNPMark：10K → *10K；再次标记不叠加前缀。
- DNPUnmark：*10K → 10K。
- DNPToggle：每个元件按现有前缀分别标记或取消；执行两次通常恢复原值。
- 面板“扫描全设计 DNP 元件”：列出位号、页面及 Value。

默认前缀为 `*`，可在面板设置非空自定义前缀，包括多个字符。程序依据 Value 的开头判断 DNP，不依据 DNP 属性判断。默认同时写入 `DNP=YES`；取消时将 DNP 属性置空。取消勾选后只改 Value，不调整已有 DNP 属性。

DNP 不会删除元件，不改变连线，不自动设置 CIS Variant 的 fitted/not fitted。BOM 是否排除 DNP 取决于 BOM 配置；需要明确按 DNP 属性或前缀过滤。Value 本来就含该前缀时也会被视为 DNP，使用前请确认。

Value 与 DNP 属性为独立写入，执行后需核对二者，异常时不要只依赖成功统计。Occurrence 覆盖可能影响实际显示和 BOM，需核对实例与 occurrence。

## 验证清单

在副本中验证：三个面板、扫描结果、一次替换、封装/电压标签、文字位置、标记后取消、全设计 DNP 扫描、位号位置及连线。实机验证范围见 README，不把模拟测试标成产品兼容认证。
