# 📚 Stash

**把吃灰的收藏夹，变成可检索的知识库。**

[English](README.md) · [中文](README_CN.md) · MIT License

---

每天刷到好内容——旅行攻略、菜谱、技术帖、投资心得。你点了*收藏*，然后再也没打开过。收藏夹成了坟场。

**Stash** 打破这个死循环。一键 clip，Stash 自动帮你：

1. 🔖 **采集** —— 通过 [Obsidian Web Clipper](https://obsidian.md/clipper) 一键保存 → 落入 `inbox/`
2. 🤖 **分类** —— 按你的类目自动归类（关键词，或可选 LLM）
3. 📚 **编译** —— 提取核心要点，织成带链接、可搜索的 wiki
4. 💬 **调用** —— 对着全部收藏提问，生成攻略、研究报告、书单

从*「收藏即遗忘」*到*「知识为你所用」*，只需要一个 Claude Code 插件。

---

## 工作原理

```
   浏览器                     你的 Vault                     Claude Code
 ┌──────────┐   Clipper    ┌──────────────┐    stash      ┌────────────────┐
 │ 任意网页 │─────────────▶│   inbox/     │──────────────▶│  分类 +        │
 │          │   一键       │ (待处理)     │   process     │  编译          │
 └──────────┘              └──────────────┘               └───────┬────────┘
                                                                  │
                            ┌──────────────┐               ┌──────▼────────┐
                            │  archive/    │◀──────────────│  wiki/        │
                            │ (原文留档，  │   归档         │ (带链接的     │
                            │  可溯源)     │               │  知识文章)    │
                            └──────────────┘               └───────────────┘
```

**两层，职责清晰分离：**

- **输入层（Clipper）平台特异** —— 用手调的 CSS 选择器，在每个站点精准抓取正文、图片、评论（小红书、公众号等）。抓取质量在这一层决定。
- **处理层（Stash）平台无关** —— 落到 `inbox/` 的都是标准 Markdown。Stash 从不根据来源分支处理，只管分类、编译、建链。

## 安装

在 Claude Code 里，把这个 repo 加为插件 marketplace，再安装 `stash` 插件：

```
/plugin marketplace add DD-ai427/stash-kb
/plugin install stash@stash-kb
```

就这样——三个 skill（`stash`、`stash-init`、`stash-tidy`）即可用。无需 Python/Node 运行时，纯 prompt 插件。

## 快速上手

### 1. 初始化

在 Claude Code 里，进入你的 vault 目录：

```
stash init
```

自动搭建 `inbox/ wiki/ output/ archive/`，根据你的兴趣生成 `config.yaml`，创建 wiki 索引文件，并引导你配置 Clipper。

### 2. 配置 Web Clipper

1. 给浏览器装 [Obsidian Web Clipper](https://obsidian.md/clipper)
2. 指向你的 vault
3. 导入 [`plugins/stash/clipper-templates/`](plugins/stash/clipper-templates/) 里的模板——把 JSON 拖进 Clipper 的 **设置 → 模板**：
   - **Stash — Default** —— 任意网页（Readability 提取）
   - **Stash — 小红书** —— 小红书专用选择器（正文 + 图片 + 评论），命中 `xiaohongshu.com` 自动切换

   两个都写入 `inbox/`，带上 Stash 需要的 frontmatter（`source`、`clipped_at`、`status: unprocessed`）。

   > 以后加平台很简单：复制小红书模板，换成那个站点的 CSS 选择器和 `triggers` 即可。处理层完全不用动。

### 3. Clip 并处理

刷网页，clip 你喜欢的。然后在 Claude Code 里：

```
stash process
```

Stash 读取 `inbox/`，逐条分类、编译进 wiki，并把原文归档。

### 4. 查询与生成

```
我收藏过赛里木湖的什么攻略？
```
```
用我的旅行笔记，帮我排一个 5 天伊犁自驾行程
```

支持 **Quick**（仅 wiki）、**Standard**（wiki + 联网）、**Deep**（全量研究）三种深度。产出存到 `output/`——Markdown，或渲染成 HTML/PDF。

### 5. 保持健康

```
stash tidy
```

健康检查：坏链、孤立文章、inbox 积压、稀疏文章，还有**待补文章**——你已经链接但还没写的概念，作为下一步要写的线索浮出来。

## 三个 Skill

| Skill | 触发词 | 作用 |
|-------|--------|------|
| **stash-init** | `stash init`、`初始化知识库` | 一次性配置：vault、config、Clipper 模板 |
| **stash** | `stash process`、`整理收藏`、`收藏这个`、提问 | inbox → wiki · 直接粘贴入库 · 查询知识库 |
| **stash-tidy** | `stash tidy`、`检查知识库` | 健康检查 + 改进建议 |

## 真实案例

这个 repo 是拿真实旅行喂出来的。**15+ 篇 clip 的小红书攻略帖** → `stash process` → 一个串起草原、湖泊、路线的 wiki → 一次查询生成了一份**4 人 5 天伊犁自驾行程**，含预算表、酒店卡片、可打印的 HTML/PDF 攻略——**人均 ¥7,500**。

单篇 clip 走完整条流水线是这样：

```
inbox/2026-05-21-赛里木湖顺时针环湖保姆级攻略.md   （clip 的小红书帖）
   │  分类 → travel（关键词得分 6）
   │  提取 → hashtags：新疆、赛里木湖、自驾 …
   ▼
wiki/04-Travel/赛里木湖.md                        （编译成文章，带 wikilink）
archive/2026-05-21-赛里木湖顺时针环湖保姆级攻略.md  （原文留档，可溯源）
```

## 配置

vault 根目录的 `config.yaml` 定义类目和关键词，见 [`config.example.yaml`](plugins/stash/config.example.yaml)。类目随便增删改，分类会自动适配。

```yaml
categories:
  travel:
    display: "旅行攻略"
    keywords: [旅行, 攻略, 自驾, 民宿, 签证, 机票, travel, itinerary]
    folder: "04-Travel"
classification:
  method: keyword        # keyword | llm | hybrid
  fallback_category: misc
```

## 设计取舍

- **不爬取。** Stash 从不爬虫、不绕登录。所有内容都由你在已登录的浏览器标签里主动 clip——合法、稳定，而且经过你人工筛选（信噪比天然高）。
- **保留溯源。** 处理过的 clip 移到 `archive/`，绝不删除。每篇 wiki 文章都反向链接到原文。
- **Obsidian 原生。** `[[wikilinks]]`、YAML frontmatter、`![[嵌入]]`。你的 vault 始终是一堆纯 Markdown，无锁定。
- **中英双语。** 开箱即用，中英文内容都行。

## 已知限制

**懒加载站点（小红书等）的评论抓不全。** Web Clipper 抓的是**你点 clip 那一刻**页面 DOM 里的内容。而小红书的评论是懒加载的：楼中楼回复折叠在「展开更多回复」后面、没滚到的评论根本没请求下来、而且评论区常用「虚拟列表」（滚出屏幕的评论会被从 DOM 移除）。所以 clip 能稳定拿到正文和顶层评论，但**楼中楼/嵌套回复通常会丢**。这**不是改模板能修的**——缺的内容压根不在页面上，没有任何 CSS 选择器能让它凭空出现。

**当评论才是重点时，改用粘贴文本。** 对于价值全在评论里的讨论帖：

1. 在网页上滚动评论区，把想要的 `展开更多回复` 都点开
2. 选中评论 → 复制
3. 在 Claude Code 里：`收藏这个` 然后粘贴——你选中多少 Stash 就收多少，一条不丢

或者：点 clip 之前先滚到评论底部、展开所有回复让它们先渲染出来——但对用虚拟列表的站点不保险。

**小红书的图片。** 帖子图片是最难干净抓下来的，三重原因叠加：(1) 图片在懒加载轮播里，只有当前那张有真实 `src`，其余是 `data-src` 占位；(2) 图床（`xhscdn.com`）有 Referer 防盗链，就算 clip 到了 `![](url)`，在 Obsidian 里也可能 403 加载不出来；(3) 轮播的选择器会随小红书改版而失效。自带的小红书模板能**稳定拿到封面图**（走页面的 `og:image`），并对轮播做尽力抓取，但图片多的帖子，**可靠做法是手动存图**——右键存图或截图丢进 vault 的附件文件夹，用 `![[图片.png]]` 嵌入（本地图彻底绕开防盗链）。`setup.sh` 提供的 `obsidian-local-images-plus` 插件也能把 clip 到的远程图本地化，前提是 URL 没失效。

> 小红书模板里的选择器（`.swiper-wrapper`、`#detail-desc`、`.comments-el`）是尽力而为的默认值，会随小红书改 DOM 而漂移。如果 clip 下来内容很单薄，就打开真实页面看一下，更新 `plugins/stash/clipper-templates/xiaohongshu.json` 里的选择器。

## 许可

MIT —— 见 [LICENSE](LICENSE)。
