# Plan & Decision Documents — Summary and Build Order

Seven shortlisted UK open-data app ideas, each taken through a deep-research stress test and written up as a plan-and-decision document. This file summarises the verdicts and states the recommended build order.

The shortlist came from the earlier stages: the [dataset catalogue](../uk-public-datasets-catalogue.md), the [viability assessment](../uk-public-datasets-assessment.md) (which produced the BUILD/WEDGE picks), and the [data centralisation report](../uk-data-centralisation-schemes.md) (which added storm overflow and planning data).

---

## Verdict summary

| # | Idea | Prior rank | Verdict | Confidence | Why it changed |
|---|------|-----------|---------|-----------|----------------|
| [01](01-mp-expenses.md) | MP expenses explorer | **#1 BUILD** | **DON'T BUILD** | High (~85% on competition) | TrustPolitics already ships the exact product, plus two more live tools |
| [02](02-station-usage.md) | Station usage explorer | **#2 BUILD** | **BUILD LATER** | Medium (6/10) | Merritt Cartographic + ORR's own dashboard already do it; reduced to a quality play |
| [03](03-ev-adoption-map.md) | EV adoption map | **#3 BUILD** | **BUILD LATER** (reframed) | 7/10 data, 6/10 competitive | Make/model doesn't exist at small-area; fleet skew dominates |
| [04](04-companies-house-psc.md) | Ownership network graph | **#4 WEDGE** | **DON'T BUILD** | Medium-high (7/10) | The ownership graph is not reconstructable from the data |
| [05](05-gritter-tracker.md) | Gritter tracker & name archive | **#5 WEDGE** | **BUILD LATER** | Medium | Wedge *confirmed*; licensing worse than assumed |
| [06](06-storm-overflow.md) | Storm overflow alerts | #2 of schemes | **DON'T BUILD** | High (~80%) | SAS runs app *and* national map; SewageMap open-sourced the hard part |
| [07](07-planning-data.md) | Planning constraints checker | #4 of schemes | **DON'T BUILD** | High | 10+ free checkers live; no GIS moat because the API does the spatial join |

**Zero BUILD NOW. Four DON'T BUILD, three BUILD LATER.**

---

## The meta-finding

The stage-2 assessment was search-based and systematically **overestimated openness**. Every "nobody has built this" claim that received deep scrutiny either collapsed or narrowed sharply. Three distinct failure modes:

1. **Incumbent missed by shallow search** (4 of 7 — MP expenses, station usage, planning, storm overflow). A first-page search finding no incumbent is weak evidence of absence. The incumbents here were real, live and often better-resourced.
2. **The data doesn't support the headline feature** (2 of 7 — EV adoption, PSC graph). Both ideas assumed a field or a join that does not exist. Neither could have been caught without inspecting the actual schema.
3. **Legal/licensing position worse than assumed** (3 of 7 — MP expenses, PSC, gritter). Personal data, defamation exposure, and approval-gated feeds respectively.

**Practical lesson for future screening:** before ranking an idea as open, verify (a) the specific field or join the killer feature depends on, and (b) at least three search framings including how a *non-technical* person would describe the product. Both cost minutes and both overturned rankings here.

A second pattern worth noting: in two cases the app layer was crowded but the **clean-data layer was genuinely absent**. Publishing a well-maintained joined dataset is often the unoccupied niche, with far lower legal exposure than a consumer app that makes claims about named individuals.

---

## Recommended build order

### 1. Gritter tracker & name archive — start now, launch by 1 November
The only idea where deeper research *strengthened* the case. No national UK gritter-name archive exists anywhere, and GitHub code search returns zero projects using this data. Lowest effort and highest viral-return in the set.

Hard sequencing constraint: it's a winter product. Work backwards from 1 November — permission-seeking and name-archive compilation in August, build September–October.

**Do first:** write to Transport Scotland for permission. Their DATEX II channel is approval-gated and expressly reserves the right to block users degrading the service, so this is a plan item, not a footnote. The separate "Gritting Routes – Scotland" dataset is properly open (OGL, WFS/WMS) and de-risks the utility half.
**Blocking unknown:** whether the gritter's *name* is a queryable field or only a UI label. The leaderboard dies without it. One live call settles it.

### 2. Station usage explorer — cheap enough to justify itself
Reduced from "nobody built this" to "nobody built a good one", which is a weaker but still real position. Economics are compelling: the full 25-year × 2,568-station corpus gzips to **249 KB**, so it's a static site at ~£1/month for ~15 dev-days. The NLC join works at 99.84%.

**Handle with care:** the growth animation is the feature the data punishes hardest — artefactual national jumps of +13.5% and +19.7% against a 0.4–5% baseline, and ORR removed ~27.5m entries from 16 of 25 station groups in the 2024-25 revision alone. Either annotate the breaks honestly or drop the animation.

### 3. MP expenses — as a dataset, not an app
The app is taken, but the **cleaned, joined, versioned open dataset is genuinely absent** (~12–15 dev-days, far lower legal exposure). This is the "be the data layer" play.

**Never ship a naive ranking.** Staff payroll is 70–78% of "expenses" and posts as a single year-end row; when missing, totals silently deflate ~75%. Ranking 2017-18 spend produces a table topped by remote-constituency Scottish MPs — a geography map, not a wrongdoing map. Auto-publishing that about named people is unfair and a live defamation vector, and OGL does not cover personal data.

### Optional — EV adoption map, only if you accept the tension
Buildable only in reframed form: no make/model at small-area, and 58.8% of BEVs are company-kept versus 9.7% of all cars. The honest map says "wealthy London boroughs lead"; the artefact-driven headline that earns traffic is wrong. The famous "Stockport is the UK's EV hotspot" story traces to one LSOA holding 200,517 company cars and 860 private ones — Stockport's true figure is 1.93%, exactly the national average.

Worth building **only** as an explicit methodology-and-debunking piece. Integrity and reach point in opposite directions here.

### Do not build
- **Companies House PSC graph** — corporate PSC registration numbers are optional free text; no published global identifier for PSC individuals. A fallback exists (corporate-only edges + density map, no individuals, 10–15 days) if the theme still appeals.
- **Storm overflow** — SAS occupies it twice over, and the one technical moat is a `pip install`.
- **Planning constraints** — no moat, ten live competitors, and MHCLG is closing the coverage gap itself.

---

## Verification caveat — read before acting on any data detail

This session's egress policy blocked direct outbound HTTPS to third-party hosts (403 on CONNECT for both `curl` and `WebFetch`). **No agent could make a live call to any of these APIs.** Per the environment's guidance, policy denials were reported rather than routed around.

Agents compensated using hosts that *are* reachable — principally GitHub — which produced genuine hands-on verification in several cases:

- **EV adoption:** parsed 1.38M rows from committed copies of the real DfT files; totals reconcile to published national figures (33.5m cars, 1.42m BEVs).
- **MP expenses:** parsed a 16.6 MB IPSA-derived dataset (1,446,219 rows × 27 cols, 2010–2018) from `poldham/ipsar`, verifying schema and £720.7m of claims.
- **Storm overflow:** read the source of ~15 production projects consuming these feeds, yielding endpoints for all 11 water companies and three schema families.
- **PSC:** parsed Companies House's own OpenAPI models to establish the identifier problem.
- **Planning:** verified against the platform's authoritative GitHub source repos; the coverage method reproduced MHCLG's published "145 data providers" figure exactly.

Each document labels claims as code-verified / search-derived / unverified, and each ends with a list of checks requiring a live connection. **Run those checks first on any project you take forward** — particularly the gritter name-field question, which is the single blocking unknown in the recommended first build.
