# OrCAD Capture 17.2 CIS — 自定义 TCL 工具集

<p align="center">
  <strong>提升原理图设计效率和准确性的实用工具</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OrCAD-17.2%20CIS-blue" alt="OrCAD 17.2">
  <img src="https://img.shields.io/badge/Language-TCL%2FTk-orange" alt="TCL/Tk">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License">
</p>

---

## ✨ 功能概览

本工具集包含 **3 个实用 TCL 脚本工具**，解决 OrCAD Capture 17.2 CIS 日常原理图设计中的高频痛点：

| 工具 | 功能 | 解决痛点 |
|------|------|----------|
| **属性显示工具** | 一键显示封装 (PCB Footprint) 和耐压值 (Voltage) | 放置元件后属性不可见 |
| **批量物料替换** | 全设计范围内替换相同物料，保留位号和位置 | 无法一键替换同一物料 |
| **DNP 不上件标注** | 选中元件 Toggle 添加/移除 Value 前 `*` 号 | 无法快捷标注不上件 |

---

## 📁 文件说明

```
orcad_tcl_tools/
├── README.md                  # 本文件
├── LICENSE                    # MIT 开源协议
├── utils.tcl                  # 公共工具函数（字符串转换、遍历、日志）
├── show_properties.tcl        # 工具一：属性自动显示
├── bulk_replace_part.tcl      # 工具二：批量物料替换
├── dnp_annotator.tcl          # 工具三：DNP 不上件标注
└── orcad_tools_menu.tcl       # 统一菜单集成入口
```

---

## 🚀 快速开始

### 环境要求

- **Cadence OrCAD Capture 17.2** （含 CIS 模块）
- Windows 操作系统

### 安装方法

提供 3 种安装方式，**推荐方式一**：

#### 方式一：自动加载（推荐 ⭐）

1. **下载或克隆** 本仓库到本地：
   ```bash
   git clone https://github.com/你的用户名/orcad-tcl-tools.git
   ```

2. **复制文件** 到 OrCAD 自动加载目录：
   ```
   C:\Cadence\SPB_17.2\tools\capture\tclscripts\capAutoLoad\
   ```
   > 如果 `capAutoLoad` 文件夹不存在，请手动创建

3. 将以下文件复制进去：
   ```
   utils.tcl
   show_properties.tcl
   bulk_replace_part.tcl
   dnp_annotator.tcl
   orcad_tools_menu.tcl
   ```

4. **重启 OrCAD Capture**，工具将自动加载，菜单中出现"自定义工具"

#### 方式二：手动加载

1. 将所有 `.tcl` 文件放在任意目录，例如 `D:\orcad_tcl_tools\`

2. 打开 OrCAD Capture → **View → Command Window**

3. 在 Command Window 中输入：
   ```tcl
   source "D:/orcad_tcl_tools/orcad_tools_menu.tcl"
   ```
   > ⚠️ 注意：路径使用 **正斜杠** `/` 或 **双反斜杠** `\\`

#### 方式三：启动脚本自动加载

1. 打开文件 `C:\Cadence\SPB_17.2\tools\capture\tclscripts\capinit.tcl`

2. 在文件 **末尾** 添加一行：
   ```tcl
   source "D:/orcad_tcl_tools/orcad_tools_menu.tcl"
   ```

3. 保存并重启 OrCAD Capture

---

## 📖 详细使用说明

### 工具一：显示封装/耐压属性

> **痛点**：从 CIS 拉取元器件后，封装和耐压值不在原理图上显示

#### 使用步骤

1. **打开工具面板**：
   - 菜单方式：`自定义工具(T)` → `显示封装/耐压属性...`
   - 命令方式：在 Command Window 输入 `ShowProperties` 回车

2. **界面说明**：

   ![属性显示工具界面](docs/show_properties_gui.png)

   - **属性列表**：勾选需要显示的属性（默认：PCB Footprint、VOLTAGE_RATING）
   - **自定义属性**：可输入其他属性名并点击"添加"
   - **显示方式**：
     - `仅显示值`（推荐）— 如显示 `0402`、`25V`
     - `显示名称和值` — 如显示 `PCB Footprint=0402`
     - `仅显示名称` — 仅显示属性名

3. **选择应用范围**：
   - 🔍 **选中元件**：仅对当前选中的元件生效
   - 📄 **当前页面**：对当前打开的原理图页面所有元件生效
   - 📋 **全部页面**：对整个设计的所有原理图页面生效

4. **执行完成**：Command Window 会输出详细日志，弹窗显示处理统计

#### 配置属性名

如果你的 CIS 数据库中属性名不同，需要修改 `show_properties.tcl` 文件第 15 行：

```tcl
# 默认配置
variable PROP_LIST {
    "PCB Footprint"      ;# 封装属性名
    "VOLTAGE_RATING"     ;# 耐压属性名
}
```

**常见属性名对照表**：

| 含义 | 可能的属性名 |
|------|-------------|
| 封装 | `PCB Footprint`、`Footprint`、`PCB_FP` |
| 耐压 | `VOLTAGE_RATING`、`Voltage`、`Max_Voltage`、`Working Voltage` |
| 功率 | `POWER_RATING`、`Power`、`Wattage` |
| 容差 | `TOLERANCE`、`Tolerance` |

> 💡 **提示**：你可以在 OrCAD CIS Explorer 中查看元件的实际属性名称

---

### 工具二：批量物料替换

> **痛点**：更换物料时需要逐一修改每个元件，无法一键全局替换

#### 使用步骤

1. **打开工具面板**：
   - 菜单方式：`自定义工具(T)` → `批量物料替换...`
   - 命令方式：在 Command Window 输入 `BulkReplace` 回车

2. **选择匹配模式**：
   - **按 Value 匹配**：适合修改电容值、电阻值等（如 `100nF/25V` → `100nF/50V`）
   - **按 Part Number 匹配**：适合替换具体型号（如 `CL05A104KP5NNNC` → `CL05B104KO5NNNC`）

3. **输入替换参数**：
   - **旧物料值**：输入要被替换的值（需与原理图中完全一致）
   - **新物料值**：输入替换后的新值

4. **操作流程**：

   ```
   第一步：点击 [🔍 扫描匹配]
          → 查看匹配结果列表（REFDES、页面、当前值）
          → 确认要替换的元件是否正确

   第二步：点击 [✏️ 执行替换]
          → 弹窗确认替换数量
          → 点击"是"执行替换
          → 查看替换结果

   第三步（可选）：点击 [📄 导出日志]
          → 保存替换记录为 CSV 文件，便于存档追溯
   ```

5. **替换日志格式**（CSV）：
   ```
   REFDES,页面,旧值,新值,状态
   C1,PAGE1,100nF/25V,100nF/50V,成功
   C5,PAGE2,100nF/25V,100nF/50V,成功
   ```

> ⚠️ **注意**：本工具只修改属性值（Value / Part Number），**不会改变 REFDES（位号）和元件位置**

---

### 工具三：DNP 不上件标注

> **痛点**：标注不上件需要手动逐一编辑 Value 属性，添加 `*` 前缀

#### 使用步骤

##### 方式 A：使用工具面板（功能全面）

1. **打开面板**：
   - 菜单方式：`自定义工具(T)` → `DNP 不上件标注` → `DNP 工具面板...`
   - 命令方式：在 Command Window 输入 `DNPTool` 回车

2. **快捷操作**（对选中元件）：
   - ⚡ **Toggle DNP**（推荐）：自动判断——未标记的添加 `*`，已标记的移除 `*`
   - ➕ **批量标记 DNP**：所有选中元件强制添加 `*`
   - ➖ **批量取消 DNP**：所有选中元件强制移除 `*`

3. **全设计扫描**：点击 `📊 扫描全设计 DNP 元件` 查看当前设计中所有 DNP 元件列表

##### 方式 B：快捷命令（最快速）

直接在 Command Window 中使用（无需打开面板）：

```tcl
# 步骤 1：在原理图中选中一个或多个元件
# 步骤 2：在 Command Window 输入：

DNPToggle    ;# Toggle：有 * 就去掉，没有就加上
DNPMark      ;# 强制标记：所有选中元件加 *
DNPUnmark    ;# 强制取消：所有选中元件去 *
```

#### DNP 标注效果

| 操作前 | 操作后 (标记 DNP) |
|--------|-------------------|
| `100nF` | `*100nF` |
| `10K` | `*10K` |
| `LM1117` | `*LM1117` |

#### 可选配置

编辑 `dnp_annotator.tcl`：

```tcl
# 修改前缀符号（默认 *）
variable DNP_PREFIX "*"

# 是否同时添加 DNP 自定义属性（用于 BOM 过滤，默认开启）
variable ADD_DNP_PROP 1
```

> 💡 **提示**：启用 `ADD_DNP_PROP` 后，标记 DNP 的元件会自动添加 `DNP=YES` 属性，方便在 BOM 生成时过滤掉不上件的元件

---

## 🔧 常见问题 (FAQ)

### Q: 加载时报错怎么办？

检查 Command Window 的错误信息：
- **`couldn't read file`**：文件路径错误，检查路径是否使用正斜杠
- **`invalid command name`**：OrCAD 版本不兼容，检查是否为 17.2 版本
- **中文乱码**：确保 `.tcl` 文件保存为 UTF-8 编码

### Q: 属性显示工具执行后没有效果？

1. 确认属性名与 CIS 数据库一致（区分大小写）
2. 在 CIS Explorer 中检查元件是否有该属性
3. 检查 Command Window 日志中是否有 "属性不存在，跳过" 的提示

### Q: 批量替换后想撤销怎么办？

- 替换前建议先导出日志（CSV），记录所有变更
- 使用 OrCAD 的 `Ctrl+Z` 撤销（支持多步撤销）
- 或者用导出的日志反向替换（旧值↔新值互换）

### Q: DNP 标记后 BOM 中还会出现该元件吗？

- 元件仍在 BOM 中，但 Value 带 `*` 前缀
- 如果启用了 `ADD_DNP_PROP`，可在 BOM 模板中按 `DNP` 属性过滤
- 也可以使用 CIS 的 Variant 功能管理不上件

### Q: 支持 OrCAD 其他版本吗？

- **17.2 / 17.4**：完全兼容
- **OrCAD X (23.x/24.x)**：基本兼容，部分 API 可能有变化
- **16.x 及更早**：可能不兼容，需要测试

---

## 📋 快捷命令速查表

| 命令 | 功能 |
|------|------|
| `ShowProperties` | 打开属性显示面板 |
| `BulkReplace` | 打开批量替换面板 |
| `DNPTool` | 打开 DNP 标注面板 |
| `DNPToggle` | Toggle 选中元件的 DNP 状态 |
| `DNPMark` | 标记选中元件为 DNP |
| `DNPUnmark` | 取消选中元件的 DNP |

---

## 📄 License

本项目采用 [MIT License](LICENSE) 开源协议。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！如果这些工具对你有帮助，请给个 ⭐ Star！
