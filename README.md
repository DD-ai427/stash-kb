# 📚 Stash

**Turn your bookmarks into a searchable knowledge base.**

[English](README.md) · [中文](README_CN.md) · MIT License

---

Every day you scroll past great content — travel tips, recipes, tech threads, investing insights. You hit *save*, and never see it again. Your bookmarks become a graveyard.

**Stash** breaks that loop. Clip anything with one click, and Stash automatically:

1. 🔖 **Captures** it via [Obsidian Web Clipper](https://obsidian.md/clipper) → lands in your `inbox/`
2. 🤖 **Classifies** it into your categories (keyword or optional LLM)
3. 📚 **Compiles** it into a linked, searchable wiki — extracting the key insights
4. 💬 **Answers** questions across everything you've saved, and generates trip guides, research reports, reading lists

From *"saved and forgotten"* to *"knowledge that works for you"* — with one Claude Code plugin.

---

## How it works

```
   Browser                    Your Vault                      Claude Code
 ┌──────────┐   Clipper    ┌──────────────┐    stash      ┌────────────────┐
 │ any web  │─────────────▶│   inbox/     │──────────────▶│  classify +    │
 │  page    │  one click   │ (unprocessed)│   process     │  compile       │
 └──────────┘              └──────────────┘               └───────┬────────┘
                                                                  │
                            ┌──────────────┐               ┌──────▼────────┐
                            │  archive/    │◀──────────────│  wiki/        │
                            │ (raw source, │   move        │ (linked       │
                            │  provenance) │               │  articles)    │
                            └──────────────┘               └───────────────┘
```

**Two layers, cleanly separated:**

- **Input layer (Clipper)** is *platform-aware* — hand-tuned CSS selectors grab the post body, images, and comments correctly on each site (小红书, WeChat, etc.). This is where extraction quality is won.
- **Processing layer (Stash)** is *platform-agnostic* — everything lands in `inbox/` as standard Markdown. Stash never branches on where content came from; it just classifies, compiles, and links.

## Install

In Claude Code, add this repo as a plugin marketplace, then install the `stash` plugin:

```
/plugin marketplace add DD-ai427/stash-kb
/plugin install stash@stash-kb
```

That's it — the three skills (`stash`, `stash-init`, `stash-tidy`) are now available. No Python or Node runtime required; Stash is a pure prompt-based plugin.

## Quickstart

### 1. Initialize

In Claude Code, from your vault directory:

```
stash init
```

This scaffolds `inbox/ wiki/ output/ archive/`, generates `config.yaml` from your interests, creates the wiki index files, and walks you through Clipper setup.

### 2. Set up the Web Clipper

1. Install [Obsidian Web Clipper](https://obsidian.md/clipper) for your browser
2. Point it at your vault
3. Import the templates from [`plugins/stash/clipper-templates/`](plugins/stash/clipper-templates/) — drag the JSON into Clipper's **Settings → Templates**:
   - **Stash — Default** — any webpage (Readability extraction)
   - **Stash — 小红书** — tuned selectors for Xiaohongshu (body + images + comments), auto-triggers on `xiaohongshu.com`

   Both write to `inbox/` with the frontmatter Stash needs (`source`, `clipped_at`, `status: unprocessed`).

   > Adding more platforms later is trivial: copy the 小红书 template, swap in that site's CSS selectors and `triggers`. The processing layer doesn't change.

### 3. Clip & process

Browse the web. Clip what you like. Then in Claude Code:

```
stash process
```

Stash reads your `inbox/`, classifies each clip, compiles it into the wiki, and archives the original.

### 4. Query & generate

```
What did I save about Sayram Lake?
```
```
Build me a 5-day Yili road-trip itinerary from my travel notes.
```

Ask **Quick** (wiki-only), **Standard** (wiki + web), or **Deep** (full research) questions. Outputs save to `output/` — Markdown, or rendered HTML/PDF.

### 5. Keep it healthy

```
stash tidy
```

Health check: broken links, orphan articles, inbox backlog, sparse articles, plus **planned articles** — concepts you've linked but not yet written, surfaced as your next things to write.

## The three skills

| Skill | Trigger | Does |
|-------|---------|------|
| **stash-init** | `stash init` | One-time setup: vault, config, Clipper templates |
| **stash** | `stash process` · `stash this` · questions | Ingest inbox → wiki · capture pasted content · query the knowledge base |
| **stash-tidy** | `stash tidy` · `health check` | Health checks + improvement suggestions |

## Real example

This repo was dogfooded on a real trip. **15+ clipped Xiaohongshu travel posts** → `stash process` → a linked wiki of grasslands, lakes, and routes → a query that generated a **5-day, 4-person Yili self-drive itinerary** with budget tables, hotel cards, and a printable HTML/PDF guide — **¥7,500/person**.

A single clip walks through the pipeline like this:

```
inbox/2026-05-21-赛里木湖顺时针环湖保姆级攻略.md   (clipped 小红书 post)
   │  classify → travel (keyword score 6)
   │  extract  → hashtags: 新疆, 赛里木湖, 自驾 …
   ▼
wiki/04-Travel/赛里木湖.md                        (compiled article, wikilinked)
archive/2026-05-21-赛里木湖顺时针环湖保姆级攻略.md  (original, kept for provenance)
```

## Configuration

`config.yaml` at your vault root defines categories and keywords. See [`config.example.yaml`](plugins/stash/config.example.yaml). Add, remove, or rename categories freely — classification adapts.

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

## Design notes

- **No scraping.** Stash never crawls or bypasses logins. All content is user-initiated through the Clipper, in an already-authenticated browser tab — legal, stable, and pre-filtered by you (so the signal-to-noise is high).
- **Provenance preserved.** Processed clips move to `archive/`, never deleted. Every wiki article backlinks to its source.
- **Obsidian-native.** `[[wikilinks]]`, YAML frontmatter, `![[embeds]]`. Your vault stays a plain folder of Markdown — no lock-in.
- **Bilingual.** Works with Chinese and English content out of the box.

## Known limitations

**Comment completeness on lazy-loaded sites (小红书 / Xiaohongshu, etc.).** The Web Clipper captures the page's DOM *at the moment you click*. Sites like Xiaohongshu load comments lazily, hide nested replies behind "展开更多回复" (show more replies), and often *virtualize* the list — comments scrolled off-screen are dropped from the DOM. So a clip reliably captures the post and top-level comments, but usually **misses deeper/nested replies**. This is **not fixable by the Clipper template** — the missing content simply isn't on the page yet, and no CSS selector can conjure it.

**When the comments are the point, paste them instead.** For discussion-heavy posts where the value lives in the replies:

1. On the page, scroll the comment section and click every "展开更多回复" to expand the threads you want
2. Select the comments → copy
3. In Claude Code: `stash this` and paste — Stash ingests 100% of what you selected, nothing dropped

Alternatively, before clicking Clip, scroll the comments to the bottom and expand all replies so they render first — but this is less reliable on sites that virtualize the list.

## License

MIT — see [LICENSE](LICENSE).
