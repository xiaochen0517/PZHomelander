# 《僵尸毁灭工程》Build 42 健康/状态/死亡系统 API 说明

> 来源：对 `tmp/projectzomboid.jar` 中 `zombie/**`（5080 个类）使用 Vineflower 反编译后分析得出，反编译产物位于 `tmp/decompiled/zombie/`。文中路径均相对该目录。

## 1. 两条并行的"血量"轨道

PZ 角色健康由两套独立系统叠加，`isDead()` 只要任一 `<=0` 即判定死亡：

| 轨道 | 归属类 | 范围 | 由谁改变 | 用途 |
| --- | --- | --- | --- | --- |
| **战斗生命值** `health` | `IsoGameCharacter` | 0.0 ~ 1.0 | 近战/远程/载具撞击等"外伤" | 瞬时战斗伤害结算 |
| **综合健康值** `overallBodyHealth` | `BodyDamage` | 0.0 ~ 100.0 | 每 tick 由各 `BodyPart.health` 汇总重算 | 饥饿/口渴/感染/流血/体温等"生理伤害" |

`isDead()`（`characters/IsoGameCharacter.java:4906`）：
```java
return this.health <= 0.0F
    || this.getBodyDamage() != null && this.getBodyDamage().getHealth() <= 0.0F;
```

## 2. 核心类速查

| 类 | 关键字段 | 说明 |
| --- | --- | --- |
| `characters/IsoGameCharacter.java` | `health`, `dead`, `kill`, `invincible` | 角色基类；`getHealth/setHealth`、`isDead/isAlive`、`Kill(...)`、`die()`、`applyDamage(float)`、`isGodMod/setGodMod`、`isInvulnerable`、`isInvincible/setInvincible` 均在此 |
| `characters/BodyDamage/BodyDamage.java` | `overallBodyHealth`, `isInfected`, `healthFromFood` | `Update()` 是每 tick 生理系统主循环；`calculateOverallHealth()` 汇总各部位得出总血量；`AddGeneralHealth/ReduceGeneralHealth` 是加减血入口 |
| `characters/BodyDamage/BodyPart.java` | `health`(0~100), `bleeding`, `isInfected`, `bitten`, `burnTime` | 单个身体部位的伤情，绝大多数字段有 public getter/setter |
| `characters/Stats.java` + `CharacterStat.java` | `Map<CharacterStat,Float>` | 饥饿/口渴/疲劳/压力/体温等属性容器，`CharacterStat` 定义每个属性的取值范围 |

### CharacterStat 属性一览

| 属性 | 范围 | 默认值 | 备注 |
| --- | --- | --- | --- |
| HUNGER 饥饿 | 0~1 | 0 | |
| THIRST 口渴 | 0~1 | 0 | |
| FATIGUE 疲劳 | 0~1 | 0 | 不直接致死 |
| ENDURANCE 耐力 | 0~1 | 1 | 不直接致死 |
| PAIN 疼痛 | 0~100 | 0 | 由各部位伤情汇总 |
| PANIC/STRESS/SANITY/MORALE | 各异 | — | 精神类，不致死 |
| POISON 中毒 | 0~100 | 0 | |
| ZOMBIE_INFECTION 真实感染 | 0~100 | 0 | 到 100 必定死亡（除非关闭感染） |
| ZOMBIE_FEVER 假感染/发烧 | 0~100 | 0 | |
| TEMPERATURE 体温 | 20~40℃ | 37 | 过低走独立冻死分支 |

## 3. 死亡判定与触发链路

生理伤害（饥饿/口渴/感染/流血/体温等）与死亡的**执行**是分离的两步：

```
BodyDamage.Update()（每 tick）
  → 计算各类伤害并 ReduceGeneralHealth() 扣血
  → calculateOverallHealth() 重新汇总 overallBodyHealth
  → （冻死/感染满值两个分支会直接把 health 或 overallBodyHealth 打到 0）
        ↓
PlayerOnGroundState.execute()（状态机，独立于 Update）
  → 检查 isDead()，为真则调用 die()
        ↓
die() → Kill() → onKilled()(IsoPlayer 覆写) → DoDeath() → OnDeath()
  → 触发 Lua 事件 OnCharacterDeath / OnPlayerDeath
```

战斗伤害（武器命中/载具撞击）则是**同一次 Java 调用栈内同步完成**扣血与死亡判定：

```
IsoGameCharacter.Hit(weapon, wielder, ...)
  → 触发事件 OnWeaponHitCharacter（可在此取消，见 §6）
  → 触发钩子 LuaHookManager.TriggerHook("WeaponHitCharacter", ...) 返回true则直接取消，0伤害
  → processHitDamage() 计算伤害
  → hitConsequences() → CombatManager.applyDamage() → isDead() 为真则同步 die()/Kill()
```

载具撞击（`onHitByVehicleApplyDamage`）走类似路径，但**没有**任何可取消的 Lua 钩子，仅受 `isGodMod()` 的 Java 内部判断保护。

## 4. Lua 可用 API（Mod 直接可调用）

PZ 通过 `LuaManager.setExposed(Class)` 把以下类**整类**暴露给 Lua（该类所有 public 方法/字段均可用 `obj:MethodName(...)` 调用）：

`IsoGameCharacter`、`IsoPlayer`、`IsoSurvivor`、`IsoZombie`、`BodyDamage`、`BodyPart`、`BodyPartType`、`Stats`、`CharacterStat`、`Moodle(s)`、`Metabolics`、`Thermoregulator`、`PerkFactory` 等。

常用方法：

```lua
player:getHealth() / player:setHealth(v)            -- 0~1 战斗生命值
player:isDead() / player:isAlive()
player:getBodyDamage():getOverallBodyHealth()        -- 0~100 综合健康
player:getBodyDamage():setOverallBodyHealth(v)
player:getBodyDamage():AddGeneralHealth(v) / ReduceGeneralHealth(v)
player:getStats():getHunger() / getThirst() / ...    -- 具体 getter 因绑定而异，也可用 CharacterStat 枚举查
player:isGodMod() / player:setGodMod(true)
player:isInvulnerable() / player:isInvincible() / player:setInvincible(true)
```

## 5. 相关 Lua 事件 / 钩子

| 名称 | 类型 | 触发时机 | 可否取消 |
| --- | --- | --- | --- |
| `OnWeaponHitCharacter` | 事件 | 武器命中，**扣血之前** | 不能直接取消，但回调内同步调用 `target:setAvoidDamage(true)` 可让本次命中在随后判断中被跳过 |
| `WeaponHitCharacter`（Hook） | 钩子 | 同上 | 回调返回 `true` 直接取消本次伤害（0 伤害） |
| `OnPlayerGetDamage` | 事件 | 生理伤害每次结算后（饥饿/口渴/中毒/流血/感染等，含原因字符串） | 仅通知，无法取消 |
| `OnCharacterDeath` / `OnPlayerDeath` | 事件 | 死亡流程 `DoDeath()`/`OnDeath()` 内 | 不能取消（死亡已发生） |
| `OnPlayerUpdate` | 事件 | 每 tick，角色 Update 完成后 | 用于"事后纠正"类需求 |

## 6. 现成的作弊/无敌系统

`characters/CheatType.java` 定义了完整的作弊枚举，经 `Cheats` 容器统一管理（`getCheats().isSet(CheatType.X)`），从 Lua 也可访问：

- **GOD_MODE**：`isGodMod()/setGodMod(bool)`。效果最强但副作用也多——每 tick 强制回满血、重置饥饿/疲劳/体温/耐力，普通玩家无法对其造成伤害。
- **HEALTH**（HealthCheat）：`isHealthCheat()/setHealthCheat(bool)`，仅用于放开调试面板手动改血量的权限，本身不是自动无敌。
- **INVISIBLE / NO_CLIP / ZOMBIES_DONT_ATTACK / FAST_MOVE / UNLIMITED_AMMO** 等：调试便利开关，与血量数值无直接关系。
- 独立字段 `IsoGameCharacter.invincible`（`isInvincible()/setInvincible(bool)`）：定义存在，但本次分析范围内未发现被 `applyDamage`/`BodyDamage.Update` 直接消费，具体用途需进一步排查引用点。

> 结论：GodMode 可以直接实现"无敌"，但会连带锁死饥饿/疲劳/体温等一大堆生理属性，通常不适合"只想不死，其它照常"的需求，这也是下一份方案文档要讨论的重点。
