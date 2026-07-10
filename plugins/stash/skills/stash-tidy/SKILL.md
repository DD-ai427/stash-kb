---
name: stash-tidy
description: "Run health checks on the Stash knowledge base and suggest improvements. Use when user says 'stash tidy', 'health check', 'tidy', 'lint', '整理知识库', '检查知识库', 'what needs fixing', or 'suggest improvements'."
---

## Overview

Health check and improvement skill for Stash knowledge bases. Scans the wiki for structural issues, identifies gaps, and offers auto-fix. Designed to run periodically (e.g., weekly) or on-demand.

**First action:** read `config.yaml` from the project root. If missing, tell the user to run `stash init` and stop.

## Model Strategy

| Task | Executor |
|---|---|
| File scanning, link extraction | haiku subagents |
| Issue detection, pattern analysis | sonnet subagents |
| Prioritization, false-positive filtering | opus |

## Health Checks

Run all checks in parallel using sonnet subagents, then opus collates and prioritizes.

### Check 1: Broken Links

Scan all wiki articles for `[[wikilinks]]` that point to non-existent files.

1. List all `.md` files under `wiki/` (excluding `_index.md`, `_sources.md`, `_categories.md`)
2. For each file, extract all `[[wikilink]]` references
3. Ignore links to `archive/…` — those are source backlinks, not wiki articles
4. Check if the target article exists

**Distinguish two cases — do NOT report all missing targets as critical:**

- **Broken link (Critical)** — the target looks like a typo, a renamed article, or a near-match to an existing article (e.g., `[[赛里木]]` when `[[赛里木湖]]` exists). These are genuine breakage. Report with source file, line number, and the likely intended target.
- **Unresolved forward-reference (Info)** — the target is a plausible new concept that simply doesn't have an article yet (e.g., `[[喀拉峻草原]]` linked from `[[赛里木湖]]` before the Kalajun article is written). This is **intentional and healthy** in a growing knowledge base — linking liberally marks concepts worth writing later. Surface these as **"planned articles"** — evolve opportunities, not errors. If the same unresolved target is referenced by 3+ articles, promote it as a strong suggestion to create that article next.

Judge which case applies by fuzzy-matching the target against existing article titles and aliases: a close match → likely broken; no close match but a coherent standalone concept → forward-reference.

### Check 2: Orphan Articles

Find wiki articles with zero inbound links from other articles.

1. Build an inbound link map: for each article, count how many other articles link to it
2. Articles with 0 inbound links are orphans
3. Exclude index files (`_index.md`, etc.) from the orphan check

**Severity: Warning** — orphans are disconnected from the knowledge graph but may still be valuable standalone.

### Check 3: Inbox Backlog

Check if there are unprocessed files sitting in `inbox/`.

1. Count files in `inbox/`
2. If > 0, report the count and suggest running `stash process`
3. If > 20, flag as warning — large backlogs suggest the user isn't processing regularly

**Severity: Info** (< 10 files) or **Warning** (> 10 files).

### Check 4: Sparse Articles

Find wiki articles with fewer than 200 words of content (excluding frontmatter).

1. For each wiki article, count words in the body (after frontmatter)
2. Articles under 200 words are sparse — they likely need enrichment
3. Suggest merging sparse articles into related fuller articles, or enriching via web search

**Severity: Info** — sparse articles aren't broken, but they add clutter without much value.

### Check 5: Missing Backlinks

Find links that should be bidirectional but aren't.

1. If Article A links to Article B, check if Article B links back to Article A
2. Not all links need to be bidirectional — only flag when both articles discuss related concepts
3. Use article titles and tags to judge relevance

**Severity: Info** — nice to have, not critical.

### Check 6: Stale Sources

Check if any source files in `archive/` have been modified since the wiki article was last compiled.

1. Read `wiki/_sources.md` for the source-to-article mapping
2. Compare source file modification times against article `updated:` dates
3. Flag articles whose sources are newer than the article

**Severity: Warning** — the wiki may be out of date.

## Output

### Report Format

Save to `output/tidy-YYYY-MM-DD.md`:

```markdown
# Stash Health Check — YYYY-MM-DD

## Summary
- 🔴 Critical: X issues
- 🟡 Warning: X issues
- 🔵 Info: X issues

## 🔴 Critical

### Broken Links
| Source | Broken Link | Suggestion |
|--------|-------------|------------|
| [[article.md]] | [[nonexistent]] | Create article or fix link |

## 🟡 Warning

### Inbox Backlog
15 unprocessed files in inbox/. Run `stash process` to compile.

### Orphan Articles
| Article | Category | Words |
|---------|----------|-------|
| [[orphan.md]] | AI-Tech | 450 |

## 🔵 Info

### Planned Articles (unresolved forward-references)
Concepts linked from existing articles that don't have their own article yet. Not errors — write next:
| Concept | Linked from | # refs |
|---------|-------------|--------|
| [[喀拉峻草原]] | [[赛里木湖]] | 1 |

### Sparse Articles
| Article | Words | Suggestion |
|---------|-------|------------|
| [[short.md]] | 89 | Merge into [[related.md]] |
```

### Auto-Fix

After presenting the report, ask the user:

> Found X issues. Want me to auto-fix what I can?
> - Fix broken links (remove or create stub articles)
> - Add missing backlinks
> - Process inbox backlog
> - Merge sparse articles into related ones

Only auto-fix with user confirmation. Never delete articles without asking.

## Evolve Mode

If the user says "suggest improvements", "what's missing", or "evolve", run a deeper analysis:

1. Read `wiki/_index.md` and `wiki/_categories.md`
2. Identify:
   - **Gaps** — concepts mentioned in articles that don't have their own article
   - **Thin categories** — categories with fewer than 3 articles (may indicate under-explored interests)
   - **Unconnected clusters** — groups of articles with no cross-category links
3. Present suggestions as a numbered list
4. User picks items → execute via process, query, or web search

## Common Mistakes

- Running all checks sequentially instead of in parallel — always dispatch subagents concurrently
- Flagging index files (`_index.md`, `_sources.md`) as orphans — they are meta-files, exclude them
- Auto-fixing without user confirmation — always ask first
- Suggesting deletion of sparse articles — prefer merging into related articles
- Not saving the report to `output/` — always persist for reference
