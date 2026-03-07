# OrCAD 自定义工具集 — 安装说明

## 文件清单

| 文件 | 说明 |
|------|------|
| `utils.tcl` | 公共工具函数 |
| `show_properties.tcl` | 工具一：显示封装/耐压属性 |
| `bulk_replace_part.tcl` | 工具二：批量物料替换 |
| `dnp_annotator.tcl` | 工具三：DNP 不上件标注 |
| `orcad_tools_menu.tcl` | 统一菜单入口 |

## 安装步骤

### 方式一：自动加载（推荐）

1. 找到 OrCAD 17.2 安装目录，例如：
   ```
   C:\Cadence\SPB_17.2\tools\capture\tclscripts\
   ```

2. 在该目录下找到或创建 `capAutoLoad` 文件夹：
   ```
   C:\Cadence\SPB_17.2\tools\capture\tclscripts\capAutoLoad\
   ```

3. 将所有 `.tcl` 文件复制到此目录：
   ```
   capAutoLoad\
     ├── utils.tcl
     ├── show_properties.tcl
     ├── bulk_replace_part.tcl
     ├── dnp_annotator.tcl
     └── orcad_tools_menu.tcl
   ```

4. 重启 OrCAD Capture，工具将自动加载并出现在菜单中

### 方式二：手动加载

1. 将所有文件放在任意目录，如 `D:\orcad_tcl_tools\`

2. 打开 OrCAD Capture

3. 打开 TCL Command Window：**View → Command Window**

4. 执行以下命令：
   ```tcl
   source "D:/orcad_tcl_tools/orcad_tools_menu.tcl"
   ```
   > 注意：路径使用正斜杠 `/` 或双反斜杠 `\\`

### 方式三：startup.tcl 自动执行

1. 编辑 `$CDSROOT\tools\capture\tclscripts\capinit.tcl`

2. 在文件末尾添加：
   ```tcl
   source "D:/orcad_tcl_tools/orcad_tools_menu.tcl"
   ```

## 使用方法

### 工具一：显示封装/耐压属性
- **菜单**：自定义工具 → 显示封装/耐压属性
- **命令**：在 TCL 窗口输入 `ShowProperties`
- **操作**：选择要显示的属性 → 选择范围（选中/当前页/全部） → 执行

### 工具二：批量物料替换
- **菜单**：自定义工具 → 批量物料替换
- **命令**：在 TCL 窗口输入 `BulkReplace`
- **操作**：选择匹配模式 → 输入旧/新物料值 → 扫描 → 确认 → 替换

### 工具三：DNP 不上件标注
- **菜单**：自定义工具 → DNP 不上件标注
- **命令**：在 TCL 窗口输入 `DNPTool`（打开面板）或 `DNPToggle`（直接 Toggle）
- **操作**：选中元件 → 点击 Toggle 按钮 → Value 前自动加/去 `*`

## 自定义配置

### 修改要显示的属性名

如果你的 CIS 数据库中属性名不同，编辑 `show_properties.tcl` 第 15 行：

```tcl
variable PROP_LIST {
    "PCB Footprint"      ;# 改为你的封装属性名
    "VOLTAGE_RATING"     ;# 改为你的耐压属性名
}
```

常见属性名对照：
| 含义 | 可能的属性名 |
|------|-------------|
| 封装 | `PCB Footprint`, `Footprint`, `PCB_FP` |
| 耐压 | `VOLTAGE_RATING`, `Voltage`, `Max_Voltage`, `Working Voltage` |

### 修改 DNP 前缀符号

编辑 `dnp_annotator.tcl` 第 14 行：

```tcl
variable DNP_PREFIX "*"   ;# 改为你需要的前缀
```

## 故障排除

| 问题 | 解决方案 |
|------|---------|
| 菜单未出现 | 检查 Command Window 是否有加载错误信息 |
| 属性不显示 | 确认属性名拼写与 CIS 数据库一致 |
| 替换后位号变化 | 工具只修改属性值，不会改变 REFDES |
| TCL 错误 | 在 Command Window 中查看详细错误信息 |
