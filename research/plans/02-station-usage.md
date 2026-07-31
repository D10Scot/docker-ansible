# UK Station Usage Explorer — Plan & Decision Document

*Research date: 31 July 2026. Latest ORR release at time of writing: **2024-25, published 4 December 2025**.*

> **Research-environment caveat, stated up front.** `dataportal.orr.gov.uk`, `www.orr.gov.uk`, `data.gov.uk`, `en.wikipedia.org`, `beta-naptan.dft.gov.uk` and all competitor sites are **blocked by this session's egress policy** (the proxy returns `403` to `CONNECT`). I could not open the ORR portal or any competitor page directly.
>
> To compensate I did the verification hands-on against **real mirrored copies of the ORR data hosted on GitHub** (which is reachable), and used web search to confirm publisher-side facts. Everything below is explicitly marked as either:
> - **[VERIFIED-LOCAL]** — I downloaded the file and computed the result myself in this session.
> - **[VERIFIED-SEARCH]** — corroborated across independent search results, but I did not load the page.
> - **[UNVERIFIED]** — inference or assumption. Treat as an open question.
>
> Section 11 lists everything that must be re-checked against the live ORR portal before committing.

---

## 1. Decision summary

**Verdict: BUILD LATER** — specifically, build in **September–October 2026** and launch 1–2 weeks *ahead of* the ORR's next annual release (expected Nov–Dec 2026).

**Confidence: Medium (6/10)** on "this is worth building at all"; **High (8/10)** on "it is not the #2 opportunity the prior assessment claimed".

**Rationale.** The prior assessment's central differentiator — *"no persistent interactive product exists; journalists have only done one-off maps"* — **is factually wrong**, and that is the single most important finding of this review. Merritt Cartographic already publishes a live, persistent, interactive GB rail map whose station symbols are sized by ORR entries-and-exits on a log scale, and the ORR itself ships a Power BI interactive dashboard, an infographic set, *and* a "Britain's Railway in Numbers" station-usage **animation** — i.e. the proposed "killer feature" already exists in the publisher's own channel. Meanwhile the growth animation is precisely the feature the data punishes hardest: I measured artefactual national jumps of **+13.5% (1998-99)** and **+19.7% (2006-07)** that are methodology, not ridership, and ORR removed ~27.5m entries-and-exits from 16 of 25 station groups in the 2024-25 revision alone. An uncritical animation would be actively misleading. What *does* survive scrutiny is genuinely attractive: the entire 25-year, 2,568-station dataset compresses to **249 KB gzipped**, so this is a pure static site at **£0/month** running cost and ~10–13 dev-days. That combination — real annual press hook, near-zero cost, small effort, but crowded and partially pre-empted — makes it a cheap opportunistic build timed to the release cycle, not a flagship. Building it in July gets no press; the entire value of the launch is the December news peg.

---

## 2. The opportunity

**The curiosity served.** "Which is the busiest/quietest station in Britain, and what about *my* station?" This is a genuine, recurring, low-stakes public curiosity with an unusually reliable annual media trigger.

**Evidence the hook is real** [VERIFIED-SEARCH]. The December 2025 release generated coverage across ITV News Central, Lincsonline (Grantham), Nottingham World, West Bridgford Wire, Time Out London, AOL/PA wire, Modern Railways and ianVisits — a mix of national wire, regional press and specialist outlets, all within days of the 4 December 2025 publication. The framing is consistent every year: one "busiest" story (London Liverpool Street, ~98m entries and exits, third year running) and one "ghost station" story (Elton & Orston, Nottinghamshire — 68 entries and exits for the whole year).

**Why the ghost-station angle keeps working.** The winner changes almost every year, which manufactures fresh news annually. From my own computation of the 1997–2021 series [VERIFIED-LOCAL], the least-used station (excluding zero/closed) was:

| Year | Least-used station | Entries & exits |
|---|---|---|
| 2012-13 | Teesside Airport | 8 |
| 2013-14 | Teesside Airport | 8 |
| 2014-15 | Shippea Hill | 22 |
| 2015-16 | Shippea Hill | 12 |
| 2016-17 | Barry Links | 24 |
| 2017-18 | Barry Links | 52 |
| 2018-19 | Stanlow & Thornton | 46 |
| 2019-20 | Berney Arms | 42 |
| 2020-21 | Teesside Airport | 2 |
| 2021-22 | Elton & Orston | 40 |

Press reports [VERIFIED-SEARCH] give Elton & Orston 212 in 2023-24 and 68 in 2024-25. Note the volatility: these are modelled estimates with enormous *relative* error at small counts. That is simultaneously the story's engine and its credibility problem (see §3.6).

**Why now — and why not now.** The honest answer is that "now" is *not* July. The dataset is annual and its attention is almost entirely concentrated in a ~2-week window each Nov/Dec. A launch that misses that window gets essentially no organic pickup and has to wait 12 months. This is the core reason the verdict is BUILD LATER rather than BUILD NOW.

---

## 3. Data deep dive

### 3.1 Access points (URLs recovered via search; **not** loaded in this session)

[VERIFIED-SEARCH] — all under `https://dataportal.orr.gov.uk`:

| Asset | Path | Format |
|---|---|---|
| Landing page | `/statistics/usage/estimates-of-station-usage/` | HTML |
| **Table 1410** — entries, exits & interchanges by station (latest year, full detail) | `/media/1909/table-1410-passenger-entries-and-exits-and-interchanges-by-station.csv` | **CSV** |
| Table 1410 (2023-24 edition) | `/media/smfd4gmg/table-1410-estimates-of-station-usage-2023-24.ods` | ODS |
| Table 1410 (2018-19 edition) | `/media/1667/table-1410-estimates-of-station-usage-2018-19.ods` | ODS |
| Estimates of station usage 2019-20 | `/media/2023/estimates-of-station-usage-2019-20.ods` | ODS |
| **Table 1415** — **time series**, Apr 1997–Mar 1998 through Apr 2024–Mar 2025 | (on landing page) | **ODS** |
| **Table 6329** — station attributes, incl. **Easting/Northing** | `/media/ootlf0cn/table-6329-station-attributes-for-all-mainline-stations.ods` | ODS |
| Quality & methodology report | `/media/1917/station-usage-quality-and-methodology-report.pdf` | PDF |
| **Historical methodological changes** (Steer, Nov 2025) | `/media/1903/station-usage-and-origin-destination-matrix-steer-historical-methodological-changes.pdf` | PDF |
| FAQs (2024-25) | `/media/1216/station-usage-faqs.pdf` | PDF |
| 2024-25 statistical release | `/media/msigcn24/station-usage-2024-25-statistical-release.pdf` | PDF |

Two things matter here for engineering:

1. **Table 1415 is the whole product's backbone.** One ODS file carries **28 financial years** (1997-98 → 2024-25) for every station. You do not need to scrape 28 separate files. [VERIFIED-SEARCH]
2. **URL slugs are unstable.** Compare `/media/1667/...` and `/media/2023/...` (numeric) against `/media/smfd4gmg/...` and `/media/ootlf0cn/...` (random tokens). ORR appears to have migrated CMS at some point. **Do not hardcode download URLs** — scrape the landing page for links each year. This is a real, concrete maintenance risk.

**Licence.** ORR statistics are Crown copyright published under the **Open Government Licence**, permitting commercial reuse with attribution [VERIFIED-SEARCH — the OGL terms are confirmed; I could not load ORR's own licence statement page, so confirm the exact OGL version ORR asserts before launch].

### 3.2 Schema — actually observed

I downloaded a genuine ORR Table 1410 extract for **2012-13** from `theodi/orpi-corpus` [VERIFIED-LOCAL]:

- **File size: 623,554 bytes**
- **2,536 data rows** (one per station) + header
- **28 columns**

Exact column names as observed:

```
NLC, Origin TLC, Station Name, Government Office Region (GOR),
County or Unitary Authority, District or Unitary Authority,
NUTS2 Spatial_Unit Code, NUTS2 Spatial Unit, Station Facility Owner,
Station Group, PTE Urban Area Station, London Travelcard Area,
Entries Full, Entries Reduced, Entries Season, Entries Total,
Exits Full, Exits Reduced, Exits Season, Exits Total,
1213 Entries & Exits, "1112 \nEntries & Exits", Interchanges,
Large station Flag, Small Station Flag, Explanation of large change,
Sources, <trailing unnamed empty column>
```

**Parsing gotchas I hit personally** — every one of these will break a naive `pandas.read_csv`:

- **Line endings are bare `CR` (old-Mac style)**, not `LF` or `CRLF`. Measured: 2,537 `\r`, zero `\n`. `head -1` returns the entire file.
- **Numbers are text with thousands separators and padding**: the value for Abbey Wood entries is literally `" 282,907 "`. Must strip and de-comma.
- **Empty interchanges are `"  "` (two spaces), not empty string** — a naive integer cast fails rather than yielding null.
- **A header contains an embedded newline**: `1112 \nEntries & Exits`.
- **Year-specific column names**: `1213 Entries & Exits` / `1112 Entries & Exits` encode the financial year *in the column name*, so they change every single edition. Never key on these.
- One row has a **blank `Origin TLC`**, and there is a **trailing unnamed column**.

**Stable keys:** `NLC` (National Location Code) and `Origin TLC` (the three-letter CRS code). Everything else is either presentational or year-dependent.

### 3.3 Volumes and history depth

I obtained a full multi-year ORR-derived dataset from `lvalnegri/RstationsusageUK` (an R package built directly from ORR Tables 1410 and 1415) [VERIFIED-LOCAL]:

| File | Bytes | Rows | Shape |
|---|---|---|---|
| `stations.csv` | 415,486 | 2,568 + hdr | 17 columns, station reference |
| `dataset.csv` | 6,894,027 | 286,802 | long format: `NLC, year, metric, value` |
| `stations_usage.xlsx` | 3,720,663 | — | source workbook |

`dataset.csv` covers **25 financial years, 1997-98 → 2021-22** (labelled by start year), with metrics `Total` (62,735 rows), `Rank` (62,735), `Changes`/interchanges (62,735), `VarYoY` (60,161), and `Full`/`Reduced`/`Season` (12,812 each — **ticket-type splits are only present for recent years**, an important limitation for any "season-ticket collapse post-COVID" story).

**History completeness** [VERIFIED-LOCAL]: **2,447 of 2,568 stations (95.3%) have all 25 years**; 121 are partial (new openings). Distribution of history length is heavily bimodal — a long tail of 2–24-year stations, then a spike of 2,447 at the full 25.

**Bottom line on volume: this dataset is tiny.** Roughly 2,570 stations × 28 years. That single fact drives the whole technical plan (§6).

### 3.4 The coordinate-join problem — solved, with one important caveat

ORR's Table 1410 carries **no coordinates** — only names, NLC, TLC and administrative geography. Three candidate join routes, tested:

**Route A — ORR's own Table 6329 (recommended).** [VERIFIED-SEARCH] "Station attributes for all mainline stations in Great Britain" provides **Easting/Northing** (British National Grid, EPSG:27700), county, constituency and station facility owner, current as at **31 March 2025**, as an ODS download from the same portal under the same OGL licence. This is the cleanest option: same publisher, same licence, no attribution complications. *Caveat: I could not confirm whether 6329 keys on NLC, CRS, or both — see §11.*

**Route B — NaPTAN `RailReferences.csv` (OGL).** [VERIFIED-SEARCH] Fields `ATCO, TIPLOC, CRS, NAME, StationNameLang, GridType, Easting, Northing, Creation, Modification`. OGL-licensed, DfT-maintained, updated frequently. Good fallback / cross-check.

**Route C — `davwheat/uk-railway-stations` (works, but licence-encumbered).** [VERIFIED-LOCAL] I downloaded `stations.json`: **2,608 stations, 285,418 bytes**, fields `stationName, lat, long, crsCode, constituentCountry` (+ `iataAirportCode` on 14). **100% coverage of both `crsCode` and lat/long.** Practical and immediately usable — **but it is ODbL** (derived from Trainline EU), which imposes share-alike obligations on a derived database. Avoid for a commercial build; Routes A/B are OGL and cleaner.

**I tested both join keys against real ORR data** [VERIFIED-LOCAL]:

| Join key | Result |
|---|---|
| **`NLC`** → `RstationsusageUK` station reference | **2,531 / 2,535 = 99.84%** |
| `Origin TLC` (CRS) → `davwheat` | 2,522 / 2,535; **13 unmatched** |
| Station **name** | **154 of ~2,522 matched pairs have differing names (~6%)** |

**Conclusion 1: join on NLC, not CRS, and never on name.** The 154 name mismatches include `Ashford (Middlesex)`/`Ashford Surrey`, `Bedford Midland`/`Bedford`, `Blackfriars`/`London Blackfriars`, `Bicester Town`/`Bicester Village`, `Bury St.Edmunds`/`Bury St Edmunds`, `Brookman's Park`/`Brookmans Park`. Fuzzy name matching at ~6% error across 2,500 stations is not acceptable for a product whose entire premise is per-station accuracy.

**Conclusion 2 — the real catch: CRS codes are not stable over time, and current reference data omits closed stations.** The 13 CRS misses split into two groups:
- **Recoded stations**: Anerley `ANY`→`ANZ`, plus `FAR` (Farringdon), `CAW` (Canada Water), `WCA` (Whitechapel), `LSP` (Liverpool South Parkway), `FAM` (Fambridge), `WDF` (Woodham Ferrers), `SMC` (Sampford Courtenay), `LON` (London Road Guildford).
- **Closed stations**: Angel Road, British Steel Redcar, IBM, Butlins Penychain.

The 4 NLC-join misses were *all* closed stations (Angel Road, British Steel Redcar, IBM, Sampford Courtenay). **This is the key structural point for a historic explorer: any coordinate source that reflects the network *today* — Table 6329 as at 31 March 2025, NaPTAN, davwheat — will silently drop stations that existed earlier in the time series.** For a product whose selling point is 28 years of history, losing exactly the stations that closed (which are inherently the most interesting "ghost station" stories) is a real defect. Budget for a small hand-maintained supplementary coordinate file for historic-only stations. This is a genuine, unglamorous piece of work the prior "trivial data" assessment did not anticipate.

### 3.5 Cadence

Annual, one release per financial year, published roughly Nov–Jan. Recent editions: 2023-24 on **21 November 2024**; 2024-25 on **4 December 2025** [VERIFIED-SEARCH]. Expect 2025-26 around **Nov–Dec 2026**. There is no intra-year update and no API — download-only.

### 3.6 Comparability — the feature-killer, quantified

This is where the "historic growth animation" concept meets reality. **ORR states plainly that estimates are not always comparable over time** [VERIFIED-SEARCH], and maintains a dedicated Steer report, *Station Usage & Origin Destination Matrix: Historical Methodological Changes* (November 2025), for exactly this reason.

**The 2024-25 revision alone**: 16 of the 25 station groups were adjusted; approximately **27.5 million entries and exits (~13.7m journeys) were removed**, concentrated on **Glasgow (~8m)**, **Edinburgh (~3.5m)** and **Haymarket (~1m)** [VERIFIED-SEARCH]. A viewer watching a naive animation would see Glasgow appear to lose 8 million passengers in one year. It did not.

**I then measured the discontinuities myself** [VERIFIED-LOCAL]. National entries-and-exits by financial year, from the 1997–2021 series:

| FY | Stations | National E&E | YoY |
|---|---|---|---|
| 1997-98 | 2,447 | 1,229,905,499 | — |
| **1998-99** | 2,452 | 1,396,310,622 | **+13.5%** |
| 1999-00 | 2,453 | 1,443,494,541 | +3.4% |
| 2000-01 | 2,462 | 1,455,141,119 | +0.8% |
| 2001-02 | 2,463 | 1,464,537,980 | +0.6% |
| 2002-03 | 2,465 | 1,499,297,204 | +2.4% |
| 2003-04 | 2,470 | 1,526,118,677 | +1.8% |
| 2004-05 | 2,470 | 1,552,434,987 | +1.7% |
| 2005-06 | 2,475 | 1,590,593,400 | +2.5% |
| **2006-07** | 2,493 | 1,903,389,843 | **+19.7%** |
| 2007-08 | 2,500 | 2,037,445,380 | +7.0% |
| 2008-09 | 2,506 | 2,145,789,104 | +5.3% |
| 2009-10 | 2,512 | 2,129,628,275 | −0.8% |
| 2010-11 | 2,526 | 2,313,347,459 | +8.6% |
| 2011-12 | 2,529 | 2,455,763,193 | +6.2% |
| 2012-13 | 2,531 | 2,537,772,406 | +3.3% |
| 2013-14 | 2,533 | 2,664,967,077 | +5.0% |
| 2014-15 | 2,535 | 2,784,935,688 | +4.5% |
| 2015-16 | 2,549 | 2,927,503,760 | +5.1% |
| 2016-17 | 2,552 | 2,939,311,119 | +0.4% |
| 2017-18 | 2,555 | 2,952,197,143 | +0.4% |
| 2018-19 | 2,557 | 3,039,400,034 | +3.0% |
| 2019-20 | 2,564 | 3,007,136,872 | −1.1% |
| **2020-21** | 2,568 | 687,732,800 | **−77.1%** (COVID — genuine) |
| **2021-22** | 2,568 | 1,788,478,136 | **+160.1%** (rebound — genuine) |

Against a baseline of ~0.4–5% in ordinary years, **1998-99 (+13.5%) and 2006-07 (+19.7%) are not credible as organic growth.**

I tested whether the 2006-07 jump was broad or concentrated, by computing the per-station ratio distribution for stations above 1,000 E&E:

| Transition | n | Median ratio | p10 | p90 |
|---|---|---|---|---|
| 1997→1998 | 2,363 | 1.054 | 0.930 | 1.289 |
| 2005→2006 | 2,400 | **1.071** | 0.930 | **1.451** |
| 2019→2020 | 2,509 | 0.225 | 0.125 | 0.357 |

The **national** jump in 2006-07 (+19.7%) is far larger than the **median station** jump (+7.1%), with a fat upper tail (p90 = 1.451). That signature — broad-based uplift plus disproportionate gains at large stations — is the fingerprint of a methodology/allocation change concentrated on grouped and major stations, not of passengers appearing. (Contrast 2019→2020, where the median ratio of 0.225 is a genuine, uniform COVID collapse.)

**Product implication.** A "watch Britain's stations grow since 1997" animation is, as specified, an artefact-generator. It must either (a) start at 2010-11 or later, sacrificing the headline "28 years"; or (b) render the known break years as explicit visual discontinuities with inline annotation. Option (b) is more honest, more interesting, and is genuinely differentiating — nobody else does it — but it converts the feature from "pretty animation" into "explainer", which is a different product with a different (smaller, more serious) audience.

### 3.7 Estimate quality at the low end

The "ghost station" headline rests on the weakest part of the dataset. Britain's network is not fully gated, so ORR explicitly states that complete recording of passenger flows is impossible and the figures are **modelled estimates** derived from the Origin-Destination Matrix (from MOIRA2.2, itself derived from LENNON ticketing/revenue data) [VERIFIED-SEARCH]. ORR further warns that figures for stations inside Travelcard zones and within station groups are allocated on **modelled assumptions**, and that group allocations are validated by occasional manual counts (most recently Spring 2025).

My own numbers show what this means in practice [VERIFIED-LOCAL]: Elton & Orston ran 164 → 68 → 12 → 40 across 2018-19 to 2021-22. Teesside Airport: 8, 8, …, 2. These are single- and double-digit counts produced by a national revenue model. **Any responsible product must present them with an uncertainty treatment**, not as a precise scoreboard. That constraint is in direct tension with the viral hook, which depends on the spurious precision of "exactly 68 passengers".

### 3.8 Supplementary data worth adding

| Dataset | Value | Access | Status |
|---|---|---|---|
| **ORR Table 6329** — station attributes | Coordinates, county, constituency, facility owner. Primary geo source. | ORR portal, ODS, OGL | [VERIFIED-SEARCH] |
| **ORR methodology + Steer historical-changes reports** | Essential for the comparability annotations in §3.6. Turns a weakness into the differentiator. | ORR portal, PDF | [VERIFIED-SEARCH] |
| **National Rail Knowledgebase — Stations feed** | Facilities for 2,500+ stations: staffing, ticket office, CCTV, accessibility, car/cycle parking. XML, plus a JSON variant with enhanced accessibility data. | **Registration** via Rail Data Marketplace | [VERIFIED-SEARCH] — licence terms unverified |
| **ODM (Origin-Destination Matrix)** | Station-to-station passenger flows — *the* underlying data behind these estimates. Reported as now **freely available on the Rail Data Marketplace**. Would enable "where do people actually travel from your station", which **nothing consumer-facing currently does**. | Rail Data Marketplace, registration | [VERIFIED-SEARCH] — strongest future differentiator; unverified |
| **NaPTAN RailReferences** | OGL coordinate cross-check; TIPLOC↔CRS↔ATCO crosswalk. | DfT NaPTAN portal | [VERIFIED-SEARCH] |
| Service frequency | "Usage per train" is a genuinely novel metric. Requires timetable data (Network Rail SCHEDULE / RDM) — significantly heavier lift. | RDM, registration | [UNVERIFIED] — out of MVP scope |
| Population / IMD by LSOA | Enables "usage vs catchment population" — the fair way to identify genuinely under-used stations. | ONS, OGL | [UNVERIFIED] |

---

## 4. Competitive landscape

All entries below were confirmed to **exist and be indexed** via search; I could not load pages to confirm current uptime or interactivity depth. Flagged accordingly.

### 4.1 The incumbent the prior assessment missed

**Merritt Cartographic — *British Railways: An interactive map of Great Britain's rail network*** (`merrittcartographic.co.uk/british_railways.html`). [VERIFIED-SEARCH] Interactive map of the GB network where **station symbols are sized proportionally to total entries and exits for 2023-24 on a logarithmic scale**, with routes coloured by the operating TOC, and station usage explicitly sourced from ORR. There is also a companion *London Railways* map.

This is, essentially, the product the prior assessment said did not exist. It directly refutes *"no dedicated interactive, ongoing consumer app was found"* and *"nobody has built the persistent explorer"*.

**Its weaknesses (i.e. the surviving gap):** it is a **single-year snapshot** — still on 2023-24 while 2024-25 has been out since December 2025, indicating slow or lapsed maintenance; it appears to be a cartographic showcase for a mapping consultancy rather than a maintained consumer product; it offers no time series, no rankings/leaderboards, no per-station permalink pages, and therefore no SEO surface.

### 4.2 The publisher itself — the strongest incumbent

**ORR Data Portal.** [VERIFIED-SEARCH] Alongside the raw tables, ORR publishes:
- an **interactive Power BI dashboard**;
- **animated charts (MP4)** and **infographics (PDF)** covering top 10 most-used stations in GB, top 5 in Scotland and Wales, top 5 per region, top 10 busiest flows, and **least-used stations**;
- a *"Britain's Railway in Numbers — station usage animation"* (`orr.gov.uk/media/23028`).

**This materially undercuts the proposed killer feature.** The historic growth animation is not an unoccupied gap — the publisher already ships one, and press outlets embed ORR's own graphics.

**Its weaknesses:** Power BI embeds are typically slow, poor on mobile, effectively invisible to search engines, and produce no shareable per-station URLs. ORR is a regulator producing statistical outputs, not optimising for consumer engagement or long-tail search. That is the entire remaining wedge.

### 4.3 Other verified-live players

| Player | What it is | Threat |
|---|---|---|
| **Wikipedia** — *List of busiest railway stations in Great Britain (per year)*, *List of least used railway stations of Great Britain* | Per-year articles plus a dedicated least-used list; individual station articles carry usage tables | **High for SEO.** Wikipedia will outrank a new site on almost every "busiest/least used station" head term, and on many per-station queries. Static tables, no map, sometimes stale — but dominant. |
| **Welsh Government** — *Rail station usage: interactive dashboard* (gov.wales) | Official interactive dashboard comparing station usage by line/route | Wales only; narrows the addressable territory |
| **DfT** — *Rail passengers and crowding interactive dashboard* (maps.dft.gov.uk) | Official interactive; crowding rather than station usage | Adjacent, government-backed |
| **Rail Insights** (rail-insights.co.uk) | Commercial station-usage dashboard deriving typical weekday/Saturday/Sunday demand patterns | Commercial/professional segment already served |
| **DataWharf — GB Rail Stations API** | Commercial API bundling station location, assets, facilities, staffing, parking, **usage** | Occupies the "developer wants this joined dataset" niche |
| **Baseview.uk** — UK National Rail Stations Directory | Searchable directory by name/code/postcode/operator/LA district; **updated 31 Jan 2026** — actively maintained | Owns the per-station-page SEO surface, though without usage-history depth |
| **TrainMap.co.uk** | Live-train interactive map, station/postcode search, heritage lines, closed stations | Adjacent (live ops, not usage) but strong on interactive rail mapping |
| **Brilliant Maps** | One-off articles: busiest UK rail stations; 196 years of GB rail | One-off journalism, as the prior assessment said — but it is *not* the only thing out there |
| **On Time Trains blog** | Annual analysis articles on each ORR release | Enthusiast commentary, not a tool |

### 4.4 The wedge, honestly stated

The prior assessment's wedge ("nobody has built a persistent interactive explorer") **does not survive contact with the evidence**. A narrower wedge does survive:

> **Nobody combines (a) the full 28-year time series, (b) an interactive map, (c) per-station permalink pages, and (d) honest treatment of the methodology breaks — in one fast, mobile-friendly, search-indexable site.**

Each incumbent has some of these; none has all four. Merritt has (b) for one year. ORR has an animation and a dashboard but no (c) and no SEO. Wikipedia has fragments of (a) and (c) but no (b) and no (d). Rail Insights and DataWharf are commercial/professional and paywalled or developer-facing.

That is a real gap — but it is a **quality and packaging** gap, not a **existence** gap. Quality gaps are far harder to convert into traffic than the prior assessment assumed, because the incumbents already absorb the search demand.

---

## 5. Product definition

**Target user (in priority order):**
1. **The casually curious reader arriving from a news story** in Dec — highest volume, lowest intent, ~2-week window.
2. **Railway enthusiasts** — lowest volume, highest engagement, the people who will find errors and share the site.
3. **Local/regional journalists** — small in number but disproportionately valuable: they need "the least-used station *in our county*", which is exactly the query the ORR dashboard answers badly.
4. **Transport planners / campaigners** (community rail groups, reopening campaigns) — need station-level trend evidence; small but genuinely underserved.

Explicitly **not** targeted: commuters. Annual historic ridership estimates answer no question a commuter has.

### MVP — in scope

- **Map of all ~2,570 GB stations**, symbol size ∝ entries+exits (log scale), colour-coded by growth/decline, with a year slider (1997-98 → latest).
- **Per-station permalink pages** (`/station/elton-and-orston`) — 28-year chart, national rank history, entries/exits/interchanges, facility owner, nearest neighbours for comparison, and a plain-English uncertainty note. **~2,570 statically generated pages: the entire SEO surface.**
- **Leaderboards**: busiest, quietest, fastest-growing, fastest-shrinking — filterable **by nation, region and county** (the journalist feature).
- **Search** by station name, CRS code and postcode proximity.
- **A methodology/caveats page** that actually explains the 2006-07 break, station-group allocation, and why small-station numbers wobble. This is the credibility anchor and a differentiator.
- **Break-year annotation** rendered inline on every chart and in the animation timeline.
- Static, no login, no analytics beyond privacy-preserving counts.

### MVP — explicitly out of scope

- Live departures / real-time anything (Darwin's territory; total incumbent lock).
- Journey planning, fares, ticket purchase.
- Origin-destination flow maps (**v2 candidate**, pending Rail Data Marketplace licence verification — see §11).
- Station facilities detail (v2 — requires RDM registration).
- Usage-per-train-service metrics (needs timetable data).
- Northern Ireland (ORR data is **Great Britain** only — do not mislabel it "UK").
- User accounts, saved stations, notifications, mobile apps.
- Anything requiring a database or a server.

### The single "killer" feature

**Not** the growth animation — ORR already publishes one and the data undermines it.

**The killer feature is the honest, comparability-aware per-station history page**: for any of ~2,570 stations, a permanent URL showing 28 years of usage with methodology breaks marked, rank trajectory, and neighbour comparison. It is the artefact Wikipedia approximates badly, ORR's Power BI cannot produce, and Merritt's map does not attempt. It is also the only feature that generates a durable, indexable long-tail (`"<station name> passenger numbers"`) rather than a single annual spike.

The animation ships as a supporting feature — with the break years visibly annotated, which is itself the story.

---

## 6. Technical plan

### Architecture: fully static. No backend. No database.

This is not a stylistic preference — it follows from a measured fact. **I serialised the complete 25-year × 2,568-station dataset into a single JSON payload: 517.4 KB raw, 249.0 KB gzipped** [VERIFIED-LOCAL]. Adding three more years takes it to roughly 280 KB gzipped. **The entire dataset is smaller than a typical hero image and can be shipped to the browser in one request.**

Consequences:
- No API, no query layer, no caching tier, no scaling concerns.
- All filtering, ranking and animation happens client-side, instantly.
- The site cannot go down for data reasons and has no attack surface worth the name.

### Stack

| Layer | Choice | Why |
|---|---|---|
| Pipeline | **Python** (`pandas` + `odfpy`/`ezodf` for ODS, `pyproj` for EPSG:27700→4326) | ODS is the format most ORR tables ship in; `pyproj` handles the Easting/Northing conversion Table 6329 requires |
| Site generation | **Astro** (or SvelteKit static adapter) | Ships near-zero JS by default; trivially generates ~2,570 static station pages; good Core Web Vitals, which matters for the SEO play |
| Map | **MapLibre GL JS** + free vector tiles (Protomaps/OpenFreeMap), or a hand-rolled SVG/canvas GB map | Avoids Mapbox billing entirely. Given only ~2,570 points, a custom canvas layer is viable and would be faster than a full tile stack |
| Charts | Hand-rolled SVG or `uPlot` | 28 points per chart — a charting library is overkill |
| Hosting | **Cloudflare Pages** (or Netlify/GitHub Pages) free tier | Static assets, global CDN, free bandwidth |
| CI | GitHub Actions, annual cron + manual trigger | Rebuild when ORR publishes |

### Pipeline

1. **Scrape the ORR landing page for download links** (do *not* hardcode: URL slugs demonstrably change between numeric IDs and random tokens — §3.1).
2. Fetch **Table 1415** (time series) and **Table 6329** (attributes/coordinates).
3. Normalise: strip thousands separators and padding; coerce `"  "` → null; handle **bare-CR line endings**; drop the trailing unnamed column; ignore year-encoded column names.
4. **Join on `NLC`** (99.84% measured), then patch closed/historic stations from a hand-maintained supplementary coordinates file.
5. Convert Easting/Northing (EPSG:27700) → WGS84.
6. Apply the **methodology-break annotation table** (hand-curated from the Steer historical-changes report) — this is a data asset, not code.
7. Emit `stations.json` (~250–280 KB gz) + per-station page data.
8. Validate: row count within expected bounds, no unjoined stations, no negative or absurd YoY without a break annotation. **Fail the build loudly** — a silent schema change is the main operational risk.

### Running cost

| Item | £/month |
|---|---|
| Hosting (Cloudflare Pages free tier) | **£0** |
| Bandwidth | **£0** (250 KB payload; even 500k annual sessions is ~125 GB, within free allowances) |
| Domain | ~**£1** (£10–15/yr amortised) |
| Map tiles | **£0** (self-hosted Protomaps basemap, or custom canvas) |
| CI | **£0** (GitHub Actions free tier) |
| **Total** | **~£1/month** |

**Static generation is not merely sufficient — it is clearly correct.** Annual data, a 250 KB corpus and ~2,570 pages is the textbook static-site case. Any proposal involving a database here should be rejected.

---

## 7. Effort & timeline

For **one competent developer** already comfortable with Python and a modern JS framework:

| Phase | Days |
|---|---|
| Pipeline: ODS parsing, cleaning, NLC join, coordinate conversion, validation | 2.5 |
| Historic/closed-station coordinate reconciliation (manual research on ~50–120 stations) | 1.5 |
| Methodology-break annotation table (reading Steer + ORR reports, curating break years and affected stations) | 1.0 |
| Map UI: symbols, year slider, animation, growth colouring | 3.0 |
| Station pages + charts + static generation for ~2,570 routes | 2.0 |
| Leaderboards, search, region/county filters | 1.5 |
| Methodology page, copy, about, attribution | 1.0 |
| SEO: metadata, sitemap, structured data, OG images | 1.0 |
| Polish, mobile, accessibility, cross-browser | 1.5 |
| **Total MVP** | **~15 dev-days** |

That is above the ~10-day figure a naive read of "trivial clean data" would suggest, and the overrun sits almost entirely in the two items the prior assessment did not anticipate: **historic-station coordinate reconciliation** and **methodology-break curation**. A version that skips both could ship in ~9 days — but it would be indistinguishable from the incumbents and would publish misleading trends.

**Ongoing maintenance: ~1–2 days per year.**
- ~0.5 day to re-run and sanity-check the annual release.
- ~0.5–1 day contingency for ORR changing file format, column names or URL structure (they have migrated CMS at least once — §3.1).
- Any new methodology break requires re-curating the annotation table.

Maintenance burden is genuinely low. The risk is not effort but **abandonment**: a site that needs attention once a year is a site that gets forgotten, and a stale station-usage site is worse than none. Merritt Cartographic sitting on 2023-24 data eight months after 2024-25 shipped is the cautionary example.

---

## 8. Distribution

### SEO

The head terms are effectively conceded to Wikipedia and ORR. **The realistic play is long-tail per-station queries**, which is exactly what ~2,570 static pages address:

- **Head (hard, likely lost):** "busiest railway station UK", "least used railway station UK", "quietest train station Britain"
- **Mid (contestable):** "least used station in [county/region]", "busiest station outside London", "busiest station in Scotland/Wales", "station usage statistics 2025-26"
- **Long tail (winnable, and the actual strategy):** "[station name] passenger numbers", "[station name] station usage", "how many people use [station]", "is [station] busy"

Publish before the ORR release so pages are indexed when journalists start searching.

### Press / viral hooks

The proven annual formula [VERIFIED-SEARCH]:
1. **"Britain's quietest station"** — the reliable engine. Elton & Orston (68 in 2024-25) drew ITV News Central plus regional press within days.
2. **"The busiest station"** — London Liverpool Street, ~98m, third year running.
3. **Regional cuts** — "the least-used station in [county]" is the highest-yield angle because it is *reproducible 40+ times* across regional outlets, and it is the query ORR's own dashboard serves worst. **This is the distribution wedge.**
4. **Elizabeth line disruption** — its stations now dominate the top 10; a genuine structural story with a clear before/after.
5. **"Stations that never recovered from COVID"** — computable directly from the series.
6. **A contrarian angle nobody has taken**: *"the 'quietest station' statistic is a modelled estimate that swings 5× year-to-year"*. Well-evidenced by my own analysis (§3.7), differentiating, and the sort of thing that earns links from data-journalism and statistics communities.

### Communities to seed in

- **RailUK Forums** (railforums.co.uk) — the largest UK railway discussion community [VERIFIED-SEARCH]; there is already an active thread on the 2024/25 release. Highest-value single seeding target. Post as a contributor, not a marketer.
- **r/uktrains, r/trains, r/transit, r/dataisbeautiful, r/CasualUK** — sizes **[UNVERIFIED]**, I could not load Reddit. Verify before planning around them.
- **Hacker News / Show HN** — plausible for the technical angle ("28 years of GB rail usage in a 250 KB static site"), unreliable as a channel.
- **On Time Trains blog, ianVisits, Modern Railways, RailBusinessDaily** — outlets that already cover each release annually and might link.
- **Community Rail Network** and station-reopening campaign groups — natural users of the trend data.
- Local Facebook groups for the named ghost stations — where the regional-press angle originates.

---

## 9. Sustainability

Assessed bluntly: **there is no realistic revenue model here, and the plan should not pretend otherwise.**

| Option | Realistic assessment |
|---|---|
| **Display advertising** | Traffic is one annual spike decaying to near-zero. Even a very good year might be tens of thousands of sessions. At UK display rates this is single- to low-double-digit pounds annually. **Not worth the page-weight or the consent-banner damage to the SEO play.** |
| **Affiliate (rail tickets)** | Superficially tempting, but the audience is historic-curiosity traffic, not people about to book. Conversion would be near-zero, and it would compromise editorial credibility. **Reject.** |
| **Data/API licensing** | The underlying data is OGL and free; DataWharf already sells a joined product. Nothing to sell. |
| **Consultancy lead-gen** | Plausible *if* the builder sells data-visualisation or transport-analytics services — this is essentially Merritt Cartographic's model (a cartography firm using the map as a showcase). **The only coherent commercial rationale, and it requires an existing business to attach to.** |
| **Donations / Ko-fi** | Might cover the domain. Not a plan. |
| **Cost recovery** | The genuinely good news: **at ~£1/month, there is nothing meaningful to recover.** |

**Conclusion.** Treat this as a **portfolio/credibility asset or a public-good side project**, funded by its own triviality. The correct framing is: it costs ~£12/year and ~1 day/year to keep alive, so it does not need to earn anything — but it should never be assigned a budget or an opportunity-cost-bearing timeline on the expectation of return. If it must pay for itself, do not build it.

---

## 10. Risks & kill criteria

### Risks

| Risk | Severity | Notes |
|---|---|---|
| **The differentiation is weaker than assumed** | **High** | Already partly materialised: Merritt Cartographic and ORR's own dashboard/animation occupy much of the claimed gap. The wedge is quality/packaging, which converts to traffic poorly. |
| **Wikipedia owns the search demand** | **High** | Wikipedia's per-year and least-used lists, plus per-station articles with usage tables, will outrank a new site on most head and many long-tail terms. |
| **Methodology breaks make the flagship feature misleading** | **High** | Quantified in §3.6. Mitigable with annotation, but mitigation costs ~1 dev-day/year and constrains the design. |
| **Small-station estimates are too noisy to headline** | Medium | §3.7. The viral hook depends on precision the data does not have. A rival could credibly attack the site's accuracy. |
| **Missing coordinates for closed/historic stations** | Medium | §3.4. Current reference data omits exactly the most story-worthy stations. Manual work required. |
| **ORR changes file format / URLs** | Medium | Evidenced CMS migration; slug patterns already inconsistent. Pipeline must scrape, not hardcode, and fail loudly. |
| **Launch-window miss** | Medium | Almost all attention is a ~2-week December window. Missing it costs a year. |
| **Abandonment** | Medium | Annual-cadence sites rot. A stale site actively damages credibility. |
| **Egress-blocked verification** | Medium | I could not open the ORR portal. Several file-level facts (§11) remain unconfirmed. |
| **Zero revenue** | Low | Only a risk if anyone expects revenue. Costs are ~£1/month. |

### Kill criteria

**Before building:**
- **Kill if** loading Merritt Cartographic (and any newer entrant) shows it already offers a time series, station pages, or regional leaderboards. The remaining gap would be too thin.
- **Kill if** ORR's Power BI dashboard turns out to already provide per-station history with shareable URLs and decent mobile performance.
- **Kill if** Table 1415 proves not to be a genuine consistent series (e.g. it is a stitched set of un-restated annual snapshots with no reconciliation) — this would push effort well past 20 days.
- **Kill if** the historic-station coordinate reconciliation exceeds ~3 days of manual work.

**After launch:**
- **Kill (stop maintaining) if** the first December launch, with regional-press outreach actually attempted, yields no press pickup and negligible search impressions. The entire thesis rests on the annual news peg; without it there is no audience.
- **Kill if** by the second year organic long-tail traffic outside the December window has not grown. That would prove it is a one-off data story, not a product — and one-off data stories do not justify indefinite maintenance.
- **Kill if** ORR ships its own modern interactive station explorer with per-station pages. The regulator can end this at any time and would immediately be authoritative.

### Is it a product or a one-off data story?

**Honestly: it is a one-off data story with a thin, indefinite tail.** Annual data cannot support repeat visits — there is nothing to come back for until next December.

The only credible route to staying power is to stop treating it as a station-usage site and treat it as a **rail data reference** — accreting adjacent open datasets (facilities, accessibility, ODM flows, service frequency, catchment population) around the same ~2,570 station pages, so each page answers many questions rather than one. That is a materially bigger project than the MVP described here and should be a **deliberate v2 decision made only if the MVP earns traffic** — not assumed at the outset.

---

## 11. Open questions

**Must be resolved before committing** (mostly consequences of the egress block — every one is answerable in under an hour with normal internet access):

1. **Table 1415's actual structure.** Is it one wide sheet (station × 28 year-columns), or multiple sheets? Are historic years **restated** onto the current methodology, or preserved as originally published? *This single answer determines whether §3.6's break-annotation work is necessary or redundant, and moves the estimate by several days.*
2. **Exact file sizes and formats** of Tables 1410, 1415 and 6329 as currently published. I verified a 623 KB CSV for 2012-13 and a 3.7 MB derived XLSX for 25 years, but not the live ORR files.
3. **Table 6329's join key** — does it carry `NLC`, `CRS`, or both? My 99.84% NLC join was against a third-party reference, not 6329 itself. If 6329 is CRS-only, the join degrades to the ~13-miss CRS path.
4. **Does Table 6329 include closed/historic stations**, or only those live at 31 March 2025? Almost certainly the latter — which is the §3.4 problem. Quantify how many historic stations need manual coordinates.
5. **ORR's precise licence assertion** — OGL version, and required attribution wording.
6. **Merritt Cartographic's actual feature set.** Does it have a year slider or station pages? If yes, the wedge narrows sharply — this is a kill criterion.
7. **ORR's Power BI dashboard capabilities** — per-station drill-down? Shareable URLs? Mobile performance? Determines how much of the wedge the publisher already occupies.
8. **The ODM on Rail Data Marketplace** — is it genuinely free and openly licensed, at what granularity, and does its licence permit public republication? Potentially the strongest v2 differentiator, entirely unverified.
9. **National Rail Knowledgebase licence terms** for facilities data — registration is confirmed, redistribution rights are not.
10. **Community sizes** — r/uktrains, r/trains, RailUK Forums membership and activity. I could not load any of them; §8's seeding plan is currently unquantified.
11. **Whether ORR's own animation is interactive or a rendered MP4.** Search indicates MP4. If ORR has shipped something interactive, the animation feature is fully pre-empted.
12. **Precise historic break years.** I identified 1998-99 and 2006-07 empirically from the national series; the Steer *Historical Methodological Changes* report should be read in full to build an authoritative break table, including station-level (not just national) breaks.
13. **Actual search volume** for the target long-tail terms (`"[station] passenger numbers"`). The entire SEO thesis is untested — no keyword tool was reachable from this session.

---

## Appendix — what I actually ran

Reproducible steps performed in this session, all against reachable mirrors:

| Source | What I did | Key result |
|---|---|---|
| `theodi/orpi-corpus` → `data/ORR-station-usage-2012-13.csv` | Downloaded; parsed with Python `csv` | 623,554 bytes; 2,536 data rows; 28 columns; **bare-CR line endings**; comma-formatted padded numbers; `"  "` nulls; embedded newline in a header |
| `lvalnegri/RstationsusageUK` → `data-raw/csv/stations.csv` | Downloaded; parsed | 415,486 bytes; 2,568 stations; 17 cols incl. `NLC, TLC, x_lon, y_lat, Easting, Northing, facility_owner, is_request_stop, started_at`; **0 missing coordinates** |
| `lvalnegri/RstationsusageUK` → `data-raw/csv/dataset.csv` | Downloaded; aggregated | 6,894,027 bytes; 286,802 rows; **25 financial years 1997-98→2021-22**; metrics `Total`/`Rank`/`Changes`/`VarYoY` full, `Full`/`Reduced`/`Season` recent years only |
| `davwheat/uk-railway-stations` → `stations.json` | Downloaded; parsed | 285,418 bytes; 2,608 stations; **100% `crsCode` + lat/long**; ODbL |
| Join test: ORR `NLC` → station reference | Computed | **2,531/2,535 = 99.84%**; 4 misses all closed stations |
| Join test: ORR `Origin TLC` → davwheat `crsCode` | Computed | 13 unmatched (closed + recoded); **154 name mismatches** among matched pairs |
| National totals + YoY, 1997-98→2021-22 | Computed | **+13.5% (1998-99)**, **+19.7% (2006-07)** artefactual; −77.1%/+160.1% COVID |
| Per-station ratio distributions | Computed | 2005→2006 median 1.071, p90 1.451 vs national +19.7% ⇒ break concentrated at large/grouped stations |
| History completeness | Computed | **2,447/2,568 (95.3%) have all 25 years** |
| Least-used station by year, 2012-13→2021-22 | Computed | Winner changes almost annually; values swing 2–5× |
| App payload serialisation | Built and gzipped | **517.4 KB raw → 249.0 KB gzipped** for the full 25-year × 2,568-station corpus |

Blocked and therefore not directly verified: `dataportal.orr.gov.uk`, `www.orr.gov.uk`, `data.gov.uk`, `en.wikipedia.org`, `beta-naptan.dft.gov.uk`, `railforums.co.uk`, `merrittcartographic.co.uk`, `trainmap.co.uk`, `brilliantmaps.com`, `railuk.com`, `postcodesuk.com`, `wikidata.org`.
