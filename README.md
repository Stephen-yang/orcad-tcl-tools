# OrCAD Capture Tcl 工具集

[English](README.en.md) · [安装手册](install.md) · [使用说明](usage.md)

[Release Notes](RELEASE_NOTES.md)

属性显示、属性批量替换、DNP 不上件标注三个工具。菜单为 **OrCAD Tools**，面板为中文；中英文文档不代表支持切换英文界面。

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
