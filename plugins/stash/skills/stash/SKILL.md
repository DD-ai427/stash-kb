---
name: stash
description: "Use when processing clipped web content into a knowledge base, querying the knowledge base, or capturing content directly. Triggers on: 'stash', 'process inbox', 'process', 'compile', '整理收藏', '整理', '收藏这个', 'save this', 'query', '查询', '查询知识库', or when the user asks a question that should be answered from the knowledge base. Also triggers when the user pastes text content and wants it saved to the knowledge base."
---

## Overview

Main operating skill for Stash knowledge bases. Three modes: **process** (inbox → wiki), **capture** (paste/URL → inbox → wiki), **query** (ask questions against the wiki). All opus-orchestrated with model-aware subagent dispatch.

**First action in every invocation:** read `config.yaml` from the project root. If missing, tell the user to run `stash init` (or `/stash-init`) and stop.

## Obsidian-Native Formatting

All wiki output MUST use Obsidian-native conventions:

- YAML frontmatter delimited by `---`
- `[[wikilinks]]` for ALL internal links -- NEVER use markdown-style `[text](url)` links for internal references
- `[[wikilinks|display text]]` when the display name differs from the target article
- Tags in frontmatter: `tags: [concept, topic]`
- Aliases in frontmatter: `aliases: [alternate name]`
- Image embeds: `![[image-name.png]]`
- Standard markdown for everything else (headings, lists, bold, code blocks, etc.)

## Model Strategy

Always set the `model` parameter explicitly when dispatching subagents.

| Task | Executor | Verifier |
|---|---|---|
| Inbox scanning, file listing, link checking | haiku subagents | none |
| Content extraction, summarization | haiku subagents | opus spot-checks |
| Wiki article writing, classification | sonnet subagents | opus reviews before commit |
| Deep research queries | sonnet subagents | opus orchestrates + verifies |
| Query synthesis, final reports | opus | none |

## Mode 1: Process (Inbox → Wiki)

**Trigger:** User says "process", "stash", "compile", "整理收藏", or "process inbox".

### Step 1: Incremental Detection

1. Read `config.yaml` for paths (inbox, wiki, archive directories)
2. Scan `inbox/` recursively for `.md` files using Bash `find`
3. Read `wiki/_index.md` to check what's already compiled
4. Identify **new** files (not yet in index) and **changed** files (hash mismatch)
5. If inbox is empty, tell the user "Inbox is empty. Clip some content first!" and stop

### Step 2: Read Metadata

Each inbox file arrives as standardized Markdown (the Obsidian Web Clipper already handled platform-specific extraction at capture time — selectors, images, comments). The processing layer is **platform-agnostic**: it does not branch on where content came from.

Just read the frontmatter as metadata:
- `source:` — origin URL (for provenance and backlinks)
- `platform:` — origin label (informational only; never used for branching)
- `clipped_at:` — when it was saved
- `status:` — should be `unprocessed`

If `platform:` or `source:` is missing (e.g., manually pasted content), that's fine — proceed with whatever is present.

### Step 3: Classification

For each file, determine the target category:

1. Read the file content (title + body)
2. Match against `config.yaml` category keywords
3. Score: count keyword hits per category, highest wins
4. If multiple categories tie, prefer the one with more specific keyword matches
5. If no category matches (score = 0), assign to `misc`
6. Extract inline hashtags (`#标签` / `#tag`) from the body text and add them to frontmatter tags — this is universal across platforms (小红书, Twitter, etc.), not platform-specific

**If `classification.method` is `llm` or `hybrid`:**
- Send the title + first 500 chars to a haiku subagent
- Prompt: "Classify this content into one of these categories: [list from config]. Return the category key only."
- Use LLM result as tiebreaker or override for low-confidence keyword matches

### Step 4: Extraction (sonnet subagents)

For each new or changed source, dispatch a sonnet subagent to:

1. Read the full inbox file
2. Extract:
   - **Key concepts** — main topics, entities, proper nouns
   - **Claims/facts** — actionable information, tips, data points
   - **Relationships** — how this content relates to existing wiki topics
3. Return a structured extraction:
   ```
   {
     concepts: ["concept1", "concept2"],
     claims: ["claim1", "claim2"],
     category: "travel",
     suggested_title: "Article Title",
     tags: ["tag1", "tag2"]
   }
   ```

### Step 5: Wiki Compilation (opus orchestration)

After extractions complete, opus decides for each:

- **New concept** → create a new wiki article in the appropriate category folder
- **Existing concept** → read the existing article, merge new information, add source backlink
- **Cross-references** → add `[[wikilinks]]` between related articles

### Wiki Article Format

```markdown
---
title: "Concept Name"
aliases: [alternate name, abbreviation]
tags: [domain, topic]
sources:
  - "[[archive/source-file.md]]"
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Concept Name

Core explanation of the concept.

## Details

Detailed information extracted from sources.

## Relationships

- Related to [[Other Concept]] because...
- See also [[Related Topic]]

## Sources

- [[archive/source-file.md]] -- key claims from this source
```

### Step 6: Archive & Index

1. Move processed inbox files to `archive/` (preserve filename)
   ```bash
   mv inbox/filename.md archive/filename.md
   ```
2. Update source references in wiki articles to point to `archive/` path
3. Update index files:
   - **`wiki/_index.md`** — add/update article entries with one-line summary
   - **`wiki/_sources.md`** — map source file → wiki articles it contributed to
   - **`wiki/_categories.md`** — rebuild category tree from folder structure

### Step 7: Summary

Print a summary for the user:
```
📚 Processed 5 clippings:
  → Created 3 new articles: [[Article A]], [[Article B]], [[Article C]]
  → Updated 1 article: [[Existing Article]]
  → Skipped 1 (duplicate of [[Existing Article]])
  → Category distribution: Travel (3), AI (1), Lifestyle (1)
```

---

## Mode 2: Capture (Pasted Text → Inbox → Wiki)

**Trigger:** User pastes text content and says "save this", "收藏这个", "stash this".

Capture is a convenience path for content the user already has as **text**. Stash does **not** fetch, crawl, or scrape a URL *to ingest it into the knowledge base* — capturing web pages is the Clipper's job (it runs in an already-authenticated browser tab and handles extraction). This keeps the ingestion boundary clean: **content enters the KB only through Clipper or pasted text, never by Stash fetching a page.**

(Query mode is different — it may use WebSearch/WebFetch to *answer* a question. That's research augmentation, not ingestion; it doesn't pull pages into the wiki.)

### Pasted Text

1. When the user pastes raw text content:
   - Ask for a title if it isn't obvious from the content
   - Ask for the source URL if the user has it (optional — for provenance)
2. Save to `inbox/manual-YYYY-MM-DD-<slugified-title>.md` with frontmatter:
   ```yaml
   ---
   title: "<title>"
   source: "<URL if provided, else empty>"
   platform: manual
   clipped_at: YYYY-MM-DD HH:mm
   status: unprocessed
   tags: []
   ---
   ```
3. Run Process mode on the new file

### If the user pastes a URL (not text)

Don't fetch it. Instead, tell them to clip it:

> Stash doesn't fetch web pages — that's what the Obsidian Web Clipper is for. Open the page in your browser, hit the Clipper (it's already logged in, so it gets the full post content and images), and it lands in your `inbox/`. Then run `stash process`.
>
> If you'd rather, paste the **text** of the page here and I'll stash it directly.

This applies to every site, including login-walled ones (小红书, x.com/twitter.com, WeChat) where fetching would fail or return truncated content anyway.

### Comment-heavy posts (known Clipper limitation)

The Web Clipper snapshots the DOM at click time. On lazy-loading sites (小红书 especially), comments load on scroll, nested replies hide behind "展开更多回复", and the list is often virtualized — so a clip reliably gets the post and top-level comments but **usually misses deeper/nested replies**. No template change fixes this; the content isn't in the page yet.

So:
- When a user says the comments came through incomplete, don't try to fix the template or fetch the page — explain the lazy-load cause and route them to paste-text.
- When the **value of a post is in its comments** (discussion threads, Q&A, crowd opinions), recommend the paste path up front: have them expand the replies they want on the page, select + copy, then `stash this` and paste. That captures 100% of what they selected.
- Content pasted this way is stashed exactly like any other clip (classify → compile → archive).

---

## Mode 3: Query

**Trigger:** User asks a question about topics in the knowledge base, or says "query", "查询".

### Step 1: Determine Query Depth

Present three options:

- **Quick** — wiki-only. Read indexes, find relevant articles, synthesize. No external calls. Best for: "What did I save about X?" or "Summarize my travel notes."
- **Standard** — wiki + web. Start from wiki, use WebSearch/WebFetch to fill gaps. Best for: "What's the best way to do X?" combining saved knowledge with current info.
- **Deep** — full research. Fan out sonnet subagents for parallel web research, opus synthesizes. Best for: comprehensive reports, guides, comparisons.

If the question is clearly a simple lookup (e.g., "What did I clip about hiking?"), default to Quick without asking.

### Step 2: Execute Query

**Quick depth:**
1. Read `wiki/_index.md` to find relevant articles
2. Read the most relevant articles (up to 5)
3. Synthesize an answer citing wiki sources

**Standard depth:**
1. Start with Quick — read wiki articles
2. Identify gaps in wiki coverage
3. Use WebSearch + WebFetch to find additional information
4. Synthesize, clearly marking which info came from wiki vs. web

**Deep depth:**
1. Generate a research outline (3-5 key questions)
2. Dispatch sonnet subagents in parallel — each researches one question via web
3. Opus collates results, cross-references with wiki, resolves contradictions
4. Produce a comprehensive report saved to `output/`

### Step 3: Render Output

- Default: render as markdown in the conversation
- If the user asks for a file: save to `output/<topic>-YYYY-MM-DD.md`
- If the user asks for HTML/PDF: generate formatted output (use the same HTML generation approach as kb skill)

### Step 4: Auto-Evolve (Background)

After delivering the answer, **immediately dispatch a background opus subagent** (via Agent tool with `run_in_background: true`). Do NOT ask permission — this runs silently.

The subagent:
1. Checks if the query response contained information not in the wiki
2. If **no new knowledge** → exit silently
3. If **yes** → act:
   - New concept → create wiki article
   - Enrichment → update existing articles with new info
   - New connections → add `[[wikilinks]]` between related articles
   - Update `wiki/_index.md`, `wiki/_sources.md`, `wiki/_categories.md`

**Constraints:**
- Never delete existing content — only add or refine
- Never create stub articles under 100 words — add to existing articles instead
- Quick queries rarely produce new knowledge — subagent should usually exit silently
- Must re-read any article before modifying (don't rely on cached state)

---

## Common Mistakes

- Running compile on the entire inbox when only a few files are new — always use incremental detection
- Using markdown-style links `[text](url)` instead of `[[wikilinks]]` for internal references
- Skipping index updates after processing — `_index.md`, `_sources.md`, `_categories.md` must always be updated
- Asking the user whether to auto-evolve — it runs silently in the background
- Defaulting to Deep query depth for simple lookups — try Quick first
- Fetching/crawling URLs from inside Stash — never. Web capture is the Clipper's job; if a user pastes a URL, redirect them to clip it (or paste the text).
- Deleting inbox files instead of moving to archive — always preserve for provenance
- Branching processing logic on `platform:` — the processing layer is platform-agnostic; platform is metadata only. Platform-specific handling belongs in the Clipper template (input layer), not here.
- Forgetting to extract inline `#hashtags` from the body — these are valuable classification signals across all platforms
- Creating a new article when an existing one covers the same concept — always check the index first
