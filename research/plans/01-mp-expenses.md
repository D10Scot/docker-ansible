# MP Expenses Explorer — Plan & Decision Document

*Research date: 31 July 2026. Author: hands-on assessment commissioned to stress-test the prior catalogue's #1 BUILD recommendation.*

---

## 1. Decision summary

**Verdict: DON'T BUILD** (as scoped — a general-purpose MP-expenses comparison and outlier-finder tool).

**Confidence: High (≈85%) on the competitive finding; Medium-High (≈70%) on the overall verdict.**

The prior assessment ranked this #1 on the strength of one claim: that "no polished public-facing comparison/outlier-finder app was found." **That claim is no longer true, and appears to have been false at the time of writing or to have been overtaken within months.** Fresh searching surfaced at least three live, currently-maintained consumer sites doing precisely this job — including [TrustPolitics](https://trustpolitics.com/), which publishes per-MP expense pages for 2024-25 *and* ranked league tables by total expenses, travel, staffing and office costs, plus a derived "Activity Efficiency Score" (parliamentary activity per pound of operational spend). That is the proposed MVP, plus the stretch features, already shipped. Separately, [mpexpenses.org.uk](https://mpexpenses.org.uk/methodology) covers 2016-17 through 2025-26 with an automated IPSA + Parliament Members API pipeline, and [mpsexpenses.info](https://www.mpsexpenses.info/all/2024) has run all-MP totals for years with include/exclude toggles for staffing and travel. The wedge the assessment identified has been occupied. Meanwhile the underlying data turns out to be materially more treacherous than "ready CSV data, low technical bar" implies — I found a specific, verified trap (annual payroll posted as a single year-end row) that silently deflates recent-year totals by roughly 75% and would make a naive outlier finder rank remote-constituency MPs as the biggest spenders. Combined with genuine legal exposure from labelling named individuals as outliers, the risk-adjusted return is poor.

**The one condition that would flip this:** a *narrow, defensible, editorially-supervised* wedge that the incumbents explicitly decline to occupy — see §5 and §11. Building the general tool is not that.

---

## 2. The opportunity

### The problem/curiosity being served

Three distinct jobs-to-be-done sit under "MP expenses":

1. **"What did *my* MP claim?"** — constituent curiosity, usually episodic, triggered by a news cycle or a local dispute. Low intent, high volume.
2. **"Who is unusual, and why?"** — journalist/campaigner work. Needs comparison, normalisation and drill-down to individual claim lines. Low volume, high value.
3. **"Is the system working?"** — researcher/policy interest in aggregate trends, budget utilisation, the cost of the parliamentary estate. Very low volume.

IPSA's own publication serves (1) adequately and (2) poorly. The prior assessment's thesis was that (2) is unserved. It is now served by at least one incumbent.

### Why now (the honest version)

The genuine "why now" signals are real but weaker than they look:

- **Recurring news hook.** IPSA publishes bi-monthly (four-to-five months in arrears) and annually, so there is a predictable drumbeat of coverage. The pattern is long-established — cf. BBC's *"DUP's Ian Paisley Jr had highest expenses claim"* (£232,000) and *"MPs claimed £23m in expenses"* framing. Press appetite for "highest claimer" league tables is proven and durable.
- **Trust in politicians is at a 40-year low** (Ipsos Veracity Index), which sustains demand for accountability tooling.
- **Fifteen full reporting years** have now closed under IPSA (2010-11 through 2024-25), making longitudinal analysis newly viable.

**But the same "why now" applies to everyone else, and several people acted on it first.** The 2025-26 window appears to have seen a cluster of new UK MP-accountability sites launch (TrustPolitics, The People's Ledger, Restore Britain Tracker). That is evidence the opportunity was real *and* evidence that it has been consumed. Low technical barriers cut both ways: they are the reason this was attractive and the reason it is now crowded.

---

## 3. Data deep dive

### 3.1 What I could and could not access — stated plainly

**I could not reach theipsa.org.uk.** This session's egress policy returned `403` to `CONNECT` for `www.theipsa.org.uk:443`, `theipsa.org.uk:443`, `data.gov.uk:443`, `assets.ctfassets.net` (IPSA's Contentful CDN), `parliamentary-standards.org.uk`, `members-api.parliament.uk`, `en.wikipedia.org` and every other non-allowlisted host, via both `curl` and the WebFetch tool. The allowlist is effectively GitHub, PyPI, npm, crates.io and the Go module proxy. **I therefore did not download the primary IPSA CSVs, and I cannot report their exact current file names, byte sizes, HTTP headers or 2025-26 column headers from first-hand observation.** Everything in §3.4 marked *(secondary)* comes from search-index snippets of IPSA pages, not from the pages themselves.

**What I did instead — and it was substantive.** I located a real, large IPSA-derived dataset reachable through the one open host and analysed it end-to-end:

| Step | Detail |
|---|---|
| Source | `https://raw.githubusercontent.com/poldham/ipsar/master/data/ipsa.rda` |
| Provenance | The `ipsar` R data package by Paul Oldham (ORCID 0000-0002-1013-4390), MIT licence, built by concatenating IPSA's own per-financial-year individual-claims CSV downloads |
| Download | HTTP 200, **16,612,460 bytes** (15.8 MiB), XZ-compressed R serialisation |
| Parsed with | `pyreadr` 0.5.6 + pandas 3.0.5 (no R available in this environment) |
| Result | **1,446,219 rows × 27 columns**, fully readable |

This is genuinely IPSA's claim-line data, just frozen at a 2018 snapshot (`last_download` field = `2018-09-01`). Everything about *shape, semantics, quality and analytical traps* transfers; only the freshness does not. The companion `ipsa_commons.rda` (88,630 bytes) downloaded successfully but **failed to parse** — `pyreadr` raised `LibrdataError: Invalid file, or file has unsupported features`, so the concordance table's contents are known only from documentation, not observation.

### 3.2 Verified schema (observed, not inferred)

All 27 columns, with observed dtypes, null counts and cardinality across all 1,446,219 rows:

| # | Column | Type | Nulls | Distinct | Notes |
|---|---|---|---|---|---|
| 1 | `ipsa_name` | str | 2 | 952 | duplicate of `mps_name` |
| 2 | `mps_name` | str | 2 | 952 | **IPSA's own name string — the only MP identifier IPSA supplies** |
| 3 | `dp_name` | str | 0 | 951 | data.parliament `display_as`, **derived by the package author** |
| 4 | `member_id` | str | 0 | 952 | data.parliament ID, **derived, not native to IPSA** |
| 5 | `current_role` | str | 0 | 3 | `MP` / `Lords` / `Ex`, derived |
| 6 | `commons_short` | str | 0 | 952 | name-matching key, derived |
| 7 | `year` | str | 2 | 8 | `10_11` … `17_18` |
| 8 | `date` | Date | 2 | 2,886 | claim date |
| 9 | `claim_no` | str | 2 | 348,940 | ~4.1 rows per claim |
| 10 | `mps_constituency` | str | 2 | 650 | name string with `CC`/`BC` suffix, **no ONS/GSS code** |
| 11 | `category` | str | 2 | 12 | see below — should be 8, is 12 |
| 12 | `expense_type` | str | 2 | **381** | badly un-normalised |
| 13 | `short_description` | str | 448,487 | 147,725 | free text |
| 14 | `details` | str | 445,920 | 288,623 | free text |
| 15 | `journey_type` | str | 672,617 | 32 | travel only |
| 16 | `from` | str | 1,127,075 | 12,057 | free-text place |
| 17 | `to` | str | 1,127,067 | 13,037 | free-text place |
| 18 | `travel` | str | 1,207,620 | 10 | mode |
| 19 | `nights` | float | 672,617 | 18 | |
| 20 | `mileage` | float | 672,617 | 556 | |
| 21 | `amount_claimed` | float | 2 | 63,902 | |
| 22 | `amount_paid` | float | 2 | 63,895 | |
| 23 | `amount_not_paid` | float | 2 | 1,250 | **exculpatory field** |
| 24 | `amount_repaid` | float | 2 | 2,499 | **exculpatory field** |
| 25 | `status` | str | 2 | 4 | **exculpatory field** |
| 26 | `reason_if_not_paid` | str | 1,443,238 | 17 | **exculpatory field** |
| 27 | `last_download` | Date | 2 | 1 | package metadata |

Columns 1, 3–6 are the package author's additions. **The native IPSA schema is columns 7–26 (20 fields).** The package's own reference documentation confirms this framing, describing `member_id` as "data.parliament id" and `current_role` as a "derived field from name matching."

### 3.3 Observed volumes, distributions and money

**Money (all years, 2010-05-07 → 2018-03-31):**

```
amount_claimed    £720,692,469   mean £498.33   median £30.15   max £178,261.77   min -£13,200
amount_paid       £720,497,047   mean £498.19   median £30.09   max £178,261.77   min -£13,200
amount_not_paid       £195,142
amount_repaid         £735,264
```

- Claimed-vs-paid gap: **£195,422 — 0.027% of claimed.** Only **3,450 rows (0.24%)** have `claimed ≠ paid`.
- `status`: `Paid` 1,437,293 · `Repaid` 6,000 · `Not Paid` 2,337 · `Part Paid` 587.
- Median claim is **£30**. This is an overwhelmingly small-transactions dataset (stationery, train singles, parking) with a thin tail of very large rows.

**Spend by category (paid, all years):**

| Category | Amount | Rows |
|---|---:|---:|
| Staffing | £529,099,957 | 89,647 |
| Office Costs | £86,658,967 | 473,040 |
| Accommodation | £55,723,373 | 97,948 |
| MP Travel | £27,819,749 | 614,633 |
| Winding Up | £10,958,371 | 5,187 |
| Staff Travel | £6,040,583 | 151,348 |
| Travel | £1,724,990 | 102 |
| Miscellaneous Expenses | £976,247 | 2,929 |
| Start Up | £956,809 | 2,968 |
| Dependant Travel | £536,327 | 8,411 |
| Office Costs Expenditure | £1,299 | 3 |
| Miscellaneous | £374 | 1 |

**Staffing share by year — and the single most important number in this document:**

| Year | Non-staffing | Staffing | Staffing % |
|---|---:|---:|---:|
| 10_11 | £17,279,442 | £54,038,753 | 76% |
| 11_12 | £21,990,232 | £68,648,133 | 76% |
| 12_13 | £23,101,717 | £76,247,232 | 77% |
| 13_14 | £23,318,838 | £80,509,036 | 78% |
| 14_15 | £22,865,497 | £82,848,137 | 78% |
| 15_16 | £33,562,226 | £80,210,887 | 70% |
| 16_17 | £25,269,754 | £84,741,046 | 77% |
| **17_18** | **£24,009,384** | **£1,856,733** | **7%** |

**Roughly 75–78% of "MP expenses" is staff payroll** — non-discretionary, budget-capped, and paid by IPSA to employees rather than pocketed by the MP. This matches IPSA's own public statement that around 80% of MPs' business costs go on paying staff. Any headline "MPs claimed £Xm" figure is overwhelmingly a staff-wages figure.

### 3.4 Quality gotchas — every one of these observed directly

**(a) THE PAYROLL TIMING TRAP — the biggest one.** Staffing appears as a **single annual row per MP dated 31 March**, with `expense_type = "Payroll"` and `short_description = "Total payroll costs for the 2010-11 year"`. Example verified row: Adam Afriyie (Windsor CC), 2011-03-31, Staffing/Payroll, £68,686.91.

In the 2017-18 snapshot those payroll rows had **not yet been published**. Filtering `year == '17_18'` and inspecting `category == 'Staffing'` returns 6,922 rows totalling only £1,856,733 — and the top expense types are `Food & Drink Volunteer`, `Public Tr UND Volunteer`, `Own Vehicle Car Volunteer`. The `Payroll` type is entirely absent, where 2016-17 has 655 `Payroll` rows and £84.7m.

The consequence, which I reproduced: ranking MPs by 2017-18 `amount_paid` produces a table topped by **Ian Blackford (Ross, Skye and Lochaber) £100,166; Drew Hendry (Inverness) £86,236; Brendan O'Hara (Argyll and Bute) £83,106; Alistair Carmichael (Orkney and Shetland) £78,254** — and four Glasgow MPs. This is not a corruption league table. It is a map of how far MPs live from Westminster, produced because 75% of the data was missing and nothing in the file says so. **A tool that auto-ingests each bi-monthly release and ranks MPs will produce exactly this artefact, on a schedule, about named living people.**

**(b) Geography dominates travel.** In 2017-18, the top-20 total claimers averaged **£16,396** of travel spend against an all-MP mean of **£4,712** — a 3.5× gap. Remote-constituency MPs will always sit at the top of an unnormalised travel ranking.

**(c) Election-year churn breaks per-MP-per-year totals.** Distinct MP names per year: 652, 654, 659, 656, 653, **833**, 662, **748** against 650 seats. In general-election years, part-year MPs, `Start Up` (2,499 rows in 15_16) and `Winding Up` (2,938 rows in 15_16; 2,020 in 17_18) contaminate the comparison. Correspondingly, my 2017-18 *bottom* list — Gerald Kaufman £53, Mike Wood £39, George Osborne £1,182, Eric Pickles £965 — is a list of MPs who died or stood down, not frugal ones. **Both ends of a naive league table are misleading.**

**(d) Redaction is pervasive.** The literal marker `[***]` appears in **162,108 `details` values (11.2% of rows)** and **48,786 `short_description` values**, plus 1,851 `from` and 1,668 `to` values. IPSA states it cannot modify claim descriptions and redacts only for security or privacy. So the free-text drill-down — the thing that made 2009 explosive — is materially holed.

**(e) Category and expense-type vocabularies are dirty.** `category` has 12 values where 8 are intended: `Office Costs` vs `Office Costs Expenditure` (3 rows); `Miscellaneous Expenses` vs `Miscellaneous` (1 row); a bare `Travel` (102 rows) alongside `MP Travel`/`Staff Travel`/`Dependant Travel`. `expense_type` has **381** values with obvious near-duplicates: `Own Vehicle Car` / `Own Car MP` / `Own Vehicle Car MP Staff`; `Food & Drink Intern/Volunteer` / `Food & Drink Int/Volntr`; `Public Tr RAIL - SGL` / `Public Tr RAIL MP Staff - SGL`. A crosswalk table is unavoidable and must be maintained by hand as IPSA changes the Scheme.

**(f) `reason_if_not_paid` contains corrupt values.** Observed vocabulary of 17 values includes `Receipt Doesn't Match Claim` (49), `Recpt Not Match Claim` (36), `Not Match Claim` (2), `Recpt Not Match ClaimPart Paid` (1) — and one row whose reason is the string **`96.8`**, i.e. a column-shift bug that survived into publication. Legitimate reasons observed: `Not Under Scheme` (973), `Over 90 Days` (628), `Insufficient Evidence` (622), `Not Payable Under Scheme` (248), `Evidence Late` (165), `Pre-Dates IPSA Scheme` (138), `Duplicate Claim` (80), `Withdrawn MP Request` (12).

**(g) Negatives and zeros.** **9,967 rows have `amount_paid < 0`, totalling −£2,086,373** (credits, corrections, repayments); 8,374 rows are exactly zero. Summing without handling these overstates or understates depending on which naive fix you pick.

**(h) Constituency strings, not codes.** `mps_constituency` is a free-text name with a `CC`/`BC` suffix and **no ONS/GSS code**. Boundary changes (the 2023 review took effect at the 2024 general election) mean historic constituency names do not map cleanly to current ones. Two MPs in the file map to more than one constituency string.

**(i) Security and disability assistance costs are not itemised.** IPSA does not release detailed data on these, publishing them only in aggregated annual totals. So an MP with substantial accessibility costs may look anomalous in the annual aggregate with **no line-level explanation available in the data at all** — the tool literally cannot show the reason.

### 3.5 Current-generation access — *(secondary, unverified by me)*

| Attribute | Reported value | Source confidence |
|---|---|---|
| Landing page | `theipsa.org.uk/mp-staffing-business-costs` | High |
| Individual claims CSV | Per-financial-year "Individual business costs" spreadsheet download | High |
| Coverage | 2016-17 → 2025-26 on the current site; 2010-11 → present overall | Medium |
| Cadence | Bi-monthly, 4–5 months in arrears; plus an annual publication | High |
| Latest cited release | 12 March 2026, covering spending mainly processed Oct–Nov 2025 | Medium |
| Annual publication | 2024-25 released November 2025 | Medium |
| Search UI | `theipsa.org.uk/mp-staffing-business-costs/your-mp`, plus legacy `parliamentary-standards.org.uk/SearchFunction.aspx` and `/InteractiveMap.aspx` with MP / constituency / postcode / region / year / month / category filters | High |
| API | **None found.** No IPSA developer portal or documented JSON endpoint surfaced in any search | Medium-High |
| Licence | Open Government Licence (public-sector information) | Medium-High |
| 2024-25 headline | Average MP claimed £224,919; highest £367,659; 540 sitting MPs with comparable full-year data | Low-Medium *(from a competitor site, not IPSA)* |
| 2025-26 budgets | Staffing: London £281,980 / non-London £263,370. Accommodation non-London £35,930. Office cost budget +8.2% London, +8.8% non-London | Medium |

**Open item:** whether current IPSA CSVs now carry a Parliament member ID. I found no evidence they do. `mpexpenses.org.uk` states it joins IPSA to the Members API, which is consistent with either a native ID or its own name-matching layer.

### 3.6 Joining to MP metadata — harder than it sounds

**IPSA supplies no MP identifier.** It supplies a name string and a constituency string. The Parliament [Members API](https://members-api.parliament.uk/) is the natural join target (it exposes member IDs and supports constituency lookup by postcode, ONS/GSS code, name or initial), but the bridge must be built.

The `ipsar` author documented this and it is worth quoting because it is the clearest first-hand account available:

> "the IPSA data is not particularly consistent with the data.parliament name format… This proved to be quite involved… We were obliged to feel our way forward with this and to engage in some manual clean up. It would be useful in future if IPSA and data.parliament harmonised their approaches to names and **if IPSA adopted the data.parliament member ids as a key**."

The five documented failure modes: (i) name-format variation between the two sources; (ii) MPs leaving the Commons; (iii) MPs elevated to the Lords, at which point their name becomes "Lord/Baroness X of Y"; (iv) MPs who never claimed; (v) sheer scale — 952 IPSA names against 4,695 data.parliament member records. On top of this, **constituency boundary changes at the 2024 general election** mean any historic time series needs a boundary crosswalk, and party affiliation changes (defections, whip removals) need to be point-in-time.

**Assessment:** this join is a one-to-two-week job to build properly and a permanent maintenance liability. It is not the "low technical bar" the prior assessment described. It is, however, the single most valuable asset you would create — and two incumbents have already created it.

---

## 4. Competitive landscape

**The prior assessment's central claim does not survive contact with fresh searching.** Caveat up front: **I could not load any of these sites** (egress blocked). My evidence is search-index results showing live pages with current-year content and specific figures. That is strong evidence of existence and freshness; it is weak evidence about design quality, traffic or commercial durability.

| Product | What it does | Freshness evidence | Status |
|---|---|---|---|
| **[TrustPolitics](https://trustpolitics.com/)** — "UK MP Accountability Engine" | **The proposed product, already built.** Per-MP expense pages by year (`/mp/carla-denyer/expenses/2024-25` with full category breakdown and rank out of 540 sitting MPs). Ranked lists of every MP by **total expenses, travel, staffing, office costs**. Plus an **"Activity Efficiency Score"** — parliamentary activity per pound of operational spend. Plus votes and donors. Editorial blog ("Fifteen Years of IPSA"). | 2024-25 data live; blog content dated to the 15-year mark | **LIVE — direct competitor, superset of the MVP** |
| **[mpexpenses.org.uk](https://mpexpenses.org.uk/methodology)** | Searchable IPSA claims, every figure linked back to its original IPSA record. Automated ingest of IPSA releases **plus the Parliament Members API** for name/party/constituency/photo/current-status. Explicit editorial stance: *"no ranking or interpretation — just public data."* Published methodology and explainer pages. | Coverage stated as **2016-17 to 2025-26**; "updated automatically when new IPSA data is released" | **LIVE — occupies the search wedge; deliberately vacates the ranking wedge** |
| **[mpsexpenses.info](https://www.mpsexpenses.info/all/2024)** | Per-MP expenses, interests, votes and contact details; **all-MP totals page with toggles to include/exclude staffing costs and travel claims.** Long-established — cited by the `ipsar` README in 2018. | `/all/2024` serving 2024-25 | **LIVE — and already ships the fairness controls** |
| **IPSA's own tools** | `your-mp` search; legacy `parliamentary-standards.org.uk/SearchFunction.aspx` (MP / constituency / postcode / region / year / month / category / expense-type filters) and `/InteractiveMap.aspx` (region → constituency summaries). Per-MP CSV download. | Continuously maintained by statute | **LIVE — dated UI, but functionally broad** |
| **[The People's Ledger](https://thepeoplesledger.co.uk/)** | "UK MP Accountability Tracker" — voting records, financial interests, parliamentary activity, per-MP pages | Live per-MP pages | **LIVE — adjacent, overlapping** |
| **Restore Britain Tracker** | Polling, membership and MP accountability | Live | **LIVE — adjacent, partisan framing** |
| **[Westminster Accounts](https://www.tortoisemedia.com/data/the-westminster-accounts)** (Sky News + Tortoise Media) | Searchable database of MP earnings, donations and gifts; postcode search; built on the Flourish SDK. **Not IPSA expenses** — Electoral Commission and Register of Interests data. | Built to cover the 2019-24 parliament "until the next general election" — that election has happened | **UNCERTAIN — likely stale/archived for the current parliament** |
| **mySociety / TheyWorkForYou** | Publishes a historic [MP Expenses 2001-2009 dataset](https://data.mysociety.org/datasets/mp-expenses/). TheyWorkForYou itself is very much alive (voting-summaries update published July 2026). | Expenses data is pre-IPSA only | **LIVE but not competing on IPSA-era expenses** |
| **`ipsar` R package** | Researcher-facing R data package, 1.45m claims 2010–2018 | Last data download **2018-09-01**; version 0.0.0.9000; repo status badge still "WIP" | **ABANDONED — 8 years stale** |

### The gaps that genuinely remain

1. **Normalised, confounder-aware comparison.** Every incumbent I found either ranks raw totals (TrustPolitics) or refuses to rank at all (mpexpenses.org.uk). Nobody appears to publish *travel cost per mile from Westminster*, *spend as % of the MP's applicable budget cap*, or *like-for-like peer-group comparison* (same nation, similar constituency area, similar London/non-London status).
2. **Change detection.** Nobody appears to alert on *movements* — "your MP's office costs rose 40% this release" — which is where the actual journalistic signal lives, as opposed to static levels.
3. **The exculpatory fields.** No incumbent I could see surfaces `status`, `reason_if_not_paid`, `amount_not_paid` or `amount_repaid` prominently. Doing so would be genuinely differentiating *and* the right thing to do.

### Why those gaps are not a business

They are real gaps, but: (a) they are *features*, not products — TrustPolitics could add budget-percentage normalisation in a sprint, and it has the harder asset (the join, the pipeline, the SEO surface) already; (b) gap (1) makes the tool *less* shareable, because a normalised table is less dramatic than a raw one; (c) gap (2) is the highest-value feature and has the smallest audience — a handful of lobby journalists who mostly already have a spreadsheet.

**The wedge is real but thin, and it is a feature-shaped wedge inside an occupied category.**

---

## 5. Product definition

*Presented for completeness, and as the specification you would use if the kill criteria in §11 were somehow all cleared.*

### Target user

**Primary: the local-newspaper or regional-desk journalist and the constituency campaigner.** They need a defensible, citable, "is this normal?" answer about one named MP, fast, ahead of a deadline. National lobby journalists have their own analysts. General public curiosity converts to traffic but not to value.

**Explicitly not the target:** the "political anorak" browsing league tables. That user is served, monetises at approximately zero, and is the user whose engagement patterns push a product toward exactly the irresponsible framing described in §10.

### MVP — in scope

- Ingest IPSA individual-claims CSVs, all available years; normalise the 381 expense types to a maintained crosswalk of ~30 canonical types; normalise the 12 category values to 8.
- Build and version the IPSA-name → Parliament-member-ID → constituency-GSS-code bridge, with a manual override table and a **hard failure** (not a silent guess) on unmatched names.
- Per-MP page: total, category breakdown, year-over-year, **and** the exculpatory panel (`status`, `amount_not_paid`, `amount_repaid`, `reason_if_not_paid`), with a deep link to IPSA's own record for every figure.
- **Peer-group comparison, not a global league table** (see killer feature).
- Completeness indicator per MP-year: *"Payroll row present / not yet published"*, *"Part-year MP"*, *"Election year"*. Any MP-year lacking its payroll row is **excluded from comparison by default**, not silently ranked.
- Bulk CSV/JSON export of the cleaned, joined dataset — the thing researchers actually want and nobody currently offers.
- Postcode → constituency → MP lookup.

### MVP — explicitly out of scope

- ❌ Any global "highest claimer" league table on raw totals.
- ❌ Any word implying wrongdoing: "outlier", "flagged", "suspicious", "worst offender", "red flag".
- ❌ Free-text search of `details`/`short_description` as a headline feature — 11% redacted and full of third-party personal data.
- ❌ Naming landlords, suppliers, family members or staff extracted from claim descriptions.
- ❌ User comments, voting, upvoting or crowdsourced "review this claim" mechanics (the *Guardian*'s 2009 crowdsourcing app worked because a newsroom stood behind it).
- ❌ Real-time anything. The data is four to five months in arrears by design.
- ❌ Non-Commons bodies (Lords, Senedd, Holyrood, Stormont) in v1.

### The single "killer" feature

**"Compared to whom?" — automatic peer-group normalisation.**

For any MP, instead of a rank out of 650, show their spend against a *defensible comparison set*: MPs in the same nation/region, with similar constituency area and distance from Westminster, matched on London-area status, and on the same budget entitlement — expressed as **percentage of the applicable IPSA budget cap consumed** (staffing £281,980 London / £263,370 non-London; accommodation £35,930 non-London for 2025-26). Every headline number becomes "83% of the staffing budget available to her, against a peer median of 91%."

This is the feature that makes Ian Blackford stop looking like a villain and start looking like the MP for a constituency the size of Wales — and it is the only framing that is simultaneously more useful, more honest, and materially harder to sue over than the raw ranking every incumbent currently ships. **It is also the feature that will get the least traffic**, which is the crux of why this is a bad business and a good piece of civic infrastructure.

---

## 6. Technical plan

Deliberately boring; the difficulty is entirely in the data layer.

**Architecture:** batch ETL → normalised store → statically generated site.

```
IPSA CSVs (manual/scripted download, bi-monthly)
        │
        ▼
  Python ingest: pandas → normalise categories & expense types
        │        → handle negatives, zeros, redaction markers
        │        → detect payroll-row presence per MP-year
        ▼
  Name-matching bridge (fuzzy + manual override YAML)
        │  ← Parliament Members API (member IDs, party, constituency history)
        │  ← ONS constituency codes + area/centroid; boundary crosswalk 2010→2024
        ▼
  SQLite/DuckDB artefact (~200–400 MB uncompressed for 15 years)
        │
        ▼
  Static site generation (~700 MP pages + ~650 constituency + index pages)
        │
        ▼
  CDN-hosted static files + downloadable dataset
```

**Stack:** Python 3 + pandas/DuckDB for ingest; DuckDB or SQLite as the artefact; Astro or Eleventy for generation; Plotly/Observable Plot or hand-rolled SVG for charts; everything version-controlled in Git so **every published figure is reproducible to a commit** — which matters enormously in §10.

**Why static:** the data changes six times a year. There is no reason to run a database in production. Static means no query-injection surface, no scaling concern, no outage, and — critically — an immutable, auditable record of exactly what was published when. If a figure is challenged, you can show precisely what your site said on a given date and which IPSA release it came from.

**Pipeline cadence:** triggered manually after each IPSA publication (six per year, plus the annual). **Do not auto-publish.** A human must approve each release — this is the control that prevents §3.4(a) from shipping.

**Hosting and running cost:**

| Item | Monthly |
|---|---|
| Static hosting + CDN (Cloudflare Pages / Netlify free tier) | £0 |
| Domain | ~£1 |
| Object storage for dataset exports | ~£1 |
| CI minutes for the six annual builds | £0 |
| Error/uptime monitoring | £0 |
| **Total infrastructure** | **£0–5/month** |
| Professional indemnity / media liability insurance *(see §10)* | **£30–80/month — the real cost** |

Infrastructure is free. Insurance is not, and it is not optional if you publish ranked judgements about named MPs.

---

## 7. Effort & timeline

For one competent developer, working alone:

| Workstream | Dev-days | Notes |
|---|---:|---|
| Acquire + document all IPSA CSVs, all years | 1–2 | Trivial *if* the site is reachable; downloads are per-year |
| Ingest, category/expense-type normalisation | 3–4 | 381 → ~30 crosswalk is a genuine slog |
| Data-quality guards (payroll detection, negatives, part-year, redaction) | 2–3 | **Do not skip. This is the product.** |
| Name-matching bridge to Members API + manual overrides | 4–6 | The `ipsar` author's account suggests this is the honest range |
| Constituency codes, areas, boundary crosswalk 2010→2024 | 2–3 | |
| Peer-group model + budget-cap table | 2–3 | Budget caps must be hand-entered per year from IPSA's Scheme PDFs |
| Site generation, ~1,400 pages, charts | 3–4 | |
| Responsible-presentation layer: caveats, methodology, exculpatory panels, correction policy | 2–3 | Non-negotiable |
| Legal review + DPIA + privacy notice | 1–2 dev-days **+ external counsel** | See §10 |
| **MVP total** | **20–30 dev-days** | Against the prior assessment's implied "low technical bar" |

**Ongoing maintenance: 1.5–3 days per IPSA release × 6 releases = 10–18 days/year**, plus:

- Every by-election adds an MP to reconcile; every defection changes a party label.
- IPSA changes the Scheme annually — new expense types, renamed categories, revised budget caps.
- Boundary or Members API changes.
- **Correction handling.** MPs have publicly attacked IPSA's own publication as "seriously misleading", complaining that claims initially refused were later approved. You will receive corrections. Each one is a manual investigation.

This is a **~25 dev-day build with a ~15 day/year floor**, indefinitely, for a product with three live competitors.

---

## 8. Distribution

*Assessed honestly, including where it is already lost.*

**SEO.** The head terms — `mp expenses`, `[MP name] expenses`, `my mp expenses`, `mp expenses by constituency` — are the entire game, and TrustPolitics, mpexpenses.org.uk and mpsexpenses.info are already ranking on them with per-MP pages. IPSA itself holds the brand terms. Entering now means competing for ~650 long-tail MP-name queries against sites with an age and link advantage. Realistically achievable: `mp expenses compared to budget`, `is my mp's spending normal`, `mp travel costs by constituency` — low-volume, low-competition, low-value.

**Press hooks (the strongest asset).**
- Each bi-monthly IPSA release generates a predictable news cycle; the annual publication is the big one.
- The genuinely *original* pitch is a counter-narrative: *"The MPs who look like the biggest spenders are mostly the ones who live furthest from London — here's the map."* That is a better story than another league table and it is journalistically defensible.
- Regional press is the realistic target — a per-MP page a local paper can cite is exactly what a district reporter needs.

**Communities.** r/ukpolitics (~560k members) is the largest relevant venue and is heavily moderated and hostile to self-promotion — expect one shot. Also: the mySociety/civic-tech community, PSA Parliaments (academic), Bureau of Investigative Journalism's local network, `#ddj` on Mastodon/Bluesky.

**Viral realism.** The viral artefact here is a league table, and the league table is the thing §10 says not to build. **The distribution strategy and the ethics strategy are in direct conflict**, and every incumbent has resolved that conflict by shipping the league table. That is a structural fact about this product, not a solvable tension.

---

## 9. Sustainability

| Option | Realistic assessment |
|---|---|
| **Display advertising** | ~£1–4 RPM on UK politics traffic. Would need ~250k pageviews/month to clear £500. Not attainable against three incumbents. **No.** |
| **Consumer subscription** | Nobody pays for MP expenses data. **No.** |
| **Journalist/researcher API or data subscription** | The addressable market is perhaps 50–200 UK organisations, most of whom will use the free CSV. Perhaps £20–50/mo × 10–20 seats at absolute best. **Marginal, and only after establishing credibility over years.** |
| **Grant funding** | The plausible route: JRRT, Open Society, Nuffield, the Google News Initiative, or an ICFJ/EJC data-journalism grant. UK civic-tech grants of £10k–50k exist for exactly this. Requires a charity/CIC wrapper and a non-trivial application effort. **Realistic but slow, and grant funders will ask "why not just fund mySociety/TrustPolitics?"** |
| **Consultancy halo** | The cleaned, joined dataset is a credible portfolio piece for data-engineering or data-journalism work. **The most honest monetisation: this is marketing, not a business.** |
| **Donations** | £20–100/month at best, on the mySociety model, and only with a real reputation. |

**Conclusion: there is no revenue model. This is a cost centre — roughly £400–1,000/year in insurance and domain, plus 15 days of unpaid labour annually — justified only by civic value or personal portfolio value.** That is a defensible reason to build something; it is not a reason to build *this* thing when three others already exist.

---

## 10. Legal, ethical & fairness considerations

**This section is the reason the verdict is DON'T BUILD rather than BUILD LATER.** The data names real, living, litigious individuals with parliamentary privilege, legal budgets and strong incentives to defend their reputations.

### 10.1 Licensing and data protection

**The Open Government Licence covers the data but expressly does not cover personal data.** OGL v3 grants a worldwide, royalty-free, perpetual, non-exclusive licence to copy, publish, adapt and commercially exploit the information — but its exclusions carve out personal data, information subject to other IP rights, and third-party rights the provider cannot license.

MP expenses data is *entirely* about identified natural persons. Republishing it is UK GDPR processing and you are the controller of your own republication. That means:

- **A lawful basis is required.** Legitimate interests (Art 6(1)(f)) is the plausible one, supported by a documented **Legitimate Interests Assessment** balancing accountability of public officials against the individual's rights. MPs are public figures acting in a public capacity, which is a strong balance in your favour — *for MPs*.
- **Third parties in the data are a different matter.** Claim descriptions contain landlords, suppliers, agents, family members and staff. These are private individuals with a much stronger privacy interest and no public-accountability offset. The Speaker separately pressed IPSA not to publish MPs' landlord and agent details, which shows how live this is. **Do not surface free-text claim descriptions containing third-party names. This alone kills the "searchable receipts" feature.**
- **Article 14 transparency** obligations apply to data obtained other than from the data subject: a privacy notice explaining source, purpose, retention and rights.
- **Erasure and rectification requests will arrive** and must be handled, even if most will be refused on Art 17(3) grounds.
- **A DPIA is advisable** — large-scale processing of personal data about identifiable individuals for evaluation/scoring purposes is close to the ICO's DPIA triggers, and "scoring" is precisely what an outlier finder does.
- **Crucially: truth is not a defence to a data-protection claim.** Publishing accurate personal data can still breach GDPR. A defamation-focused risk assessment is insufficient.
- **Verify the licence yourself.** I could not load IPSA's own pages; the OGL attribution is from secondary sources. Confirm the exact licence statement and required attribution wording before publishing anything.

### 10.2 Defamation

Under the **Defamation Act 2013**:

- **s.1 serious harm** — a claimant must show serious reputational harm. For an MP, an implication of misusing public money clears that bar easily.
- **s.2 truth** — a complete defence if the *sting* of the statement is substantially true. "MP X claimed £Y" is verifiably true. But **the sting of an outlier finder is not the number — it is the imputation.** Labelling an MP an "outlier", "flagged", or placing them on a "worst offenders" list carries a natural-meaning imputation of impropriety, and *that* is what you would have to prove true. You cannot, because the raw data does not support it.
- **s.3 honest opinion** — available, but only if you **indicate the basis of the opinion** and the opinion is one an honest person could hold on those facts. This is exactly why every comparative figure must be shown with its methodology and its source link inline. It is a usable defence *if the product is designed for it from day one*.
- **s.4 publication on a matter of public interest** — available, requiring a reasonable belief that publication was in the public interest. Standard responsible-journalism conduct strengthens it: contacting the subject, explaining the allegation, allowing time to respond, and publishing the response.

**The practical line:** publishing a *ranking* of true, sourced figures is defensible. Publishing a *characterisation* derived from those figures is where liability lives. The word "outlier" in the project brief is the single most legally expensive word in it.

### 10.3 The fairness problem — the data actively misleads

Everything below was observed directly in §3, not hypothesised. **Each is a mechanism by which a technically-correct tool produces a substantively false accusation about a named person:**

| Confounder | Evidence | Effect if ignored |
|---|---|---|
| Staffing dominates | 70–78% of spend is staff payroll | "Expenses" headline is a staff-wages headline; MPs with more caseworkers look worse |
| Payroll timing | 17_18 staffing = 7% vs 77% typical, because the annual payroll row was unpublished | Recent-year rankings are ~75% incomplete and silently so |
| Geography | Top-20 claimers' travel = £16,396 vs £4,712 all-MP mean | Remote-constituency MPs are permanently top of the table |
| Part-year MPs | 833 names in 15_16, 748 in 17_18, against 650 seats | Both extremes of any ranking are populated by turnover, not behaviour |
| Redaction | `[***]` in 11.2% of `details` | Drill-down is holed; absence of detail reads as concealment |
| Security & accessibility costs | Not itemised by IPSA; annual aggregates only | **An MP with high disability-assistance costs may look anomalous and the tool cannot show why** |
| Rejected/repaid claims | `status`, `amount_not_paid`, `amount_repaid`, `reason_if_not_paid` exist in the file | Summing `amount_claimed` attributes to an MP money they never received |
| Negatives | 9,967 rows, −£2,086,373 | Naive handling swings totals either direction |
| Ministerial/leadership roles | Not in IPSA data at all | Party leaders and ministers have structurally different cost profiles |

The last one deserves emphasis: **IPSA's data cannot exonerate.** A high figure with a perfectly good explanation looks identical to a high figure without one, because the exculpatory context (constituency accessibility, a caseworker crisis, a security requirement) is precisely what IPSA withholds.

### 10.4 The responsible-presentation design

If built, these are requirements, not nice-to-haves:

1. **No global raw-total league table. Ever.** Peer-group comparison and percentage-of-budget only.
2. **Ban the vocabulary.** No "outlier", "flagged", "suspicious", "worst", "offender", "abuse", "scandal". Use "above the peer median", "in the top decile of its comparison group".
3. **Never sum `amount_claimed`.** Use `amount_paid`. Show `not paid` and `repaid` alongside every total, with the reason.
4. **Completeness badge on every MP-year**, and **exclude incomplete MP-years from comparison by default** — this is the specific control that would have caught §3.4(a).
5. **Source link on every single figure**, back to IPSA's own record — mpexpenses.org.uk already does this and it is correct practice.
6. **A prominent, unavoidable, plain-English caveat** stating that ~75-80% of costs are staff wages, that variation reflects constituency geography and office size, and that **high spend is not evidence of wrongdoing** — the framing IPSA itself uses ("variation alone does not indicate wrongdoing").
7. **A published methodology page** with the full normalisation crosswalk and known limitations, and a **published corrections policy** with a named contact and a target response time.
8. **Right of reply.** Any MP may submit context that is displayed on their page.
9. **Redact third parties.** No landlord, supplier, agent, staff or family names surfaced from free text.
10. **Version everything.** Every published figure traceable to a commit and an IPSA release date.
11. **Take out media liability insurance before launch.**

Note that mpexpenses.org.uk arrived at a stricter version of this ("no ranking or interpretation") and mpsexpenses.info independently built include/exclude toggles for staffing and travel. **Two of the three incumbents have already concluded that the responsible design and the outlier-finder concept are in tension. That is corroborating evidence for this section's conclusion, not just my opinion.**

---

## 11. Risks & kill criteria

### Risks

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Incumbents already own the category** | **Materialised** | **Severe** | None available — this is the finding, not a risk |
| Auto-published ranking built on an incomplete release defames an MP | High if automated | Severe | Human approval gate; completeness badge; §10.4 |
| Legal letter from an MP or their agent | Moderate | Severe for a solo dev | Insurance; §10.4 design; documented corrections policy |
| Data-subject complaint to the ICO by a named third party | Moderate | High | Never surface third-party names |
| IPSA changes its publication format or moves to an API | Moderate | Medium | Version the ingest; the site is static and degrades gracefully |
| Name-matching drift silently misattributes spend to the wrong MP | High | Severe (a defamation vector in itself) | Hard-fail on unmatched names; never guess |
| Boundary changes break longitudinal comparison | Certain | Medium | Crosswalk; label pre/post-2024 explicitly |
| Maintenance abandonment | High for a solo unfunded project | Medium | `ipsar` is the cautionary tale — 8 years stale |
| Traffic never materialises because SEO is taken | High | High | None |

### Kill criteria — signals that should stop the project

**Pre-commitment gates (all must clear before writing code):**

1. ❌ **Any one of TrustPolitics, mpexpenses.org.uk or mpsexpenses.info is live, current and competent on inspection.** *Current status: search evidence says all three are live with 2024-25 or 2025-26 data. This gate appears already failed and must be checked by actually loading the sites from an unrestricted network.*
2. ❌ **You cannot articulate a feature the incumbents could not copy in one sprint.** Peer-group normalisation probably fails this test.
3. ❌ **You are not willing to pay for media liability insurance.** If so, stop — the project is uninsurable-in-practice for an individual and the downside is unbounded.
4. ❌ **You cannot commit to ~15 days/year indefinitely.** An abandoned expenses site showing stale data about named MPs is worse than no site.

**Post-launch kill signals:**

- Under 2,000 organic sessions/month by month six.
- Zero journalist citations by month twelve.
- Two or more legal or ICO complaints in the first year.
- Any incumbent ships peer-group normalisation.
- IPSA itself ships comparison tooling (it already has an interactive map and a filterable search — this is a plausible roadmap item for them).

### The recommendation, restated

**Do not build the general MP-expenses comparison and outlier-finder tool.** The category is occupied by at least three live products, one of which is a strict superset of the proposed MVP; there is no revenue model; the maintenance burden is real and permanent; and the concept's headline feature is the one that carries genuine legal risk.

**If something is built in this space, build the narrow thing nobody wants to build:** the *cleaned, joined, documented, versioned open dataset* — IPSA claims normalised to canonical categories, bridged to Parliament member IDs and current constituency GSS codes, with completeness flags and the exculpatory fields preserved — published as CSV/Parquet under an open licence, with no rankings, no editorial layer and no consumer front-end. That is genuinely absent (the only prior attempt, `ipsar`, died in 2018), it is the piece every incumbent and every journalist has had to rebuild privately, it carries a fraction of the legal exposure because it makes no characterisations, it is grant-fundable, and it is roughly 12–15 dev-days rather than 25–30. It is infrastructure, not a product — which is an accurate description of what this dataset actually supports.

---

## 12. Open questions

Things I could not verify, in rough order of how much they matter:

1. **Are the three incumbent sites actually good?** I could not load any of them — my egress was restricted to GitHub/PyPI/npm. All my competitive evidence is search-index snippets. **Before any decision, load trustpolitics.com, mpexpenses.org.uk and mpsexpenses.info from an unrestricted network and assess design quality, data freshness, completeness and whether they handle the §10.3 confounders.** If all three turn out to be thin AI-generated SEO shells with no data-quality handling, the verdict could move to BUILD LATER on a quality wedge. **This is the single highest-value follow-up.**
2. **What is the actual current IPSA CSV schema?** I verified a 2010–2018 snapshot (20 native fields). I could not verify 2018–2026. Specifically unknown: whether IPSA now publishes a Parliament member ID; whether the payroll row is still a single year-end line; whether `status`/`reason_if_not_paid` survive; exact file names and sizes.
3. **Exact licence wording on IPSA's downloads.** Reported as OGL by secondary sources. Must be read first-hand, including required attribution and any personal-data conditions.
4. **Does IPSA offer any machine-readable access?** No developer portal or JSON endpoint surfaced. The legacy `parliamentary-standards.org.uk/SearchFunction.aspx` may expose a scrapeable query interface — unverified. If IPSA ships an API, the differentiation collapses further.
5. **Does the annual publication include budget-vs-spend per MP?** This determines whether the killer feature (percentage of budget consumed) can be computed from published data or requires hand-keying budget caps from Scheme PDFs each year.
6. **What is real search demand?** I have no keyword volume data for `mp expenses` or `[MP name] expenses`. Without it, the traffic case is guesswork.
7. **Is Westminster Accounts still maintained?** Built for the 2019–24 parliament, and that parliament has ended. If archived, that is a data point on how these projects age; if renewed, it is a well-resourced competitor moving closer.
8. **Has any UK MP ever taken legal or ICO action against a third-party expenses site?** I found no such case. Absence of evidence here is weak evidence of absence, and I would want a media lawyer's read before publishing rankings.
9. **What is the constitution/funding of TrustPolitics and The People's Ledger?** If these are venture- or party-adjacent, that changes both the competitive and the reputational picture.
10. **Would mySociety collaborate rather than compete?** They hold the strongest UK civic-tech distribution, publish a historic 2001–2009 expenses dataset, and have no IPSA-era expenses product. If the open-dataset recommendation in §11 is pursued, a conversation with them is the first step, not the last.

---

*Prepared 31 July 2026. Primary data analysis performed on `poldham/ipsar` `data/ipsa.rda` (16,612,460 bytes, 1,446,219 rows × 27 columns, 2010-05-07 → 2018-03-31), parsed with pyreadr 0.5.6. IPSA's live site was unreachable from this environment; all statements about current IPSA publications are marked as secondary and require first-hand confirmation.*
