---
name: stash-init
description: "One-time setup to bootstrap a new Stash knowledge base. Use when user says 'stash init', 'setup stash', 'initialize', '初始化知识库', or when config.yaml is missing and the user wants to get started."
---

## Overview

First-time setup skill for Stash knowledge bases. Guides the user through vault configuration, directory scaffolding, category setup, and Obsidian Web Clipper installation.

**This skill runs once per vault.** After setup, all ongoing operations use the `stash` skill.

## Setup Flow

### Step 1: Vault Selection

Ask the user:
1. Do you have an existing Obsidian vault, or should we create a new one?
2. What is the vault path? (e.g., `~/Documents/my-knowledge-base`)

If the path doesn't exist, create it with `mkdir -p`.

### Step 2: Directory Scaffolding

Create the standard directory structure:

```
vault/
├── inbox/          # Clipper saves here, unprocessed
├── wiki/           # Compiled knowledge articles
├── output/         # Generated reports, guides, exports
└── archive/        # Processed inbox files (for provenance)
```

Run: `mkdir -p <vault>/{inbox,wiki,output,archive}`

### Step 3: Category Configuration

Ask the user about their interests. Present the default categories from `config.example.yaml` and let them:
- Keep defaults as-is
- Remove categories they don't need
- Add custom categories with their own keywords
- Rename display names

Generate `config.yaml` at the vault root with their choices.

Default categories (8):
1. AI & Technology
2. 生活方式 (Lifestyle)
3. 投资理财 (Finance)
4. 旅行攻略 (Travel)
5. 职业发展 (Career)
6. 健康养生 (Health)
7. 独立开发 (Indie Dev)
8. 育儿教育 (Parenting)

### Step 4: Wiki Index Files

Create initial (empty) index files:

**`wiki/_index.md`**:
```markdown
# Stash Knowledge Base Index

> Auto-maintained by Stash. Do not edit manually.

| Article | Category | Summary | Sources |
|---------|----------|---------|---------|
```

**`wiki/_sources.md`**:
```markdown
# Source Registry

> Maps clipped sources to wiki articles they contributed to.

| Source File | Wiki Articles | Compiled |
|-------------|---------------|----------|
```

**`wiki/_categories.md`**:
```markdown
# Category Tree

> Auto-maintained. Reflects folder structure under wiki/.

(categories will appear here after first compile)
```

### Step 5: Obsidian Web Clipper Setup

Guide the user through Clipper installation:

1. Install Obsidian Web Clipper:
   - Chrome/Edge/Brave: https://chromewebstore.google.com/detail/obsidian-web-clipper/cnjifjpddelmedmihgijeibhnjfabmlf
   - Firefox: https://addons.mozilla.org/en-US/firefox/addon/web-clipper-obsidian/
   - Safari: Available in the App Store

2. Configure Clipper:
   - Open Clipper settings → Templates
   - Set vault to the path from Step 1
   - Import the template JSON files from `clipper-templates/` in the plugin directory (drag the JSON in, or use the Import button)
   - Both templates write to the `inbox/` folder with Stash frontmatter (source, clipped_at, status: unprocessed)

3. Available templates:
   - **Stash — Default** — works with any webpage (Readability extraction). Fallback for all sites.
   - **Stash — 小红书** — optimized for Xiaohongshu (uses hand-tuned selectors: post body `#detail-desc`, images `.swiper-wrapper img`, comments `.comments-el`). Auto-triggers on `xiaohongshu.com`.

   Adding more platform templates later (公众号, Twitter, etc.) is easy: copy the 小红书 template, swap in that site's CSS selectors and `triggers`, keep the same frontmatter properties. The processing layer doesn't care how many templates exist — everything lands in `inbox/` as standard Markdown.

### Step 6: Obsidian Plugins (Optional)

Ask if the user wants to install recommended Obsidian community plugins. If yes, locate the `setup.sh` script in the plugin directory and run it:

```bash
bash <plugin_dir>/setup.sh "<vault_path>" --all
```

Plugins installed (all optional — Stash works on a plain Markdown vault):
- **Dataview** — browse wiki articles like a database in Obsidian. Stash doesn't depend on it (query mode reads the index directly), but it's handy for manual browsing.
- **Obsidian Git** — auto-backup vault to git
- **Tag Wrangler** (optional) — rename and merge tags
- **Local Images Plus** (optional) — download remote images locally

### Step 7: Confirmation

Print a summary:
```
✅ Stash knowledge base initialized!

Vault:      ~/Documents/my-knowledge-base
Categories: 8 configured
Clipper:    Install Web Clipper and import a template
Plugins:    Dataview installed

Next steps:
1. Open the vault in Obsidian
2. Click "Trust author and enable plugins" if prompted
3. Browse the web, clip content you like
4. Run "stash process" to compile your clippings into knowledge
```

## CLAUDE.md Generation

Create a `CLAUDE.md` at the vault root:

```markdown
# CLAUDE.md -- Project Instructions

## Project Identity
- Stash knowledge base — AI-maintained personal wiki compiled from web clippings.
- The wiki is managed by the Stash skill. Do not manually edit wiki articles.

## Configuration
- Always read `config.yaml` at the vault root before operating.

## Formatting Rules (Obsidian-Compatible)
- `[[wikilinks]]` for all internal links (never markdown-style links).
- `[[wikilinks|display text]]` when the display name differs from the target.
- YAML frontmatter on every article with: title, aliases, tags, sources.
```

## Error Handling

- If `config.yaml` already exists at the vault root, ask the user if they want to reconfigure or skip setup.
- If Obsidian is not installed, still complete setup — the vault works as a plain Markdown directory too.
- If `setup.sh` fails (e.g., GitHub API rate limited), warn but don't block — plugins can be installed manually later.
