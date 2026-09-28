# Homelander

基于 **Lua** 的《僵尸毁灭工程》(Project Zomboid) **Build 42** Mod：为角色的多种状态（血量、综合健康、饥饿、口渴、疲劳）分别设置数值锁定，受伤或状态变化时自动把对应数值钳制在设定阈值之上或之下。

方案依据见 `tmp/` 下两份分析文档（基于反编译源码整理，未纳入版本控制）：`PZ_健康死亡系统API说明.md`（B42 健康系统 API 梳理）与 `属性锁定与免死方案分析.md`（纯 Lua 环境下可行方案分析，本 Mod 采用其中推荐的"每 tick 纠正"方案 A）。

## 功能特性

- 可分别为「血量 / 综合健康 / 饥饿 / 口渴 / 疲劳」5 项状态开关锁定
- 每项状态可单独设置方向（不低于 / 不高于）与目标数值，用 `+`/`-` 按钮调整
- 每 tick（`OnPlayerUpdate`）检查一次，只在数值越过阈值时才纠正，阈值内的正常波动不受影响
- 综合健康锁定会同步钳制各身体部位血量（否则下一 tick 会被游戏自身的汇总计算覆盖）
- 设置通过 `getFileWriter`/`getFileReader` 写入 `Zomboid/Lua/Homelander_Settings.ini`，与存档无关，**重启游戏后自动读回上次的开关状态与数值**
- 左侧边栏新增图标按钮，点击打开/关闭设置窗口

## 目录结构

```
Homelander/
├── .gitignore
├── README.md                            # 本文件
├── workshop.txt                         # Workshop 清单（上传时填写 id）
├── poster.png                           # Workshop 预览图
└── contents/
    └── mods/
        └── Homelander/                  # Mod 根目录，与 mod.info 的 id 一致
            └── 42/                      # B42 版本目录
                ├── mod.info
                ├── poster.png
                └── media/
                    └── lua/
                        ├── shared/Homelander/
                        │   ├── Config.lua       # 全局配置
                        │   ├── Logger.lua       # 日志工具
                        │   └── StatLocks.lua    # 状态定义 + 纠正逻辑 + 持久化
                        └── client/Homelander/
                            ├── Bootstrap.lua    # OnGameStart 加载设置 / OnPlayerUpdate 逐 tick 纠正
                            └── UI/
                                ├── SettingsWindow.lua  # 设置窗口
                                └── SidebarButton.lua   # 左侧边栏图标按钮
```

## 核心模块说明

| 模块 | 位置 | 说明 |
| --- | --- | --- |
| `Homelander.Config` | shared/Config.lua | 全局配置：`MOD_NAME`/`MOD_ID`/`SETTINGS_FILE` |
| `Homelander.Logger` | shared/Logger.lua | `Logger.debug/info/warn/error(fmt, ...)` |
| `Homelander.StatLocks` | shared/StatLocks.lua | `Definitions`（状态定义表）、`Settings`（当前设置）、`load()`/`save()`（持久化）、`applyTo(player)`（每 tick 纠正） |
| `Homelander.UI.SettingsWindow` | client/UI/ | 设置窗口，`toggle()` 切换显示 |
| `Homelander.UI.SidebarButton` | client/UI/ | 左侧边栏图标按钮（hook `ISEquippedItem`），点击切换设置窗口 |

### 新增/调整一个状态锁定项

在 `StatLocks.Definitions` 里加一条即可，`get`/`set` 分别是读取与写入该属性的闭包（可参考文档里列出的 API）：

```lua
{
    key = "temperature", label = "体温",
    min = 20, max = 40, step = 1,
    defaultMode = "min", defaultValue = 25,
    get = function(player) return player:getStats():get(CharacterStat.TEMPERATURE) end,
    set = function(player, value) player:getStats():set(CharacterStat.TEMPERATURE, value) end,
},
```

`mode = "min"` 表示锁定项是下限（不低于，如血量），`mode = "max"` 表示锁定项是上限（不高于，如饥饿/口渴/疲劳）；UI 与持久化对新项自动生效，不需要额外改动。

## 安装与本地测试

1. 在游戏的本地 Mod 目录中创建指向本仓库 Mod 子目录的 **Junction（目录联接）**：

   ```powershell
   New-Item -ItemType Junction -Path "C:\Users\28270\Zomboid\mods\Homelander" -Value "D:\Code\Learn\GameMod\Homelander\contents\mods\Homelander"
   ```

   说明：

   - B42 从用户目录 `C:\Users\<你>\Zomboid\mods\` 与游戏安装目录 `ProjectZomboid\mods\` 扫描本地 Mod
   - Junction 指向仓库的 `contents\mods\Homelander` 子目录，链接内保留 `42\` 版本目录（B42 版本化布局）；仓库根目录仍保留 `workshop.txt + contents/mods` 的 Workshop 布局，日后上传创意工坊无需任何改动
   - 仓库内的任何改动（Lua）**无需手动拷贝**，重启游戏后直接生效
   - 此命令**只需执行一次**，重启电脑后依然有效；不想再测试时删除链接即可（不会删除仓库本体）：

     ```bat
     rmdir "C:\Users\28270\Zomboid\mods\Homelander"
     ```

     注意：删除时不要加 `/s` 参数，普通 `rmdir` 只移除链接本身，不会触碰仓库内容

2. 启动游戏 → Mods → 勾选 **Homelander** → 重启生效
3. 验证：
   - 进入存档后，点击左侧边栏新增的图标按钮，打开设置窗口
   - 把「血量」启用并设为「不低于 30」，用作弊菜单把血量打到很低，观察下一 tick 是否被纠正回 30
   - 退出并重启游戏，确认设置窗口里的开关/方向/数值与关闭前一致（对应 `Zomboid\Lua\Homelander_Settings.ini`）
   - 日志文件为 `C:\Users\<你的用户名>\Zomboid\console.txt`（当前会话）及 `Zomboid\Logs\` 目录下的 `*_DebugLog.txt`，搜索 `Homelander` 可看到 `client ready` 日志

### Debug 模式（可选）

Steam 启动选项填 `-debug`。Debug 模式提供作弊菜单（传送、改属性等），方便测试锁定效果。

## 已知限制

- 纠正基于 `OnPlayerUpdate` 逐 tick 检查，存在"游戏改了 → 下一 tick 才纠正"的一帧滞后，一般不可感知；但对武器命中/载具撞击这类同一调用栈内同步完成扣血与死亡判定的瞬时伤害，理论上仍存在极端情况下的漏判窗口（详见`属性锁定与免死方案分析.md`第三节）。本 Mod 只做通用的属性锁定，未额外实现 `tmp/属性锁定与免死方案分析.md` 中"免死"专题的武器命中钩子兜底。
- 逻辑目前只应用于本地控制的玩家（`OnPlayerUpdate` 传入的 `player`），多人游戏下每个客户端只会纠正自己的角色。

## 修改配置

全局参数集中在 `shared/Homelander/Config.lua`；状态列表、默认方向/数值集中在 `shared/Homelander/StatLocks.lua` 的 `Definitions`。发布前可将 `Config.DEBUG` 设为 `false` 关闭调试日志。
