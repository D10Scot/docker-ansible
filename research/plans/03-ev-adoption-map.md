# EV Adoption & Vehicle Fleet Map — Plan & Decision Document

*Researched 31 July 2026. All data findings below were verified hands-on against a real copy of the DfT/DVLA small-area files (2025 Q1) unless explicitly marked as unverified.*

---

## 1. Decision summary

**Verdict: BUILD LATER — and only in a materially reframed form. Do not build the product as originally scoped.**

**Confidence: Moderate-high (7/10)** on the data findings (measured directly from the real files); **moderate (6/10)** on the competitive read (gov.uk, DfT and ONS hosts were unreachable from this environment — see §11).

**Rationale.** The prior assessment ranked this #3 BUILD on three premises. Hands-on research confirms one and breaks two. Confirmed: the data is genuinely clean, open (OGL), quarterly, UK-wide and available at LSOA granularity — I downloaded it, parsed 1.38 million rows, and its totals reconcile to published national figures. Broken premise #1: **make and model do not exist at any sub-national geography**, so "the most popular car in your neighbourhood" — half the original concept and by far its most viral half — is simply not buildable from open data. Broken premise #2: the claim that existing coverage is only one-off PR journalism is **only true at LSOA level**; at local-authority and parliamentary-constituency level there are free, official, actively-maintained interactive dashboards (House of Commons Library, updated 15 January 2026; EVA England), and the LSOA-level policy market is already served commercially by Field Dynamics/Cenex. What remains is a genuinely unserved consumer niche — neighbourhood-level EV penetration — but it sits on a data-validity problem far more severe than "a caveat": **58.8% of Britain's battery-electric cars are company-kept**, versus 9.7% of cars overall, and the two defensible ways of handling that produce top-100 neighbourhood rankings that overlap by only 11%. The honest version of this map is a worthwhile ~2-3 week civic artefact with a real press hook (debunking the "Stockport is the UK's EV capital" story, which I confirmed is a single leasing depot). It is not a product with an audience that returns or a revenue model that survives contact with Field Dynamics.

---

## 2. The opportunity

**The curiosity served.** "Is my neighbourhood ahead of or behind on electric cars?" is a real, frequently-asked question with no good answer available to a member of the public at any granularity finer than their council. Council-level is too coarse to be interesting — a London borough or a large shire district averages together streets with driveways and streets without, which is precisely the variable that determines EV feasibility.

**Why now.**
- The UK crossed **2 million electric cars** in 2026, and BEVs were **30.0% of new car registrations in June 2026** (per Zapmap's market tracker). The transition is past novelty and into "is my area being left behind" territory.
- The ZEV mandate makes local EV-readiness a live political question; charger-siting decisions are being made now, and LSOA-level uptake is an input.
- **EV-transition inequality is the actual story in the data.** The honest measure (see §3) shows private BEV uptake concentrated in Westminster (7.30%), Camden (6.85%) and Kensington & Chelsea (6.62%) against a national private figure of **1.93%** — a threefold-plus gap that tracks wealth and off-street parking.

**The counter-consideration.** Curiosity is not need. Nothing about the answer changes a reader's behaviour. This is content, not a tool, and should be resourced as such.

---

## 3. Data deep dive

### 3.1 What I actually did

gov.uk, `assets.publishing.service.gov.uk`, `geoportal.dft.gov.uk` and `geoportal.statistics.gov.uk` are **all blocked by this environment's egress policy** (HTTP 403 at the proxy, for both `curl` and the fetch tool). I therefore verified the data by a different route:

1. Located real analyst pipelines consuming these files via GitHub code search, and read their column handling.
2. Retrieved a **committed copy of the actual DfT data** (column subsets, 2025 Q1) from the `HBudnitz/PLEASEM` repository — `df_VEH0125_col13456.csv` (**36,472,540 bytes**, 971,665 data rows) and `df_VEH0145_col1345.csv` (**16,278,450 bytes**, 409,807 data rows) — and parsed both in full.
3. Cross-checked schema and semantics against `alexsingleton/vehicle_licensing_statistics` (a 2026 Quarto build script that ingests the current releases), `PlaceBasedCarbonCalculator/build`, `UCL/urban-energy` and `stevecrawshaw/environment-plan-evidence`.
4. Joined to a mirrored ONS LSOA→local-authority lookup (`drkane/geo-lookups`, 16.3 MB) to name the anomalies.

**Sanity check passed.** My parse of the raw file yields **33,510,206 licensed cars** (30,273,910 private + 3,236,296 company) and **1,420,533 BEVs** (585,392 private + 835,141 company) at 2025 Q1 — both reconcile to the published UK car parc (~33.5m) and BEV parc (~1.4m). The data is what it claims to be.

### 3.2 The tables that exist, and exactly what geography each has

Landing pages: `gov.uk/government/statistical-data-sets/vehicle-licensing-statistics-data-files` and `.../vehicle-licensing-statistics-data-tables`. Licence: **Open Government Licence**. Cadence: **quarterly** data-file refresh plus an annual headline release.

| Table | Content | Geography | Format / size |
|---|---|---|---|
| **df_VEH0125** | Vehicles by licence status, **body type**, keepership | **LSOA / DZ / SDZ (UK)** | CSV, **62–70 MB** |
| **df_VEH0135** | Licensed **ULEVs** by fuel type, keepership | **LSOA / DZ / SDZ (UK)** | CSV, **10–23 MB** |
| **df_VEH0145** | Licensed **plug-in vehicles (PiVs)** by fuel type, keepership | **LSOA / DZ / SDZ (UK)** | CSV, **9.8–16 MB** |
| VEH0105 | Body type × **fuel type** × keepership | Upper- and lower-tier **local authority** | **ODS**, ~16.6 MB |
| VEH0142 | Plug-in vehicles (cars / motorcycles) by fuel type, keepership | **Lower-tier local authority**, published as ready-made polygon layers on DfT's geoportal | Esri / geospatial |
| VEH0122 | Vehicles by **postcode district** and body type | Postcode district | **ODS**, ~3.67 MB — **reported as not updated, under review** |
| df_VEH0120_GB / _UK | Licence status, body type, **make, generic model, model** | **Great Britain / UK — national only** | CSV |
| VEH0121 | SORN vehicles by make and model | National | ODS, ~15 MB |

*(Sizes vary by release because quarter columns accumulate; the ranges above are values reported across successive releases.)*

**The decisive cross-tabulation finding.** I enumerated every distinct value in the real VEH0125 file:

- `BodyType` ∈ **{Cars, Motorcycles, Other body types, Total}** — four values. That is the entire vehicle-type detail available at small-area geography.
- `Keepership` ∈ {Private, Company, Total} (plus 8 stray `Disposal` rows)
- `LicenceStatus` ∈ {Licensed, SORN}

And in VEH0145: `Fuel` ∈ {Battery electric, Plug-in hybrid electric (petrol), Plug-in hybrid electric (diesel), Range extended electric, Total}.

So, precisely:

- **Fuel type at small-area: YES — but only for plug-in/ULEV vehicles** (VEH0135/VEH0145). There is no petrol-vs-diesel-vs-hybrid breakdown of the whole fleet below local-authority level; for that you need VEH0105, which is **local authority and ODS**.
- **Make/model at small-area: NO.** Make and model exist only in VEH0120, which is **national**. Not LSOA, not local authority, not postcode district. **The "most popular car in your neighbourhood" feature cannot be built.** The closest legal geography is postcode district (VEH0122) and even that is body-type only and currently unmaintained. The national make/model niche is already occupied by `howmanyleft.co.uk` (still live; slight traffic growth as of June 2026), which has no geography at all.

### 3.3 Schema, as observed

Current releases (verified against 2026 build code):

```
df_VEH0125:  LSOA21CD, LSOA21NM, BodyType, Keepership, LicenceStatus, "2011 Q4", "2012 Q1", … "2025 Q4"
df_VEH0135:  LSOA21CD, LSOA21NM, Fuel, Keepership, <one column per quarter>
df_VEH0145:  LSOA21CD, LSOA21NM, Fuel, Keepership, <one column per quarter>
```

Wide format, one column per quarter, VEH0135/0145 running from **2011 Q4**. Older releases used `LSOA11CD` — DfT has migrated to **2021 LSOAs**, so any historical comparison across that boundary change needs care.

**Geography is not uniform across the UK** — a point every consumer-facing treatment must handle:
- England & Wales: **2021 LSOAs** (33,755 + 1,917; ~1,500 residents each)
- Scotland: **2022 Data Zones** (~500–1,000 residents)
- Northern Ireland: **Super Data Zones** (codes like `95AA01S1`)

Because Scottish Data Zones are roughly half the size of English LSOAs, **raw per-area counts are not comparable across nations** — only rates are. I measured **42,620 distinct areas** in VEH0125.

There is also a literal **`Miscellaneous`** row for vehicles not allocable to a small area: **172,455 company + 289,346 private licensed cars ≈ 462,000 cars that cannot be mapped at all.**

### 3.4 Suppression — including a trap that will silently corrupt a naive build

- `[c]` = suppressed, meaning a count of **1–4**. `[x]` = not available.
- Measured suppression: **8.8%** of VEH0125 cells, but **30.9%** of VEH0145 cells. For the private-BEV series specifically, **7,141 of 40,728 LSOAs (17.5%)** are suppressed.
- **The trap:** DfT **omits the row entirely** when the true count is zero, rather than writing `0`. So an absent row is a genuine zero, while `[c]` is 1–4 and genuinely unknown. **1,892 LSOAs have no private-BEV row at all** — these are real zeros. A naive left-join treats both as missing and silently drops exactly the low-uptake, disproportionately Scottish and Northern Irish areas that the "EV deserts" story is about. (This is handled correctly in Singleton's build; it is the single most likely correctness bug in a first implementation.)

### 3.5 The fleet / company-registration skew — measured, and worse than assumed

The registered-keeper caveat is not a footnote here. It is the dominant feature of the data.

**Nationally (2025 Q1):**

| | Private | Company | Company share |
|---|---|---|---|
| Licensed cars | 30,273,910 | 3,236,296 | **9.7%** |
| Battery-electric cars | 585,392 | 835,141 | **58.8%** |

**The majority of Britain's BEVs are registered to companies** — salary-sacrifice schemes, leasing firms and fleets — at a rate six times the all-car average.

**Per-LSOA distribution of company share of licensed cars:** median 4.0%, p90 9.5%, p99 29.3%, **p99.9 84.0%, max 99.6%**. 148 LSOAs (0.35%) are more than half company-registered; 48 are over 80%.

**The extremes are absurd, and I named them.** The single most company-dominated LSOA in the UK:

| LSOA | Name | Local authority | Company cars | Private cars |
|---|---|---|---|---|
| E01005819 | Stockport 018C | Stockport | **200,517** | 860 |
| E01015503 | Swindon 022C | Swindon | 152,001 | 540 |
| E01016767 | Milton Keynes 005D | Milton Keynes | 146,247 | 746 |
| E01015686 | Peterborough 006E | Peterborough | 103,934 | 869 |
| E01014868 | South Gloucestershire 019B | South Gloucestershire | 83,307 | 2,707 |
| E01023142 | Rushmoor 008B | Rushmoor | 80,656 | 1,452 |
| E01016474 | Slough 008B | Slough | 75,898 | 831 |

An LSOA holds roughly 1,500 residents. Stockport 018C has **200,517 cars registered in it**. These are leasing-company and fleet-operator registered addresses.

**This directly explains the incumbent journalism.** One Home's widely-syndicated "Stockport is the UK's EV hotspot" story, and the "Stockport records 109,389 EVs, 25.2% of licensed vehicles" figure still circulating in 2026, are **artefacts of this single depot**. Aggregating my parse to local authority:

| Local authority | All-keeper BEV % of cars *(the reported number)* | Private-only BEV % *(the honest number)* |
|---|---|---|
| Westminster | 44.3% | 7.30% |
| **Stockport** | **31.2%** | **1.93%** |
| Slough | 24.3% | 1.86% |
| Peterborough | 23.7% | 1.45% |
| Swindon | 19.9% | 1.77% |
| Milton Keynes | 19.7% | 2.88% |

Stockport's honest figure — 1.93% — is **exactly the national average**. It is a completely ordinary place for EVs. To its credit, One Home did note that over 94% of ULEVs in these areas are company-owned; the syndicated coverage generally did not.

**The two defensible methods disagree almost completely.** Restricting to LSOAs with ≥100 private cars and no suppression (35,413 areas), Spearman rank correlation between private-only and all-keeper BEV penetration is **0.855** — respectable in aggregate, catastrophic at the top, which is the only part anyone looks at:

| "Top EV neighbourhoods" list | Overlap between the two methods |
|---|---|
| Top 100 LSOAs | **11 / 100** |
| Top 500 LSOAs | 184 / 500 |
| Top 1,000 LSOAs | 485 / 1,000 |
| Top 20 local authorities | **5 / 20** |

Eight LSOAs show all-keeper BEV shares **above 100%** of their car fleet — mathematically impossible, peaking at **769%**.

**What this means for the product.**

1. **The all-keeper map is indefensible.** It cannot be shipped.
2. **Private-only is the right method** — and, crucially, **DfT supplies the `Keepership` column, so the fix is available and free.** This is genuinely good news and is why the dataset is still worth something.
3. **But private-only describes only 41.2% of the BEV fleet.** Salary-sacrifice EVs are driven by ordinary households on ordinary streets; excluding them understates real neighbourhood EV presence, and understates it *unevenly*, since salary sacrifice skews to higher-earning employees with employer schemes. There is no open data that reallocates them to driver postcodes, and DfT states there is no way to do so.
4. So the honest headline is narrow and must be stated on every screen: *"share of **privately-owned** cars that are electric."* Not "cars in your neighbourhood."
5. **The commercial tension is real.** The accurate map's story — affluent London boroughs lead — is duller and less shareable than the inaccurate "Stockport!" headline that earns the clicks. The product's integrity is inversely correlated with its virality.

### 3.6 Pipeline fragility

- Download URLs are **`assets.publishing.service.gov.uk/media/<opaque-hash>/df_VEH0125.csv`**, and **the hash changes every release** — I observed at least four distinct media IDs for the same table across repos (`65734c35…`, `68494ae1…`, `696648a3…`, `69ef3d34…`). A pipeline **must scrape the landing page**; hardcoded URLs silently rot.
- Singleton's build wraps downloads in a **3-attempt retry** with the comment that "gov.uk occasionally drops HTTP/2 streams mid-download." Expect flakiness on 60 MB files.
- Table numbers themselves churn: VEH0122 is under review, and DfT has renumbered tables before and published an old→new mapping.

---

## 4. Competitive landscape

I could not load these sites directly (egress policy), so status below is from current search-index evidence; treat "alive" as high- but not full-confidence.

**Live and maintained — genuine competition**

- **House of Commons Library, "Local area data: Electric vehicles and charging points" (CBP-10561).** Free, official, interactive dashboard covering EVs and chargepoints **by local authority** across the UK. **Vehicle data updated 15 January 2026.** This is the strongest incumbent and largely satisfies the general-interest question at council level.
- **EVA England EV Constituency Dashboard.** Parliamentary-constituency level, built by Field Dynamics using Zapmap charger data. Live; aimed squarely at the political/press audience.
- **Cenex NEVIS + Field Dynamics** (`EVMap`, `GigaMap`, `CatchmentModeller`). Commercial household- and **LSOA-level** EV analytics sold to local authorities; their near-home-charging index is explicitly computed at LSOA and aggregated up. **This occupies the B2B/policy monetisation route completely**, and does so bundled with charger siting — the thing councils actually have budget for.
- **DfT's own Transport Statistics Geography Portal** (`geoportal.dft.gov.uk`) publishes vehicle licensing as **ready-made polygon geospatial layers** (e.g. `LicensedPlugInVehiclesCarsVEH0142 UK DfT Poly`). DfT is publishing the map layers itself — for GIS users, not consumers, but it lowers the barrier for anyone else to build this.
- **howmanyleft.co.uk** — live, national make/model lookup, no geography. Proves demand for the make/model curiosity and simultaneously proves the geography doesn't exist.
- **Zapmap.** Confirmed distinction holds: Zapmap is **chargers plus national market-share statistics** (`zapmap.com/ev-stats`). It tracks new registrations nationally and monthly. It does **not** publish small-area vehicle-adoption maps. The gap is real.
- **SMMT.** National new-registration statistics only; no small-area geography.
- **New AutoMotive "The Index"**, **Auto Trader "Road to 2030"** — national/monthly registration trackers, not neighbourhood maps.

**One-off journalism (the prior assessment's premise — confirmed at LSOA level)**

One Home ("Stockport is the UK's EV hotspot"; "areas with the fewest and most electric cars"), Regit ("UK EV adoption by postcode"), Dick Lovett ("EV Deserts"), Carwow. All are static articles. **All rely on the all-keeper figure and are therefore substantially wrong**, as demonstrated in §3.5.

**Research-grade prior art (not products, but they narrow the novelty claim)**

- **`alexsingleton/vehicle_licensing_statistics`** — an active 2026 build producing per-LSOA BEV counts and penetration, a GeoParquet of LSOA polygons joined to metrics, an OAC-neighbourhood-type cluster analysis and a national time series. Notably it already uses the **private-only method I would recommend**. Research output, no consumer front-end — but someone credible is standing on this exact ground.
- **Place-Based Carbon Calculator** — a live public tool consuming VEH0125/0135/0145 at LSOA for carbon footprinting.

**The wedge, honestly stated.** Two things are genuinely unoccupied:
1. **Neighbourhood granularity for a general audience.** Everything free and maintained stops at local authority or constituency. Nothing lets a member of the public see their own LSOA.
2. **Methodological correctness as the product.** Every popular treatment of this dataset is distorted by the fleet artefact. A map that corrects it — and *shows* the correction, with a "why Stockport isn't really the EV capital" explainer — is a defensible and honest position nobody occupies.

That is a real wedge. It is also a narrow one, and #2 appeals mainly to journalists and researchers, not consumers.

---

## 5. Product definition

**Target user.** Primary: a UK adult idly curious whether their area is ahead or behind on EVs — arriving from search or social, staying 90 seconds, not returning. Secondary, and strategically more valuable: **journalists, local-government officers and researchers** who need a citable, methodologically-sound neighbourhood figure and currently have only the distorted one.

### MVP — in scope

1. **Postcode → your neighbourhood.** Enter a postcode, land on your LSOA/DZ/SDZ. Show: private BEV count, private car count, **private BEV penetration %**, and ranking as a percentile nationally and within your local authority.
2. **A national choropleth of private BEV penetration** at LSOA level, with local-authority and national zoom tiers.
3. **The time series.** Data runs from 2011 Q4, so every area gets a "how your neighbourhood electrified" line chart, plus a national animated sweep. This is the strongest content asset in the dataset and is nearly free once the panel is built.
4. **Explicit honesty furniture — the differentiator, not a disclaimer.** A permanent "private cars only" label; a toggle that shows the all-keeper figure *labelled as distorted*; and a short standing explainer page: **"Why Stockport isn't Britain's EV capital."** Suppressed areas rendered in a distinct hatch, not as zero.
5. **Correct suppression handling** (absent row = 0, `[c]` = unknown), per §3.4.

### The single killer feature

**The corrected-vs-reported toggle.** One control that flips between the number the newspapers printed and the number the data actually supports, with the delta named on-screen — Stockport 31.2% → 1.93%. It is the only thing here that no incumbent offers, it is the entire press hook, and it converts the dataset's biggest weakness into the product's reason to exist.

### Explicitly OUT of scope

- **"Most popular car in your neighbourhood"** — impossible; no make/model below national level (§3.2). Cut it from the concept entirely.
- **Fuel-mix of the whole fleet at neighbourhood level** — petrol/diesel/hybrid splits exist only at local authority, in ODS.
- **Chargepoints.** Zapmap and Field Dynamics own this; adding a weak charger layer invites a comparison that cannot be won.
- **Any "should I buy an EV" advice, running-cost calculator, or vehicle marketplace.**
- **Accounts, saved areas, alerts.** Quarterly data cannot justify them.
- **Live or real-time anything.**
- **Cross-national count comparisons** — Scottish DZs and NI SDZs are not size-comparable to English LSOAs; rates only.

---

## 6. Technical plan

**Shape: a static site.** There is no user state, no write path, and the data changes four times a year. Anything server-side is waste.

**Pipeline** (scheduled monthly; the data moves quarterly):
1. Scrape the gov.uk landing page for current `df_VEH0125` / `df_VEH0145` media URLs — never hardcode (§3.6). Retry 3×.
2. Ingest with **DuckDB** (all four reference pipelines I examined use DuckDB or R/arrow; DuckDB reads the 60 MB CSV directly and handles the `[c]`/`[x]` sentinels via `strict_mode=false`).
3. Unpivot wide quarters → long panel; filter `Keepership='Private'`, `LicenceStatus='Licensed'`; join BEV numerator to `BodyType='Cars'` denominator on (area, quarter). Apply the absent-row-equals-zero rule. Drop `Miscellaneous`.
4. Emit a per-area **Parquet** metrics table plus a small per-area JSON for the lookup panel.

**Boundaries.** ONS Open Geography Portal for E&W 2021 LSOAs; **NRS/Scottish Government for Data Zones and NISRA for Super Data Zones — three separate sources**, which is a real and often-underestimated integration cost. Use the **BGC (generalised clipped, 20 m)** variant, not full-resolution BFE.

**Vector tiles, not GeoJSON — measured, not assumed.** I downloaded already-simplified LSOA boundaries and measured them: Stockport's 190 LSOAs occupy **405,447 bytes** (2.13 KB/LSOA, ~45 coordinate pairs each); City of London's 6 occupy 9,154 bytes. Extrapolated to ~42,000 UK small areas that is **≈ 88 MB of GeoJSON even after simplification** — an order of magnitude beyond what a browser can accept. Therefore: **`tippecanoe` → PMTiles**, served as a single file over HTTP range requests, rendered with MapLibre GL. Expect roughly 60–120 MB of tiles for the full UK at LSOA detail; metrics joined at runtime or baked in as tile attributes.

**Hosting.** Static bundle on Cloudflare Pages; PMTiles on Cloudflare R2 (zero egress fees, which matters — R2's lack of egress charging is the main reason to prefer it to S3 here). Pipeline on GitHub Actions cron. Postcode→LSOA lookup from ONS ONSPD, shipped as a static prefix-partitioned index so no geocoding service is needed.

**Rough running cost: £0–5/month** at modest traffic (R2 storage for ~100 MB of tiles plus Pages bandwidth). A viral spike is the only cost risk, and R2's zero egress largely neutralises it. Assume **£5–10/month** as a planning figure including a domain.

---

## 7. Effort & timeline

For one competent developer already comfortable with Python/DuckDB and web mapping:

| Work | Days |
|---|---|
| Data pipeline: scrape, ingest, panel build, suppression/zero semantics, validation | 3 |
| Boundaries: three national sources, reconcile, simplify, tippecanoe → PMTiles | 3 |
| Postcode lookup + area page (stats, percentiles, time-series chart) | 2 |
| Map UI, choropleth, corrected/reported toggle, legend, mobile | 3 |
| Methodology + explainer content, "why Stockport isn't the EV capital" | 2 |
| Polish, accessibility, SEO/meta, launch | 2 |
| **MVP total** | **~15 dev-days** |

Add 2–3 days if the Scottish/NI boundary reconciliation misbehaves, which it frequently does.

**Ongoing maintenance: low but non-zero — roughly 0.5–1 day per quarter.** The pipeline is scheduled, but the media-URL hash rotation, occasional table renumbering, and the eventual LSOA boundary vintage change all require a human. Budget **~4 days/year**, plus an unbudgeted day whenever DfT restructures the tables.

---

## 8. Distribution

**SEO.** Realistic head terms are contested but the long tail is wide open and matches the product exactly: `"EV ownership in [town]"`, `"electric car uptake [postcode]"`, `"how many electric cars in [area]"`, `"EV adoption by area UK"`, `"electric cars per postcode UK"`. **Generate a static, indexable page per local authority (~370) and per MSOA or LSOA** — this is the single highest-leverage distribution move and costs nothing at build time. The area pages are the product's whole SEO surface.

**Press / viral hook — and it is a good one.** Not "here is a map"; that gets ignored. The hook is **"The UK's supposed EV capital has average EV ownership — we checked."** A named, quantified debunk of a story that has been syndicated repeatedly (200,517 company cars in one Stockport LSOA; 31.2% → 1.93%) is genuinely newsworthy, offers a data-journalism angle to *The Guardian*, the BBC data unit, *Big Issue*, and trade press (*Fleet News*, *Autocar*), and positions the tool as the authority rather than the aggregator. This hook is one-shot; spend it deliberately at launch.

**Communities to seed.** SpeakEV (~79,000 members, 2.1m posts — the largest UK EV forum), r/ElectricVehiclesUK and r/unitedkingdom, Tesla Owners UK, EVA England's membership, Hacker News (the methodology angle, not the map), the UK open-data/geo community (Owen Boswarva's audience, the ONS/geo Slack circles), and local-government transport officers via LinkedIn.

**Realistic expectation:** one launch spike of tens of thousands of sessions, decaying to a long organic tail driven entirely by the per-area pages. Quarterly data gives no reason to return.

---

## 9. Sustainability

Assessed honestly, the options are weak:

- **Do nothing; absorb the cost.** At £5–10/month this is entirely viable and is the recommended posture. Treat it as a portfolio/civic artefact.
- **B2B data/dashboards for local authorities.** **Effectively closed.** Field Dynamics and Cenex already sell LSOA-level EV analytics into exactly this buyer, bundled with the charger-siting modelling councils actually procure. Competing needs a sales motion, not a map.
- **Affiliate / lead-gen to EV retail.** Zapmap, Auto Trader, Carwow and Regit own this funnel with far better intent signals. Traffic here is curiosity, not purchase intent. Expect negligible revenue and meaningful credibility cost — bolting car ads onto a tool whose selling point is methodological integrity actively undermines it.
- **Consultancy/press halo.** The most plausible non-zero return: the debunk earns citations and inbound work. Unquantifiable, but this is how comparable civic tools have actually paid off.
- **Donations/grant.** Possible via a climate/transport funder given the inequality framing; low probability, high effort.

**Conclusion: assume zero revenue.** Only build this if it is worth ~15 days and £10/month for its own sake.

---

## 10. Risks & kill criteria

**Risks, roughly ordered by severity**

1. **Editorial integrity vs. reach.** The accurate map's finding is "wealthy London boroughs lead," which is worthy and unsurprising. The inaccurate version is the one that travels. Resisting that pressure is the whole point of the product and also caps its ceiling.
2. **The honest metric is genuinely incomplete.** Private-only excludes 58.8% of BEVs. A well-informed critic can fairly say the map understates real EV presence, especially in salary-sacrifice-heavy areas — and there is no open data that fixes it.
3. **High suppression at the sharp end.** 17.5% of LSOAs have suppressed private-BEV counts, concentrated in exactly the low-uptake areas an "EV deserts" story is about. Large parts of the map are honestly blank.
4. **Incumbent expansion.** If the Commons Library dashboard, DfT's geoportal, or Field Dynamics ships a free public LSOA view, the wedge closes overnight. DfT already publishes polygon layers, so the distance is short.
5. **Pipeline rot.** Rotating media URLs, table renumbering (VEH0122 is already under review), and the LSOA11→LSOA21 style boundary migrations.
6. **No retention.** Quarterly data, curiosity use case, no reason to return.
7. **Misreading risk.** Users will read "EVs in my neighbourhood" as "cars driven near me" no matter how it is labelled. That misreading is the thing the product exists to correct, and it may simply be unwinnable at a 90-second attention span.

**Kill criteria — stop if any of these hold**

- **Before writing code:** if the corrected-vs-reported toggle does not survive a hostile read as *the* reason the site exists, there is no product here — the plain map is a weaker Commons Library dashboard. Kill.
- **Before writing code:** if a free, public, LSOA-level EV map from DfT, the Commons Library, Zapmap or Field Dynamics is found live, kill (I could not fetch those sites; verify first — see §11).
- **At the data-build stage:** if private-only BEV counts prove too suppressed to render a coherent national picture (say >30% of LSOAs unusable at the chosen geography), drop to MSOA — and if it fails there too, kill.
- **Post-launch, 3 months:** if the per-area pages are not accruing organic search traffic, the SEO thesis — the only durable distribution channel — has failed. Stop maintaining; leave the static site up.
- **Any time:** if maintenance exceeds ~2 days/quarter, archive it with a dated "data current as of" banner rather than letting it rot silently.

---

## 11. Open questions

**Could not verify (environment egress policy blocked `gov.uk`, `assets.publishing.service.gov.uk`, `geoportal.dft.gov.uk`, `geoportal.statistics.gov.uk`, `data.gov.uk`, `owenboswarva.com` and all non-GitHub hosts; findings came from search-index evidence, third-party code and a mirrored copy of the real data):**

1. **The live gov.uk table listing.** Exact current table numbers, titles and file sizes should be read off the page directly before committing. My table list is assembled from search-index snapshots and third-party consumers and may be one release stale.
2. **VEH0122's status.** Reported as "not updated, under review." If postcode district were revived *and* gained a fuel-type split, it would be a materially better consumer geography than LSOA — more intuitive, fewer areas, less suppression. Worth checking directly.
3. **Whether DfT's geoportal already serves LSOA plug-in layers publicly as a browsable web map.** It publishes VEH0142 polygon layers at LA level and search evidence indicates LSOA-level PiV data too. If there is already a public LSOA web map, the wedge narrows sharply. **Check this first — it is the cheapest kill test.**
4. **Live status and depth of the Commons Library and EVA England dashboards.** I have their update dates but have not seen them. Confirm they genuinely stop at LA/constituency.
5. **Exact ONS boundary file sizes** for LSOA 2021 BGC/BSC, and equivalents from NRS and NISRA. My 88 MB GeoJSON figure is extrapolated from a measured 2.13 KB/LSOA on a third-party simplified set — sound as an order-of-magnitude argument for vector tiles, not a precise number.
6. **Whether the `[c]` suppression rate is materially lower at MSOA.** DfT does not publish MSOA directly, but aggregating LSOAs upward would cut suppression substantially and might be the better default geography. Testable from the data I already have; not yet done.
7. **Whether Owen Boswarva's FOI-obtained Output Area dataset is still being refreshed.** He has obtained **unsuppressed Output Area-level** counts via FOI covering end-2023 and end-2024. If maintained, that is finer geography *and* no suppression — a significant upgrade over the published LSOA files, and a route worth pursuing directly with him.
8. **Whether any open or purchasable dataset reallocates leasing/salary-sacrifice vehicles to driver postcodes.** DfT says there is not. If one exists commercially, it would transform this product from "honest but partial" to genuinely authoritative.
9. **Whether the 2011→2021 LSOA migration is applied retrospectively** across the full historical series in current releases, or only forward. This determines whether the "how your neighbourhood electrified since 2011" time series is actually continuous.
