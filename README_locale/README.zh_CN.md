# MineClone 2

一个非官方的Minetest游戏，游玩方式和Minecraft类似。由davedevils从MineClone分拆。
由许多人开发。并非由Mojang Studios开发。<!-- "Mojang AB"'s Name changed at 2020/05, main README should change too -->

版本：0.79 (in development)

## 游玩

你开始在一个完全由方块随机生成的世界里。你可以探索这个世界，挖掘和建造世界上几乎所有的方块，以创造新的结构。你可以选择在「生存模式」中进行游戏，在这个模式中，你必须与怪物战斗，飢饿求生，并在游戏的其他各个环节中慢慢进步，如采矿、养殖、建造机器等等。

或者你也可以在「创造模式」中玩，在这个模式中，你可以瞬间建造绝大部分东西。

### Gameplay summary

* 沙盒式游戏，没有明确目标
* 生存：与怪物和飢饿搏斗
* 挖矿来获得矿物和宝物
* 附魔：获得经验值并以附魔强化你的工具
* 使用收集的方块来创造伟大的建筑
* 收集鲜花（和其他染料来源），令世界多姿多彩
* 找些种子并开始耕种
* 寻找或合成数百个物品之一
* 建立一个铁路系统，并从矿车中得到乐趣
* 用红石电路建造复杂的机器
* 在创造模式下，你几乎可以免费建造任何东西，而且没有限制。

## 如何开始

### 开始生存

* **挖树干**直到其破裂并收集木材
* 将木头**放入2×2的格子中**（你的物品栏中的「合成格子」），然后制作4块木材。
* 将4块木材按2×2的形状摆放在合成格子里，制作成合成台。
* **右键单击制作台**以获得3×3制作网格，制作更复杂的东西
* 使用**合成指南**（书形图标）了解所有可能的合成方式
* **制作一个木镐**，这样你就可以挖石头了。
* 不同的工具可以打破不同种类的方块。试试吧！
* 继续玩你想玩的。尽情享受吧！

### 耕种

* 找到种子
* 合成锄头
* 用锄头右键点击泥土或类似的方块，创建农田
* 将种子放在农田上，看着它们长出来
* 完全成熟后采集植物
* 在靠近水的地方农田会变湿并加速植物的生长

### 熔炉(Furnace)

* 制作熔炉
* 熔炉让你获得更多物品
* 上方栏位必须包含可熔炼物品（例如：铁矿石 iron ore）
* 下方栏位必须包含燃料物品（例如：煤炭 coal）
* 请参阅制作指南中的工具提示:了解燃料和可熔炼物品

### 额外帮助

更多关于游戏玩法、方块物品等的帮助可以在游戏内发现。您也可以从物品栏中获得帮助。

### 特殊物品

以下物品对于创意模式和冒险地图构建者来说很有趣。 它们无法在游戏中的物品栏中直接获得。

* 屏障(Barrier)：`mcl_core:barrier`

不过可以使用 `/giveme` 聊天命令来获取。 请参阅游戏内帮助以获取说明。

## 安装

此游戏需要 [Minetest](http://minetest.net) 运行（版本 5.4.1 或更高版本）。 所以你需要先安装 Minetest。 官方仅支持稳定版本的 Minetest。 不支持在 Minetest 的开发版本中运行 MineClone2。

要安装 MineClone2（如果您还没有安装），请将这个目录移动到您的 Minetest 数据目录的“games”目录中。 咨询 Minetest 的帮助以了解更多信息。


## 有用的链接

MineClone2 存储库托管在 Mesehub。 要贡献或报告问题，请前往那里。

* Mesehub: <https://git.minetest.land/MineClone2/MineClone2>
* Discord: <https://discord.gg/xE4z8EEpDC>
* YouTube <https://www.youtube.com/channel/UClI_YcsXMF3KNeJtoBfnk9A>
* IRC: <https://web.libera.chat/#mineclone2>
* Matrix: <https://app.element.io/#/room/#mc2:matrix.org>
* Reddit: <https://www.reddit.com/r/MineClone2/>
* Minetest forums: <https://forum.minetest.net/viewtopic.php?f=50&t=16407>
* ContentDB: <https://content.minetest.net/packages/wuzzy/mineclone2/>
* OpenCollective: <https://opencollective.com/mineclone2>


## 目标

- 至关重要的是: 基于 Minetest 引擎的单人游戏和多人游戏创建一个稳定、可修改、免费/自由的 Minecraft 克隆。
  当前，“Minecraft Java Edition”的许多游戏功能已经实现. 完善现有功能优先于新功能请求。
- 降低优先级但严格执行功能定位: “当前的 Minecraft 版本 + OptiFine”（OptiFine 实现仅在 Minetest 引擎支持的范围内）。
  这意味着与列出的 Minecraft 体验同等的功能优先于不满足此范围的功能。
- （可选）创建在真正低规格计算机上运行相对良好的高性能体验。
  不幸的是，由于 Minecraft 的机制和 Minetest 引擎的限制以及在低规格计算机上的玩家群非常少，因此很难研究优化。

## 完成程度

该游戏目前处于**测试**阶段。
它是可玩的，但功能还不完整。
并不能完全保证向后兼容，更新你的世界可能会导致小错误。
如果你想在生产中使用开发版的 MineClone2，master 分支通常是比较稳定的。 测试分支通常具有一些实验性 PR，应该被认为不太稳定。

已经实现以下功能：

* 工具，武器
* 盔甲
* 合成和熔炼系统：2×2 合成格, 合成台 (3×3 合成格), 熔炉, 合成教学
* 储物箱，大型储物箱，终界(末影)箱和界伏(潜影)盒
* 熔炉, 漏斗
* 飢饿和饱食
* 大多数怪物和动物
* Minecraft 1.12中的所有矿物<!-- Minecraft 1.17 added copper, so here must mark the version is 1.12, then main README should also add this -->
* 主世界的大部分方块
* 水和岩浆
* 天气
* 28 个生物群系(生态域) + 5 个下界生物群系(生态域)
* Nether地狱(下界)，炽热的维度，另一个维度的火热地下世界
* 红石电路（部分）
* 矿车（部分）
* 状态效果（部分）
* 经验系统
* 附魔(Enchanting)
* 酿造，药水，药水(尖)箭（部分）
* 船
* 火
* 建筑方块：楼梯、半砖、门、地板门、栅栏、栅栏门、墙。
* 时钟
* 指南针
* 海绵
* 史莱姆方块（不与红石互动）
* 小植物和树苗
* 染料
* 旗帜
* 装饰方块：玻璃、染色玻璃、玻璃片、铁栅栏、陶土（和染色版本）、头颅等
* 物品展示框
* 唱片机
* 床
* 物品栏
* 创造模式物品栏
* 农业生产
* 书和羽毛笔
* 一些服务器命令
* 村庄
* 结束
* ...

以下是不完整的特性：

* 一些怪物和动物
* 红石系统相关的东西
* 特殊矿车
* 几个重要的块和项目

额外功能（在Minecraft 中没有）。

* 内置合成指南，向你展示制作和熔炼的配方
* 游戏中的帮助系统包含了大量关于游戏基础知识、方块、物品等方面的帮助。
* 临时制作配方。它们的存在只是为了在你不在创造模式下时，提供原本无法获得的物品。这随着开发的进行和更多功能的可用，这些配方将被删除.
* v6地图生成器中箱子里的树苗。
* 完全可修改（得益于Minetest强大的Lua API）。
* 新的方块和物品：
  * 查找工具，向您显示任何涉及的帮助
  * 更多的半砖(台阶)和楼梯
  * 地狱砖栅栏门
  * 红地狱砖栅栏
  * 红地狱砖栅栏门
* 结构替换 - 这些 Minecraft 结构的小变体可作为替换，直到我们可以让大型结构工作：
  * 林地小屋（豪宅）
  * 下界前哨（堡垒）


与Minecraft的技性术差异：

* 高度限制为31000格(远高于Minecraft)
* 水平世界大小约为62000×62000格（比Minecraft中的小得多，但仍然非常大）。
* 仍然非常不完整和有问题
* 块、物品、敌人和其他功能缺失。
* 一些项目的名称略有不同，以便于区分。
* 唱片机的音乐不同
* 不同的材质（像素完美）
* 不同的声音（各种来源）
* 不同的引擎（Minetest）
* 不同的复活节彩蛋

...最后，MineClone2是自由软件！

## Other readme files

* `LICENSE.txt`：GPLv3许可文本
* `CONTRIBUTING.md`: 为那些想参与贡献的人提供资讯
* `API.md`: 关于MineClone2的API
* `LEGAL.md`: Legal information
* `CREDITS.md`: List of everyone who contributed

