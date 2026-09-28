# PZ Example Mod

基于 **Lua** 的《僵尸毁灭工程》(Project Zomboid) **Build 42** Mod 开发框架模板。

框架采用 `shared / client / server` 三层结构，内置日志、网络命令封装、事件注册、示例 UI 与示例物品，可直接作为新 Mod 的起点进行扩展。

## 功能特性

- B42 标准 Workshop 目录结构（`workshop.txt` + `contents/mods/<ModID>/<版本号>/`，版本化目录），兼容本地开发与创意工坊上传
- 三层 Lua 架构：
  - `shared`：客户端与服务器共用代码
  - `client`：仅在客户端加载（UI、本地玩家逻辑）
  - `server`：仅在服务器加载（SP 下与 client 同时运行）
- **无加载顺序依赖**：所有跨文件引用均为延迟访问（函数内引用），文件任意命名、任意顺序加载均不会报错
- 统一日志工具 `Logger`（DEBUG / INFO / WARN / ERROR，DEBUG 受 `Config.DEBUG` 开关控制）
- 网络命令封装 `Network`（`sendToServer` / `sendToPlayer` / `sendToAll`，SP 与 MP 通用）
- 事件系统示例：客户端 `OnGameStart` / `OnServerCommand`，服务器 `OnGameStart` / `OnClientCommand`
- 示例 UI 窗口（`ISPanel` 派生，点击左侧边栏图标按钮切换，可拖动）
- 示例物品脚本（`PZExampleMod.ExampleItem`）
- 内置 client → server → client 的完整命令往返示例（`requestInit` → `syncData`）

## 目录结构

```
PZExmapleMod/
├── .gitignore
├── README.md                            # 本文件
├── workshop.txt                         # Workshop 清单（上传时填写 id）
├── poster.png                           # Workshop 预览图（256x256）
└── contents/
    └── mods/
        └── PZExampleMod/                # Mod 根目录，与 mod.info 的 id 一致
            └── 42/                      # B42 版本目录（游戏按 Build 版本选择加载）
                ├── mod.info             # Mod 元数据（B42 必须包含 poster 字段）
                ├── poster.png           # Mod 预览图（mod.info 引用）
                └── media/
                    ├── lua/
                    │   ├── shared/PZExampleMod/       # 双端共用
                    │   │   ├── Config.lua             # 全局配置（名称、版本、调试开关、网络模块名）
                    │   │   ├── Logger.lua             # 日志工具
                    │   │   ├── Utils.lua              # 通用工具函数（表复制、计数、四舍五入等）
                    │   │   └── Network.lua            # 网络命令封装
                    │   ├── client/PZExampleMod/       # 仅客户端
                    │   │   ├── Bootstrap.lua          # 事件注册入口（接线到 Events/Commands）
                    │   │   ├── Events.lua             # 事件处理器
                    │   │   ├── Commands.lua           # 处理 server → client 命令
                    │   │   └── UI/
                    │   │       ├── ExampleWindow.lua  # 示例窗口（ISPanel 派生）
                    │   │       └── SidebarButton.lua  # 左侧边栏图标按钮（hook ISEquippedItem）
                    │   └── server/PZExampleMod/       # 仅服务器（SP 下同样运行）
                    │       ├── Bootstrap.lua          # 事件注册入口
                    │       ├── Events.lua             # 服务器事件处理器
                    │       └── Commands.lua           # 处理 client → server 命令
                    └── scripts/
                        └── items_example.txt          # 示例物品脚本
```

## 核心模块说明

| 模块 | 位置 | 说明 |
| --- | --- | --- |
| `PZExampleMod.Config` | shared/Config.lua | 全局配置。`DEBUG` 控制调试日志；`NETWORK_MODULE` 是网络命令的模块标识，所有命令收发都按它过滤 |
| `PZExampleMod.Logger` | shared/Logger.lua | `Logger.debug/info/warn/error(fmt, ...)`，支持 `string.format` 风格占位符，输出到游戏日志 |
| `PZExampleMod.Utils` | shared/Utils.lua | `shallowcopy` / `deepcopy` / `count` / `round` 等通用函数 |
| `PZExampleMod.Network` | shared/Network.lua | `sendToServer(cmd, args)`（客户端→服务器）、`sendToPlayer(player, cmd, args)` / `sendToAll(cmd, args)`（服务器→客户端）、`isOurModule(module)` |
| `PZExampleMod.Client` | client/ | 客户端命名空间：`onGameStart` 事件处理、`CommandHandlers` 命令表、`onServerCommand` 分发器 |
| `PZExampleMod.Server` | server/ | 服务器命名空间：`onGameStart` 事件处理、`CommandHandlers` 命令表、`onClientCommand` 分发器 |
| `PZExampleMod.UI.ExampleWindow` | client/UI/ | 示例窗口类，`toggle()` 切换显示 |
| `PZExampleMod.UI.SidebarButton` | client/UI/ | 左侧边栏图标按钮（B42 `ISEquippedItem` hook），点击切换示例窗口 |

### 命令往返示例（已内置）

```
客户端 OnGameStart
  → Network.sendToServer("requestInit")
    → 服务器 Commands.lua: CommandHandlers.requestInit
      → Network.sendToPlayer(player, "syncData", { message = ... })
        → 客户端 Commands.lua: CommandHandlers.syncData（记录 debug 日志）
```

`ping` / `pong` 为另一对往返示例，可在任意客户端代码中调用 `PZExampleMod.Network.sendToServer("ping", {})` 测试。

## 安装与本地测试

1. 在游戏的本地 Mod 目录中创建指向本仓库 Mod 子目录的 **Junction（目录联接）**：

   ```powershell
   New-Item -ItemType Junction -Path "C:\Users\28270\Zomboid\mods\PZExampleMod" -Value "D:\Code\Learn\GameMod\PZExmapleMod\contents\mods\PZExampleMod"
   ```

   说明：

   - B42 从用户目录 `C:\Users\<你>\Zomboid\mods\` 与游戏安装目录 `ProjectZomboid\mods\` 扫描本地 Mod
   - Junction 指向仓库的 `contents\mods\PZExampleMod` 子目录，链接内保留 `42\` 版本目录（B42 版本化布局）；仓库根目录仍保留 `workshop.txt + contents/mods` 的 Workshop 布局，日后上传创意工坊无需任何改动
   - 仓库内的任何改动（Lua / 物品脚本 / 贴图）**无需手动拷贝**，重启游戏后直接生效
   - 此命令**只需执行一次**，重启电脑后依然有效；不想再测试时删除链接即可（不会删除仓库本体）：

     ```bat
     rmdir "C:\Users\28270\Zomboid\mods\PZExampleMod"
     ```

     注意：删除时不要加 `/s` 参数，普通 `rmdir` 只移除链接本身，不会触碰仓库内容
   - 等效的 cmd 写法：`mklink /J "C:\Users\28270\Zomboid\mods\PZExampleMod" "D:\Code\Learn\GameMod\PZExmapleMod\contents\mods\PZExampleMod"`
   - 在其他机器上使用时，请替换为目标机器的 Windows 用户名与仓库实际路径

2. 启动游戏 → Mods → 勾选 **PZ Example Mod** → 重启生效
3. 验证：
   - 进入存档后，点击左侧边栏（搬运/健康/搜寻等图标下方）新增的图标按钮，可开关示例窗口
   - 日志文件为 `C:\Users\<你的用户名>\Zomboid\console.txt`（当前会话）及 `Zomboid\Logs\` 目录下的 `*_DebugLog.txt`，搜索 `PZExampleMod` 应出现 `client ready` / `server ready` / `Server sync: ...` 日志
   - 创造模式搜索 "Example Item" 可找到示例物品

### Debug 模式（可选）

Steam 启动选项填 `-debug`。Debug 模式提供作弊菜单（传送、刷物品等），方便测试。

## 如何扩展

### 添加新事件

1. 在对应端的 `Events.lua` 中实现 `PZExampleMod.Client.onXxx` / `PZExampleMod.Server.onXxx`
2. 在对应端 `Bootstrap.lua` 中注册，保持延迟引用写法：

   ```lua
   Events.OnPlayerUpdate.Add(function(player)
       PZExampleMod.Client.onPlayerUpdate(player)
   end)
   ```

### 添加网络命令

在两侧 `Commands.lua` 中成对添加（命令名即 key）：

```lua
-- server/Commands.lua：处理 client → server
PZExampleMod.Server.CommandHandlers.myCommand = function(player, args)
    PZExampleMod.Network.sendToPlayer(player, "myResponse", { value = args.value * 2 })
end

-- client/Commands.lua：处理 server → client
PZExampleMod.Client.CommandHandlers.myResponse = function(args)
    PZExampleMod.Logger.debug("Got value: %s", tostring(args.value))
end
```

### 添加 UI

参考 `client/PZExampleMod/UI/ExampleWindow.lua`：`ISPanel:derive` 派生类 + `toggle()` 静态开关。

挂到 B42 左侧边栏参考 `client/PZExampleMod/UI/SidebarButton.lua`：hook `ISEquippedItem.initialise` 在原生按钮末尾追加图标按钮（尺寸自动跟随游戏侧栏大小设置，纹理复用 `media/ui/Sidebar/`），点击回调中调用窗口的 `toggle()` 即可。

### 添加物品 / 脚本

在 `media/scripts/` 下新建 `.txt`（自动加载），或按类型放入：
`media/textures/`（贴图，自动加载）、`media/sound/`（音效）、`media/models/`（模型）等 B42 标准资源目录。

### 修改配置

所有全局参数集中在 `shared/PZExampleMod/Config.lua`；发布前将 `DEBUG` 设为 `false` 关闭调试日志。

## 重命名指南

如需将框架改为自己的 Mod 名称，需同步修改：

1. `contents/mods/PZExampleMod/` 文件夹名及其下的版本目录 `42/`（如需支持多版本，可复制为 `41/` 等并按版本调整内容）
2. `mod.info` 中的 `name` 与 `id`
3. `shared/PZExampleMod/Config.lua` 中的 `MOD_NAME` / `MOD_ID` / `NETWORK_MODULE`
4. （可选）`workshop.txt` 与 Lua 目录名 `media/lua/*/PZExampleMod/`（仅影响可读性，不影响功能，因为模块表 `PZExampleMod` 是全局变量）

## 注意事项

- B42 要求 `mod.info` 中包含 `poster=` 字段，poster 图片尺寸需为 **2 的幂次方**（本框架为 256x256）
- 游戏日志：当前会话在 `Zomboid\console.txt`，历史会话在 `Zomboid\Logs\`（`*_DebugLog.txt`）
- `sendToServer` 仅在客户端有效（需要本地玩家）；`sendToPlayer` / `sendToAll` 仅在服务器端有效
- MP 环境下 server 目录代码只在服务端运行，client 目录代码只在客户端运行；SP 下两者都在同一进程运行，命令自动回环
