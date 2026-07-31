# Storm Overflow / Sewage Alert — Plan & Decision Document

*Research date: 31 July 2026. Author: research agent.*

> **Methodological honesty statement — read this first.** This session's egress policy blocked **all** direct HTTP fetching (`curl`, `WebFetch`) to every external host, including `streamwaterdata.co.uk`, `portal-streamwaterdata.hub.arcgis.com`, `environment.data.gov.uk`, `sas.org.uk` and `top-of-the-poops.org`. Proxy status endpoint confirmed `connect_rejected — gateway answered 403 to CONNECT (policy denial)` for each. **I therefore could not issue a single live API request and cannot claim to have personally observed any endpoint returning data.**
>
> To compensate I substituted a stronger-than-usual documentary method: GitHub code search across all public repositories (which *was* available) to read the **actual source code and committed data files of ~15 independent projects that consume these feeds in production**. Endpoint URLs, field names, record limits and coordinate systems below are taken verbatim from that code, cross-checked across multiple independent codebases, and corroborated by committed CSV/JSON output containing real data with timestamps as recent as **March 2026**. That is strong evidence the endpoints are live and the schemas correct — but it is *second-hand*. Everything below is labelled **[code-verified]**, **[search-derived]** or **[unverified]** accordingly. Section 12 lists what must be checked by hand before any commitment.

---

## 1. Decision summary

**Verdict: DON'T BUILD.**

**Confidence: High (~80%)** that this should not be built as a standalone consumer product intended to sustain itself. **Moderate (~60%)** on the narrower question of whether the one genuine remaining gap (arbitrary-point upstream-aware alerting) is worth building as a free open-source utility — see §5 for that carve-out.

**Rationale.** The data is real, open, free, unauthenticated and genuinely excellent — better than the prior assessment implied, with eleven water companies exposing standard Esri FeatureServer endpoints that any developer can poll today without registration. But the prior assessment's "AVOID — SATURATED" verdict on bathing-water/swim-safety turns out to apply to the real-time EDM angle too, and *more* strongly than expected. Surfers Against Sewage did not stand still: alongside the Safer Seas & Rivers Service app (4.9★, 11,000+ iOS ratings, 100,000+ Android installs, 450+ alerting locations), they now run **Data HQ**, a live national map of *every* CSO across England, Wales and Scotland with full spill history back to December 2024 and postcode search. Separately, **SewageMap.co.uk** (Dr Alex Lipp, UCL) already solves the single hardest and most differentiating technical problem — hydrological downstream propagation of live discharges across England and Wales — has ~300,000 visitors/year, and has **open-sourced the entire engine as the `POOPy` Python library plus pre-computed D8 flow rasters on Zenodo**, so the moat is not merely crossed, it is published as a pip install. Meanwhile **Defra's own design team has an alpha prototype in public GitHub** (`defra-design/Water-Quality-Checker`) explicitly aimed at "wild swimmers, paddleboarders, canoeists, anglers, dog walkers…" that already wires together bathing water, hydrology, storm overflows, pollution incidents, Met Office rainfall and water chemistry — i.e. the exact mashup this brief proposed, being built by the department that will own the standard. The remaining unserved slice is narrow (alerts on *user-chosen non-designated* points with upstream awareness), is technically cheap for any incumbent to add, has at least four hobbyist implementations already on GitHub, and sits in front of an audience that is emotionally and financially aligned to a charity you would be competing with. There is no defensible position here.

---

## 2. The opportunity — and why it is smaller than it looks

**The problem, honestly stated.** ~4.4 million adults swim outdoors in England annually; ~543,000 do so regularly (up from ~266,000 in 2016-17); paddlesports participation rose to 24% of adults in 2025 from 18% in 2023 [search-derived]. These people want to know one thing: *is it grim in the water today?* The statutory EDM feed answers a proxy question — *did a pipe open near here recently?* — which is genuinely useful and genuinely insufficient.

**Why now (the regulatory freshness argument).**

| Driver | Status | Effect on this product |
|---|---|---|
| **s.81 Environment Act 2021** — publish discharge start/stop within 1 hour | **Live.** All ~15,000 English storm overflows had an EDM fitted as of the 2025 annual return [search-derived, EA press release Mar 2026] | The core feed exists and is legally guaranteed. This is the strong part. |
| **Water (Special Measures) Act 2025** — extends near-real-time duty to 100% of *emergency* overflows | Royal Assent 24 Feb 2025; equipment rollout **phased to 2035** [search-derived] | More overflows over time, but slowly. Not a 2026 catalyst. |
| **s.82 Environment Act 2021** — continuous water-quality monitoring (sondes) up/downstream of every overflow and STW | Rollout began 2025; **≥25% of applicable assets by 2030; full by 2035** [search-derived] | This is the transformative dataset — measured pH/turbidity/DO/ammonia rather than "a pipe opened". **It is 4–9 years from meaningful national coverage, and I found no confirmed open publication duty, API or format for it.** |
| **Defra Water White Paper (20 Jan 2026)** — abolish Ofwat, single Integrated Water Regulator | Published; legislation pending | Institutional churn. Feeds and platform ownership may move. Risk, not opportunity. |

**The honest reading of "why now": you are late, not early.** The s.81 duty bit in 2023–2025. Every incumbent named in this brief already consumes it. The genuinely new dataset (s.82) is 2030+. There is no 2026 regulatory moment that opens a door for a new entrant.

---

## 3. Data deep dive

### 3.1 What I actually did

Blocked from HTTP, I read the source of production consumers of these feeds. The most valuable were:

- **`AlexLipp/POOPy`** (GPL-3.0) — the library behind SewageMap.co.uk; one module per water company. Definitive for endpoints and per-company quirks.
- **`top-poop/top-of-the-poops-site`** — the live Top of the Poops backend (`services/stream/stream.py`, `stream-sources.http`).
- **`defra-design/Water-Quality-Checker`** — Defra's alpha prototype; `app/services/clients/storm-overflow-client.js` contains a curated company-feed table with normalisation notes.
- **`sebbacon/sewage-alerts`**, **`DanielChicot/turd-alert`**, **`Deveroonie/SewageData`**, **`bwgraves/SpillAlerts`**, **`danielashare/stw-map-of-shame`**, **`elidgdg/water-quality-checker`**, **`Walton-Viking-Scouts/thameswatch-model`**, **`a-jone5/nRtsom`** (R package), **`sticerd-eee/sewage`** (LSE research) — independent corroboration.

Cross-checking these gave consistent endpoints. `Walton-Viking-Scouts/thameswatch-model` also commits **real API output** (`data/cso_upstream_chertsey.csv`) with `statusChanged` values of `2026-03-13T01:24:00` — direct evidence the Thames feed was live and returning current data in March 2026.

### 3.2 The three access routes

There are **three** ways in, and understanding the distinction matters:

1. **Stream portal** (`streamwaterdata.co.uk`, ArcGIS Hub mirror `portal-streamwaterdata.hub.arcgis.com`) — the industry catalogue/shop-window. Ofwat Innovation Fund project led by Northumbrian Water with a consortium of **11 water companies** and 5 partners, designed with **Icebreaker One**; Day-1 platform launched April 2024 [search-derived]. Human-browsable dataset pages per company.
2. **National Storm Overflow Hub (NSOH)** — Water UK's public map (ArcGIS Experience Builder app; `experience.arcgis.com/experience/cb89b71c060f40d394dca026445da4bc/`), showing near-real-time EDM activity for **the previous 24 hours, or the most recent recorded spill if older than 24h** [search-derived]. A *map*, not an API.
3. **The underlying per-company Esri FeatureServer endpoints** — what everyone actually integrates against. **These are the real API.** No registration, no token, no key.

**Key practical finding: you do not need Stream at all.** Stream is a discovery layer over feature services that are individually public. Every production consumer I read bypasses the portal and hits the company endpoints directly.

### 3.3 Verified endpoints by company [code-verified]

All are standard ArcGIS REST query endpoints. Canonical call pattern (from `a-jone5/nRtsom`, `Deveroonie/SewageData`, `top-of-the-poops-site` — consistent across all):

```
{API_ROOT}{RESOURCE}?where=1%3D1&outFields=*&outSR=4326&f=geojson
```

`f=json` (Esri JSON) and `f=geojson` both supported. Pagination via `resultOffset`/`resultRecordCount`; `returnIdsOnly=true` supported (used by Top of the Poops for cheap delta checks).

| Company | ArcGIS org / API root | Resource path | Page limit |
|---|---|---|---|
| Anglian Water | `services3.arcgis.com/VCOY1atHWVcDlvlJ/arcgis/rest/services/` | `stream_service_outfall_locations_view/FeatureServer/0/query` | 1000 |
| Northumbrian Water | `services-eu1.arcgis.com/MSNNjkZ51iVh8yBj/arcgis/rest/services/` | `Northumbrian_Water_Storm_Overflow_Activity_2_view/FeatureServer/0/query` | 2000 |
| Severn Trent Water | `services1.arcgis.com/NO7lTIlnxRMMG9Gw/arcgis/rest/services/` | `Severn_Trent_Water_Storm_Overflow_Activity/FeatureServer/0/query` | 2000 |
| South West Water | `services-eu1.arcgis.com/OMdMOtfhATJPcHe3/arcgis/rest/services/` | `NEH_outlets_PROD/FeatureServer/0/query` | 1000 |
| Southern Water | `services-eu1.arcgis.com/XxS6FebPX29TRGDJ/…` **or** `…/6qJmARkS2dt2IjVA/…` — **conflicting** (see §3.6) | `Southern_Water_Storm_Overflow_Activity/…` / `SouthernWater_StormOverflowActivity_PROD_view/…` `FeatureServer/0/query` | 1000 |
| Thames Water (Esri view) | `services2.arcgis.com/g6o32ZDQ33GpCIu3/arcgis/rest/services/` | `Thames_Water_Storm_Overflow_Activity_(Production)_view/FeatureServer/0/query` | — |
| United Utilities | `services5.arcgis.com/5eoLvR0f8HKb7HWP/arcgis/rest/services/` | `United_Utilities_Storm_Overflow_Activity/FeatureServer/0/query` | 2000 |
| Wessex Water | `services.arcgis.com/3SZ6e0uCvPROr4mS/arcgis/rest/services/` | `Wessex_Water_Storm_Overflow_Activity/FeatureServer/0/query` | 2000 |
| Yorkshire Water | `services-eu1.arcgis.com/1WqkK5cDKUbF0CkH/arcgis/rest/services/` | `Yorkshire_Water_Storm_Overflow_Activity/FeatureServer/0/query` | 2000 |
| Dŵr Cymru Welsh Water | `services3.arcgis.com/KLNF7YxtENPLYVey/arcgis/rest/services` | `/Spill_Prod/FeatureServer/0/query?where=1=1&outFields=*&f=json` | 2000 |

**Non-Esri outliers:**

- **Thames Water proprietary Open Data API** — two generations found. Legacy MuleSoft: `https://prod-tw-opendata-app.uk-e1.cloudhub.io/data/STE/v1/DischargeCurrentStatus`, **requires `client_id` + `client_secret` headers**, self-service registration at `data.thameswater.co.uk/s/application-listing`, max 1000 items, supports server-side filtering (`?col_1=AlertStatus&operand_1=neq&value_1=Not discharging`). Newer, in current POOPy: `https://api.thameswater.co.uk/opendata/v2/discharge/status` with `limit`/`offset` params. Thames is **the only company requiring registration**, and only for its own API — its Esri view needs none.
- **Scottish Water** — `https://api.scottishwater.co.uk/overflow-event-monitoring/v1/near-real-time`. Outside the s.81 regime (Scotland legislates separately) but present in POOPy and consumed by SAS and the Rivers Trust.
- **Hafren Dyfrdwy** — not found as a separate feed in any codebase. Presumed folded into Severn Trent (its parent). **[unverified]**

**Coverage summary: 9 of 9 English WaSCs verified, plus Welsh Water and Scottish Water = 11 feeds, national coverage of England, Wales and Scotland.** Not verified: Hafren Dyfrdwy separately; Northern Ireland (NI Water — no feed found; NI is not covered by the Environment Act 2021 provisions).

### 3.4 Schema [code-verified]

**There is no common schema.** This is the single biggest ingestion cost. Three distinct families observed:

**(a) Thames family** — string status, OSGB36 coordinates:
```
LocationName, PermitNumber, ReceivingWaterCourse, X, Y,
AlertStatus, StatusChange, MostRecentDischargeAlertStart,
MostRecentDischargeAlertStop, AlertPast48Hours
```
`AlertStatus` ∈ `{'Not Discharging', 'Recent Discharge', 'Discharging', 'Offline'}` (from `JonnyDawe/UK-Sewage-Map/src/utils/discharge/types.ts`). Dates are `esriFieldTypeDate` = **epoch milliseconds** in the Esri view; ISO-8601 strings in the proprietary API. **`X`/`Y` are OSGB36 eastings/northings, not lat/lon** — an explicit comment in `dhruvsyam123/london-nervous-system/ingestors/thames_water.py` warns about exactly this. Real values: `472800,174500`.

**(b) Severn Trent family** — integer status codes, epoch-ms:
```
Id (e.g. "SVT00291"), ReceivingWaterCourse, Latitude, Longitude,
LatestEventStart (epoch ms), LatestEventEnd (epoch ms),
Status (int), LastUpdated (epoch ms)
```
(from `sebbacon/sewage-alerts/docs/superpowers/specs/2026-03-17-sewage-alerts-design.md`)

**(c) South West Water** — same semantics, **lowercase field names**. Defra's own client carries an explicit `lowercaseFields: true` flag for SWW alone and a `normaliseAttributes(attrs, lowercaseFields)` function. Some companies also expose camelCase (`locationName`, `alertStatus`, `receivingWaterCourse`) vs PascalCase depending on endpoint generation.

Budget for a per-company adapter with its own field map, status-code map, date parser and CRS handling. POOPy's `field_mapping` dicts are the reference implementation and are GPL-3.0.

### 3.5 Cadence, licence, registration

- **Cadence:** statutory duty is publication **within 1 hour** of discharge start and of stop (s.81). Observed practice per Defra's own docs: *"Coverage and timeliness vary by water company."* NSOH map shows a rolling 24h window. Practical polling interval of 10–15 minutes is well inside the data's own resolution. [search + code-derived]
- **Registration:** **none** for any of the 11 Esri feeds. Only Thames's proprietary API needs a free self-service `client_id`/`client_secret`.
- **Licence: NOT VERIFIED — and this is a genuine commercial risk.** Stream/NSOH describe themselves as "a source of open data"; Icebreaker One publicly advocates mandating OGL or CC-BY. But I could not load a single dataset page to read its actual licence field, and Defra's *own* research notes in `docs/non-government-water-data-sources.md` repeatedly flag this class of problem — e.g. for Canal & River Trust data: *"Hub lists OGL; some catalogue entries historically cited INSPIRE EUL — confirm licence PDF before production"*, and for an EA layer: *"package licence field empty on data.gov.uk — treat as EA reuse pending confirm."* If Defra's designers can't assume the licence, neither can you. **Redistribution and commercial reuse rights must be confirmed per company before any monetised product.**

### 3.6 Data-quality gotchas — the honest list

1. **A discharge event is not a contamination measurement.** The feeds carry no volume, no concentration, no duration-weighted load. Stream's own documentation states the APIs *"do not provide information on the quality of the body of water in question… no information on the volume of a discharge or any change to the water quality as a result."* This is the fundamental epistemic limit of the entire product category.
2. **"Not discharging" ≠ safe.** Agricultural runoff, misconnections, urban diffuse pollution, upstream STW final effluent and unmonitored assets all contaminate water with no EDM event. An app whose green state implies safety is actively misleading.
3. **The discharge point is often unknown.** SAS's own caveat: *"in the majority of cases, we are unable to determine the location of the discharging pipe."* Feed coordinates are the monitored asset, which may be some distance from the actual outfall.
4. **Dilution and travel time are unmodelled in the raw feed.** A spill 10 km upstream matters differently from one at the entry point, and differently again at 2 m³/s vs 40 m³/s flow. Solving this is the real product problem — and SewageMap has already solved it and open-sourced the solution.
5. **"Non-impacting" classification is contested.** Southern Water's Beachbuoy was publicly accused of *"a manipulation of the data"* after it began filtering displayed discharges by tidal direction — *"trying to manipulate the situation so the press don't see any red icons."* Any company-supplied "impact" flag is a judgement call by the discharger.
6. **Monitor availability.** England reached 100% EDM fitment in the 2025 return, but the annual return dataset has recorded, since 2021, *reasons why monitors provided data for <90% of the return period*. `Offline` is a first-class value in the live status enum for a reason. An offline monitor is an unknown, not a zero — and must not render green.
7. **Endpoint churn is observable.** Southern Water appears under **two different ArcGIS org IDs** across codebases of similar vintage (`XxS6FebPX29TRGDJ` vs `6qJmARkS2dt2IjVA`), and Thames has migrated from MuleSoft `/data/STE/v1/` to `api.thameswater.co.uk/opendata/v2/`. Resource names carry `_view`, `_2_view`, `_PROD`, `(Production)` suffixes that betray republishing. **Expect breakage several times a year with no deprecation notice.**
8. **Beware the 2025 headline numbers.** 291,492 spill events in 2025; average spills per overflow down 31.8 → 20.5; total duration down 48%. 2025 was a notably dry year. Attributing that fall to infrastructure improvement rather than rainfall would be a serious analytical error, and any product that leans on it will be corrected publicly.

### 3.7 Adjacent datasets — which combination actually helps

| Dataset | Access | What it adds | Verdict |
|---|---|---|---|
| **EA Bathing Water Quality API** — `environment.data.gov.uk/bwq/` | Open, OGL, linked data + CSV/JSON, no key [search-derived] | *Measured* E. coli / intestinal enterococci. ~400 sampling points, **weekly, 15 May–30 Sep only**. Public face is **Swimfo**. | High trust, low frequency, coastal-biased. **Already integrated by SAS, Defra prototype, and everyone else.** |
| **EA Flood Monitoring / Hydrology** — `environment.data.gov.uk/flood-monitoring/`, `/hydrology/` | Open, OGL, no key | River level & flow ⇒ dilution capacity and travel time. **This is the ingredient that turns a discharge event into a risk estimate.** | Genuinely valuable. Prior assessment marked flood data itself SATURATED, but as an *input* it is underused. |
| **EA Water Quality Archive** — `environment.data.gov.uk/water-quality/data/observation` | Open | Temp, pH, ammonia, DO. **Note: legacy API retired December 2025**; this is the replacement (per Defra's own client comments). | Periodic lab samples, sparse. Supporting context only. |
| **EA Water recreation locations** — OGC API Features, `…/spatialdata/water-recreation-locations-zones-catchment/ogc/features/v1` | Open, ~3,347 locations, GeoJSON/GPKG | **A national register of where people actually swim/paddle, including non-designated spots.** Research snapshot (~2017–2024), not live. | The most interesting *unexploited* dataset here — it maps the gap between "designated bathing water" and "places people actually go". |
| **s.82 continuous WQ sondes** | **No public API, no confirmed open publication duty, no format** | Actual continuous measured quality. The thing that would fix problem #1. | **≥25% of assets by 2030, full by 2035.** Not a 2026 product input. |
| **Met Office rainfall** (DataHub) | Registration; commercial tiers | Antecedent rainfall — the strongest single predictor of poor water quality. | Useful; licensing friction. |

**Best possible combination:** live EDM + upstream catchment topology + EA river flow (for dilution and travel time) + antecedent rainfall + latest bathing-water sample, presented as a *graded risk statement with explicit uncertainty*, extended to non-designated spots via the EA recreation-locations register.

**That combination is genuinely better than any single incumbent offers today.** It is also, almost line for line, the architecture of `defra-design/Water-Quality-Checker` — whose `README.md` contains a table of exactly these sources and whose landing page reads: *"This is an alpha discovery prototype… It explores how Defra could provide a single, trusted view of water conditions."*

---

## 4. Competitive landscape

### 4.1 Surfers Against Sewage — the incumbent, re-verified

**Safer Seas & Rivers Service (SSRS)** [search-derived]:
- Free. iOS + Android. Latest version 5.4.0, updated March 2026.
- **App Store: 4.9 / 5 from 11,000+ ratings.** Google Play: 100,000+ installs. "Hundreds of thousands of active users" claimed.
- Real-time sewage discharge and pollution-risk alerts for **450+ locations** (some sources say 850 with water-quality info) across England, Wales and — since a 2025 expansion — **48 Scottish locations**, alerting when a CSO discharges within 2 km of a designated bathing water.
- Watchlists with push notifications; tide times; lifeguard info; **sickness reporting** (720 reports in a year); one-tap email to MP / water company CEO.
- Rivers included since 2021 (River Dee, Warleigh Weir, River Wharfe at Ilkley).

**Data HQ (`datahq.sas.org.uk`)** — the finding that changes the analysis:
- A **live national map of all CSOs across England, Wales and Scotland**, showing how many are active and where.
- **Full history for every recorded overflow in England since December 2024.**
- **Postcode-searchable.**
- Plus a data-investigations arm publishing analysis ("over 1,000 discharges in 3 days in the South West").

**Organisational strength:** record income **£3.36m in 2024**, up 16% [search-derived]. Described in trade press as *"the UK's most feared lobby."* Deep press relationships; every sewage story quotes them.

**Judgement:** the prior assessment described SSRS as covering "550+ locations with live sewage-discharge alerts". That understated them. Between SSRS (alerts on curated locations) and Data HQ (national all-overflow live map + history + postcode search), SAS now occupies both the alerting product *and* the national-map product.

### 4.2 SewageMap.co.uk — the technical incumbent

- Dr Alex Lipp (UCL) with Jonathan Dawe (BAS). Free, open-source.
- **Uniquely combines live CSO data with a hydrological flow model to highlight river reaches downstream of active spills** — the dilution/travel-time problem this brief identifies as the key gap.
- Originally Thames Basin; the repo now describes *"non-tidal rivers across England and Wales."*
- **~300,000 visitors in the past 12 months.** Funded/supported by River Action; academic publication + EGU 2026 abstract.
- **Powered by `POOPy` — MIT/GPL open source — which normalises all 11 company feeds, plus D8 flow-direction rasters for every company published on Zenodo (`zenodo.org/records/19709169`) with published MD5s.**

**This is the decisive competitive fact.** The single hardest, most defensible piece of engineering in this product category — catchment routing of live discharges — is not merely built, it is packaged, versioned, documented and free. Anyone can `pip install` it. That destroys the technical moat for everyone, including the incumbent who built it.

### 4.3 Everyone else, verified live

| Product | What it is | Overlap |
|---|---|---|
| **Top of the Poops** (`top-of-the-poops.org`) | James Richardson. Annual EDM + consented-discharge data by constituency, river, beach, shellfish area, water company. England, Wales, Scotland. 2025 data live. Also polls live Stream feeds (`services/stream/stream.py`). | Owns the **accountability/journalism** framing. |
| **The Rivers Trust "Is my river fit to play in?"** | ArcGIS Experience app. Annual summaries since 2019 **plus near-real-time alerts for England and Scotland**. 2025 annual data added ~April 2026. Backed by ~60 member trusts. | Owns the **conservation-sector map**. |
| **National Storm Overflow Hub** (Water UK) | Official industry map, 24h window. | The neutral baseline. |
| **Water-company apps/maps** | Southern Water **Beachbuoy**; South West Water **WaterFit Live** (bathing + storm overflow maps, river pilots on Dart and Tavy); United Utilities storm overflow map; Thames Water free email alerts. | Regional, self-serving, distrusted. Beachbuoy's "non-impacting" filter caused a public row. |
| **`defra-design/Water-Quality-Checker`** | **Defra alpha prototype, public on GitHub.** Postcode → overview combining bathing water, hydrology, storm overflows, pollution incidents, water chemistry, Met Office rainfall, EA recreation locations. GOV.UK Design System. Explicit provenance labels (Live / Demonstration / Not connected). Target users named as *"wild swimmers, paddleboarders, canoeists, anglers, dog walkers, parents, teachers, farmers, flood action groups"*. | **The proposed product, being built by government.** |
| **RiverSafe.uk** | Polls Thames Water API every 30 min, emails on upstream release start/stop. Beta. | The exact "upstream alerting" wedge — already exists for the Thames. |
| **Wild Open Water** (`wildopenwater.com`) | 15,000+ UK swim spots, live tides/temperature/quality from EA + NOAA + ECMWF + BODC, 40,000+ community reports, favourites + alerts. **Wild Pro £3.99/month.** | Owns **spot discovery + conditions + a working consumer subscription**. |
| **WildOtter** (iOS) | Swim spots, POIs, river levels. **£10/year.** | Same. |
| **NOWCA Wild** | Venue-network swim discovery. | Adjacent. |
| **British Rowing / Angling clubs** | Sewage email alerts, water-quality guidance (British Rowing published fresh Thames guidance July 2026). | Vertical channels already served. |
| **~10 hobbyist GitHub projects** | `sebbacon/sewage-alerts` (multi-company alerting, YAML config, postcodes.io), `DanielChicot/turd-alert` (Kotlin Multiplatform mobile), `Deveroonie/SewageData`, `bwgraves/SpillAlerts` (email alerts), `elidgdg/water-quality-checker` (wild-swim checker with upstream sites), `danielashare/stw-map-of-shame`, `rjmlaird` Leicestershire monitor, `a-jone5/nRtsom` (R package), `Walton-Viking-Scouts/thameswatch-model`. **Several dated March 2026.** | Proof the build is easy and the idea is obvious. Zero of them appear to have escaped hobby status — which is itself the signal. |

### 4.4 Does a wedge exist? Honest judgement

**One narrow gap is real.** Nobody combines *all four* of:
1. alerts on **arbitrary user-chosen points**, not a curated list of designated bathing waters;
2. **upstream-catchment awareness** (alert only for overflows hydrologically upstream, not merely within a radius);
3. **flow-aware travel-time / dilution weighting** from EA river data;
4. delivered as **push/email**, not a map you must remember to open.

SAS alerts fixed designated locations. SewageMap does 2 and partly 3 but is a map, not an alerting service. RiverSafe does 1, 2 and 4 but Thames-only and in beta. Wild Open Water does 1 and 4 but not 2 or 3.

**But it is not a wedge you can hold, for five reasons:**

1. **No moat.** POOPy + Zenodo D8 rasters make component 2 a weekend's work. Components 1, 3 and 4 are undergraduate exercises. A capable developer replicates you in a fortnight — which is precisely why nine of them already have repos.
2. **Trivially absorbed.** "Add a custom pin" is a sprint for SAS. Their SSRS already has watchlists and push infrastructure; they have the alerting engine, the users, and the brand.
3. **Government is entering.** Defra's alpha prototype is aimed at the identical audience with a superset of data sources and will carry a GOV.UK domain, free-forever funding and the presumption of authority. It may never ship — most alphas don't — but it is not a risk you can price.
4. **Two subscription competitors already price the ceiling.** Wild Open Water at £3.99/month and WildOtter at £10/year define what this audience will pay, and both bundle spot discovery, tides and community — features you would have to build *in addition* to the alerting.
5. **The gap is narrow because the underlying signal is weak.** A more precise alert on a fundamentally noisy proxy ("a pipe opened upstream") is a marginal improvement in *precision*, not a step-change in *usefulness*. The step-change requires s.82 sonde data. That is 2030+.

**Verdict on the brief's core question — is the real-time EDM angle genuinely different from the SATURATED bathing-water space, or the same space wearing a new hat?**

**It is largely the same space wearing a new hat.** The prior assessment reached AVOID for the right reason (SAS) but via the wrong dataset. Real-time EDM is a *better dataset* than weekly bathing-water samples — fresher, national, year-round, not limited to designated sites. But it feeds the **same product, for the same users, against the same incumbent**, and in the two years since s.81 bit, that incumbent has already built both the alerting app *and* the national live map on top of it. The 2/10 score stands. If anything the EDM angle is *more* crowded than bathing water, because it also attracts the campaigners (Top of the Poops, Rivers Trust, River Action), the academics (SewageMap/UCL), the water companies themselves, and now Defra.

---

## 5. Product definition

Included for completeness, and because §11's revival criteria need something concrete to point at. **This is what you would build if you overrode the recommendation.**

**Target user (narrow, deliberately):** the regular river user at a **non-designated** spot — the rowing club at a specific reach, the daily swimmer at a particular weir, the club angler on a named beat. Someone who returns to the *same* piece of water repeatedly and is therefore willing to configure a location once. Explicitly **not** the casual beachgoer — SAS owns that, comprehensively, and always will.

**The single "killer" feature:** **catchment-aware alerting on a point you choose.** Drop a pin anywhere. The service computes the upstream contributing catchment, watches every EDM in it, and notifies you when one starts — weighted by distance, current river flow and estimated travel time. Not "a spill happened within 5 km" but *"a discharge started 8 km upstream at 14:20; at today's flow the plume reaches your spot around 17:00."*

**In scope (MVP):**
- Ingest all 11 feeds; normalise; persist full event history.
- Drop-a-pin location creation; upstream catchment derivation via POOPy D8 rasters.
- Alerting: web push + email. Discharge-start, discharge-stop, and a daily digest.
- Per-spot page: current status, active upstream discharges with travel-time estimate, last 7/30/365-day discharge count, EA river flow, latest bathing-water sample if within range, antecedent rainfall.
- Explicit **data-confidence banner**: how many upstream monitors are `Offline`, when each company's feed was last successfully polled.
- Public spot pages, indexable, one per named river reach (SEO surface).

**Explicitly out of scope (MVP):**
- Native mobile apps (web push covers iOS 16.4+ and Android; native doubles the build and puts you in a store next to a 4.9★ incumbent).
- Spot discovery / directory (Wild Open Water has 15,000 spots and community reports; do not fight that).
- Tides, weather forecasts, water temperature (commodity; everyone has them).
- Community features, sickness reporting, social (SAS's sickness-report pipeline has campaigning value you cannot match).
- Historical league tables / accountability dashboards (Top of the Poops and Rivers Trust own this).
- Scotland/NI at launch (different regime; Scottish Water feed exists but adds surface area).
- Any predictive "will it be clean tomorrow" model. Unvalidatable without sonde data, and dangerous.

---

## 6. Technical plan

**Architecture — deliberately boring:**

```
[11 poller workers] ──► [normalise/adapter layer] ──► [PostgreSQL + PostGIS]
   every 10-15 min           per-company field maps        overflows, events,
   ArcGIS f=geojson          CRS: OSGB36→WGS84             spots, subscriptions
   + Thames OAuth                                                │
                                                                 ▼
[EA flood-monitoring poller] ──────────────────────► [alert evaluator]
   river level/flow, hourly                            upstream set ∩ new events
                                                       × flow-weighted travel time
                                                                 │
                                    ┌────────────────────────────┼──────────────┐
                                    ▼                            ▼              ▼
                             [Web Push (VAPID)]         [Email: SES/Postmark]  [Web app
                                                                                SSR + map]
```

- **Catchment derivation:** offline batch. Download POOPy's D8 rasters from Zenodo per company; on spot creation, trace the upstream contributing area and materialise the set of overflow IDs. This is a one-off per spot, cached — *not* a per-alert computation. Removes all runtime GIS cost.
- **Ingestion discipline:** poll `returnIdsOnly=true` first for a cheap change check where supported (Top of the Poops does this); full page-through with `resultOffset` on change. Persist raw payloads before parsing so schema drift is recoverable. **Per-company circuit breaker: on parse failure or 5xx, freeze that company's state as `unknown`, never as `not discharging`, and surface it in the UI.** This is a safety requirement, not a nicety.
- **Volume:** ~15,000 English overflows + Wales + Scotland ≈ 22,000 records. At 1000–2000 per page across 11 companies, one full cycle ≈ 150–200 HTTP requests. At 10-minute intervals ≈ **~25,000 requests/day**. Well within reasonable use of public feature services, but set a descriptive `User-Agent` with contact details, back off on 429/5xx, and be prepared to justify yourself.
- **Hosting:** single small VPS (2 vCPU / 4 GB) running app + Postgres/PostGIS + workers. Cloudflare in front. Self-hosted Protomaps/PMTiles basemap avoids per-view tile billing.

**Rough monthly running cost:**

| Item | Cost |
|---|---|
| VPS (Hetzner/Fly class, 2 vCPU / 4 GB) | £12–20 |
| Object storage (raw payload archive, rasters) | £2–5 |
| Transactional email (SES ~£0.08/1,000; Postmark from ~£12) | £1–15 |
| Web push (VAPID/FCM) | £0 |
| Map tiles (self-hosted PMTiles) | £0 (in VPS/storage) |
| Domain, TLS, backups, error monitoring | £5–10 |
| **Total** | **~£25–50/month at low volume; ~£80–150/month at ~50k MAU** |

Cost is not the constraint. Attention is.

---

## 7. Effort & timeline

One competent full-stack developer, working uninterrupted:

| Workstream | Dev-days |
|---|---|
| Ingestion: 11 adapters, normalisation, CRS, pagination, retries, raw archive | 7 |
| Catchment derivation: POOPy/D8 integration, upstream-set materialisation | 5 |
| Data model, history, backfill | 3 |
| Alert engine: subscriptions, dedupe, quiet hours, travel-time weighting | 5 |
| Delivery: web push (VAPID), email templates, unsubscribe, bounce handling | 4 |
| Web app: map, spot pages, onboarding, account | 8 |
| Confidence/offline-monitor UX, disclaimers, legal pages, cookie/GDPR | 3 |
| Deploy, monitoring, alerting-on-the-alerter, docs | 3 |
| **MVP total** | **~38 dev-days (≈ 8 working weeks)** |

Add **20–30 days** for native iOS/Android if pursued (not recommended).

**Ongoing maintenance — the part people underestimate.** Eleven third-party feeds you do not control, with observed history of silent org-ID migrations, resource renames and API-generation changes. Budget **1.5–3 days/month steady-state**, spiking on breakage. Plus: the annual EDM data release (late March) needs handling, the bathing season boundary (15 May / 30 Sep) changes data availability, and every schema surprise arrives as a user-visible incorrect alert. Realistically **~25–30 days/year** — a permanent, unglamorous tax on a product with no revenue.

---

## 8. Distribution

**SEO.** The valuable head terms are already owned — "sewage map", "is it safe to swim", "storm overflow map" return SAS, Rivers Trust, Top of the Poops and GOV.UK. The viable surface is the **long tail of named river reaches**: `sewage alerts River Wharfe Ilkley`, `is the River Dart clean to swim today`, `storm overflow near Warleigh Weir`, `[club name] rowing water quality`. Programmatic spot pages seeded from the **EA water recreation locations** dataset (~3,347 places) is the only credible SEO play, and it works precisely because it targets *non-designated* places the incumbents don't have pages for.

**Press hooks.** (a) The **annual EDM data release, late March** — the single biggest sewage news moment of the year, though SAS/Top of the Poops/Rivers Trust are the standing sources every desk already calls. (b) **Bathing season opening, 15 May.** (c) **Heavy-rainfall events** — reactive, high-volume, low-attribution. (d) **New bathing water designations** (13 new sites in 2026, six of them rivers). Realistically you would be a quoted afterthought, not the story.

**Communities to seed.** These are where the audience actually is:
- **Outdoor Swimming Society** (~200,000 claimed members) and its published UK wild-swim-group directory — the single highest-leverage list.
- **The Bluetits Chill Swimmers** — 150+ volunteer-led groups.
- **Per-river Facebook groups** — the real unit of organisation. Concrete examples surfaced in research: *Save the Teifi*, *Friends of the Somerset River Frome*. There are hundreds; each is a self-selecting, highly motivated micro-audience for one spot.
- **Reddit:** r/WildSwimming, r/UKhiking, r/unitedkingdom (sewage stories reliably trend).
- **Vertical bodies:** British Rowing (actively publishing Thames water-quality guidance July 2026), Angling Trust, Paddle UK, Swim England open-water.
- **Campaign orgs:** River Action UK, the ~60 local rivers trusts.

**The distribution problem in one line:** every one of these communities has *already been reached by SAS*, who arrived first, arrived as a charity they support, and asked them to download an app they rate 4.9.

---

## 9. Sustainability

| Option | Realistic assessment |
|---|---|
| **Donations / "buy me a coffee"** | Plausible at hobby scale. Covers £30/month hosting, not 30 days/year of maintenance. |
| **Consumer subscription (£3–4/mo or £10–12/yr)** | Precedent exists (Wild Open Water £3.99/mo; WildOtter £10/yr) — but both bundle discovery, tides and community. Charging for *alerts alone*, in a category where the beloved charity gives them away free, is a hard sell. |
| **B2B: clubs, event organisers, venues** | The most defensible: rowing/swim/triathlon clubs and open-water event organisers have a duty-of-care need and a budget line. But it is a small, slow, relationship-led B2B sale — a different business from the consumer app. |
| **Data/API licensing** | Undermined by the source data being free and POOPy being open source. |
| **Sponsorship / grants** | Grant funders in this space (Ofwat Innovation Fund, environmental trusts) fund charities and academics — i.e. SAS, Rivers Trust, UCL. You would compete for the same money from a weaker position. |
| **Advertising** | Audience too small; category too sensitive. |

**On competing commercially with a charity — the honest assessment.**

This matters more here than in most categories, and not merely as etiquette:

- **The audience is the charity's constituency.** These users don't just use SSRS, they *support* SAS — they email MPs through it, submit sickness reports to it, donate to it. Launching a paid competitor invites a specific and damaging reaction: *"someone is monetising sewage."* That reaction would be organised, public, and would occur in exactly the Facebook groups and subreddits you need for distribution.
- **You would be free-riding on their advocacy.** The s.81 duty that generates your data exists substantially because SAS and allied campaigners spent a decade forcing it into law. Building a paid product on data their campaigning created, in competition with their free tool, is defensible in principle and poor optics in practice.
- **The asymmetry is total.** They have £3.36m income, charitable status, 11,000 five-star reviews, and every environment correspondent's phone number. You have a VPS.

**A cleaner path exists if the goal is impact rather than revenue:** build the catchment-aware alerting as a free, open-source, MIT-licensed service — or better, contribute it upstream to POOPy/SewageMap or offer it to SAS. That achieves the user benefit without the reputational problem, and matches how everything else in this ecosystem has actually succeeded.

---

## 10. Safety & liability

**The core hazard.** Telling someone water is safe when it is not can put them in hospital. Waterborne illness from CSO-affected water is real and documented (SAS logged 720 sickness reports in a year; E. coli at a Thames rowing site reportedly reached 58× the "poor" threshold). A green indicator on your app that precedes a gastrointestinal infection is a foreseeable harm from a product whose entire purpose is informing that decision.

**Legal posture.** UK law imposes no general duty to provide accurate information, but negligent misstatement is available where a defendant assumes responsibility for advice a claimant foreseeably relies on. A product that says "safe to swim" and takes money for saying it is assuming responsibility far more clearly than one that displays a public dataset with caveats. Terms-of-service exclusions help but are weakened where the service is consumer-facing (Consumer Rights Act 2015) and cannot exclude liability for death or personal injury caused by negligence.

**Design rules — non-negotiable:**
1. **Never use the word "safe."** Never render a green tick, a "clean" badge or a numeric safety score. State facts: *"No discharge reported from 14 monitored overflows upstream in the last 48 hours. 2 upstream monitors are offline."*
2. **Report the absence of data as absence of data**, never as good news. Offline monitors, stale feeds and failed polls must be visible and must degrade the display, not silently pass.
3. **Show the epistemic gap explicitly and repeatedly:** discharge data says a pipe opened, not what is in the water. Agricultural and diffuse pollution are invisible to it.
4. **Timestamp everything** — per-company "last successfully updated" on every screen.
5. **Point to authority:** link EA Swimfo classifications and UKHSA guidance rather than substituting your own judgement.
6. **Log what each user was shown, when.** If someone gets ill and asks, you need the record.
7. **Insure it.** Professional indemnity / product liability before any paid tier.

**How incumbents handle it.** SAS is unusually candid: *"not a perfect system but the best possible solution given the data available"*; *"in the majority of cases we are unable to determine the location of the discharging pipe"*; *"confirmation of a sewage overflow operating doesn't always provide enough context to know when it is safe to enter the water."* Defra's prototype goes further with per-field provenance labelling (Live / Demonstration / Not connected / Placeholder) and an internal design rule to *"never silently override EA"* classifications. **A new entrant must be at least as conservative as both — which structurally caps how confident and therefore how compelling the product can be.** That is not a UX problem to solve; it is the honest shape of the domain.

---

## 11. Risks & kill criteria

**Risks, ranked:**

| # | Risk | Likelihood | Impact |
|---|---|---|---|
| 1 | **No differentiation survives contact with users** — they already have SSRS and see no reason to switch | High | Fatal |
| 2 | **SAS ships arbitrary-point alerts.** They have the users, the push infrastructure and the watchlist feature already | Medium-high | Fatal |
| 3 | **Defra's Water Quality Checker ships as a GOV.UK service** — free, authoritative, superset of data | Medium (alphas often die) | Fatal |
| 4 | **Feed breakage causes a wrong alert** — silent org-ID migration, schema change, stale data shown as green | High (observed history) | Severe (safety + trust) |
| 5 | **Licence turns out to restrict commercial reuse** for one or more companies | Medium (genuinely unverified) | Severe for any paid tier |
| 6 | **Maintenance tax exceeds motivation** — ~30 days/year on 11 uncontrolled feeds with no revenue | High | Fatal (slow) |
| 7 | **Reputational backlash** from monetising against a charity | Medium-high if paid | Severe |
| 8 | **A user gets ill after a green display** | Low per-user, non-trivial in aggregate | Severe |
| 9 | **Regulatory churn** — Ofwat abolition, Integrated Water Regulator, platform ownership moves | Medium | Moderate |
| 10 | **Another hobbyist ships first** — nine repos already visible, several active March 2026 | High | Moderate (commoditises, doesn't kill) |

**Kill criteria — stop if any of these occur:**
- SAS announces custom-location or arbitrary-pin alerting in SSRS.
- Defra's Water Quality Checker moves from alpha to a live GOV.UK beta.
- Fewer than **200 alert subscriptions** in the first 8 weeks after seeding 5+ named communities.
- Fewer than **25% of week-1 subscribers still active at week 8** (this is a habit product; retention is the only metric that matters).
- More than **3 days/month** on feed breakage for two consecutive months.
- **Any** incident where a user acted on a green display during an unreported discharge.
- Licence review finds commercial redistribution is not permitted for ≥2 companies and a paid tier was the plan.

**Revival criteria — reasons to revisit:**
- **s.82 sonde data becomes openly published with a national API.** This is the real unlock: continuous measured water quality converts the product from proxy-inference to measurement, and would reset the entire competitive field. Watch for the EA/Defra publication mechanism, not just the monitoring rollout. Earliest meaningful signal: 2029–2030.
- SAS discontinues or degrades SSRS (no current indication; the opposite).
- A specific vertical (rowing clubs, open-water event organisers) demonstrates willingness to pay for a duty-of-care tool — which would be a different, B2B product.

---

## 12. Open questions

**Must be answered before any commitment. Items 1–4 are blockers.**

1. **Licence, per company.** Load each Stream/ArcGIS Hub dataset page and read the actual licence field and any linked terms PDF. Is redistribution permitted? Commercial use? Attribution requirements? **Defra's own researchers refuse to assume this for comparable datasets.** Not verified here.
2. **Do the endpoints in §3.3 actually respond today?** Every URL is from third-party source code, corroborated but not personally observed. Run each with `?where=1=1&outFields=*&resultRecordCount=1&f=geojson` and record status, record count, field list, CRS. **Resolve the Southern Water conflict** (`XxS6FebPX29TRGDJ` vs `6qJmARkS2dt2IjVA`) — one is stale.
3. **Real update cadence, measured.** Poll all 11 feeds every 5 minutes for two weeks and measure actual `StatusChanged` latency per company against the statutory 1 hour. Compliance almost certainly varies; the product's credibility depends on the worst performer.
4. **Rate limits and acceptable-use.** No published limits found. Establish whether ~25k requests/day is acceptable, ideally by asking Stream/the companies directly rather than discovering it via a block.
5. **Does `f=geojson` return WGS84 for all companies, or do some return OSGB36 regardless of `outSR`?** Thames's proprietary API definitely returns eastings/northings. Verify per feed.
6. **Full field inventory per company.** I have three schema families; there are eleven feeds. Enumerate `outFields` for each from the FeatureServer metadata (`/FeatureServer/0?f=json`).
7. **Hafren Dyfrdwy** — separate feed, or folded into Severn Trent? Not found.
8. **Northern Ireland** — is there any NI Water EDM feed? Not found; NI is outside the Environment Act 2021 provisions.
9. **`defra-design/Water-Quality-Checker` status.** Is it a funded alpha with a route to beta, or an unfunded design exploration? This single fact materially changes the verdict. Check GOV.UK service assessments and the Defra digital roadmap; talk to the team if possible — it is a public repo.
10. **SAS's SSRS roadmap.** Have they publicly signalled custom-location alerting? Worth asking them directly — and that conversation might productively become a collaboration rather than a competition.
11. **Does anyone actually want alerts, or do they want reassurance?** Untested demand assumption. Ten interviews with regular users at non-designated spots (a rowing club, a swim group, an angling club) would settle it faster than any amount of building. **Do this before writing code.**
12. **Travel-time model validity.** SewageMap propagates discharges downstream but I could not verify whether it models *time* or only *connectivity*. If travel-time weighting is the differentiator, its physical validity needs review by someone who understands river hydraulics — an unvalidated time estimate presented with false precision is worse than none.

---

### Sources

Endpoints, schemas and per-company quirks were read from public source code: [AlexLipp/POOPy](https://github.com/AlexLipp/POOPy), [AlexLipp/sewage-map](https://github.com/AlexLipp/sewage-map), [top-poop/top-of-the-poops-site](https://github.com/top-poop/top-of-the-poops-site), [defra-design/Water-Quality-Checker](https://github.com/defra-design/Water-Quality-Checker), [sebbacon/sewage-alerts](https://github.com/sebbacon/sewage-alerts), [JonnyDawe/UK-Sewage-Map](https://github.com/JonnyDawe/UK-Sewage-Map), [DanielChicot/turd-alert](https://github.com/DanielChicot/turd-alert), [Walton-Viking-Scouts/thameswatch-model](https://github.com/Walton-Viking-Scouts/thameswatch-model), [a-jone5/nRtsom](https://github.com/a-jone5/nRtsom), [Deveroonie/SewageData](https://github.com/Deveroonie/SewageData).

Platform, competitive and regulatory context: [Stream storm overflows data](https://www.streamwaterdata.co.uk/pages/storm-overflows-data), [National Storm Overflow Hub](https://experience.arcgis.com/experience/cb89b71c060f40d394dca026445da4bc/), [Icebreaker One — Stream](https://ib1.org/water/stream/), [Ofwat open data in the water industry](https://www.ofwat.gov.uk/regulated-companies/open-data-in-the-water-industry/), [SAS Safer Seas & Rivers Service](https://www.sas.org.uk/water-quality/sewage-pollution-alerts/safer-seas-rivers-service/), [SAS Data HQ](https://datahq.sas.org.uk/sewage-data-hq/), [SSRS on Google Play](https://play.google.com/store/apps/details?id=uk.org.sas.saferseasservice&hl=en_GB), [SSRS on the App Store](https://apps.apple.com/gb/app/safer-seas-rivers-service/id1458786821), [SAS 2024 Annual Report](https://www.sas.org.uk/wp-content/uploads/2025/09/SAS_Annual_Report_2024-25_LQ_FINAL-SIGNED-1-1.pdf), [Top of the Poops](https://top-of-the-poops.org/), [Rivers Trust "Is my river fit to play in?"](https://experience.arcgis.com/experience/e834e261b53740eba2fe6736e37bbc7b), [UCL on SewageMap](https://www.ucl.ac.uk/mathematical-physical-sciences/news/2025/jul/sewage-map-england), [RiverSafe.uk](https://riversafe.uk/), [Wild Open Water](https://www.wildopenwater.com/), [South West Water WaterFit Live](https://www.southwestwater.co.uk/environment/rivers-and-bathing-waters/waterfitlive), [Rivers Trust on water-company live maps](https://theriverstrust.org/about-us/news/water-companies-launch-new-live-sewage-spill-maps), [BBC on the Beachbuoy row](https://feeds.bbci.co.uk/news/uk-england-hampshire-62924995), [EA 2025 EDM data release](https://wired-gov.net/wg/news.nsf/articles/Fewer+and+shorter+storm+overflow+spills+in+2025+new+monitoring+data+shows+26032026132500?open=), [EA EDM annual returns dataset](https://environment.data.gov.uk/dataset/21e15f12-0df8-4bfc-b763-45226c16a8ac), [EA Bathing Water Quality API](https://environment.data.gov.uk/bwq/), [EA flood monitoring API](https://environment.data.gov.uk/flood-monitoring/), [Water (Special Measures) Act 2025 explanatory notes](https://www.legislation.gov.uk/ukpga/2025/5/pdfs/ukpgaen_20250005_en.pdf), [RPS on sewage, sondes and s.82](https://www.rpsgroup.com/insights/water/sewage-sondes-and-section-82/), [Defra Water White Paper 2026](https://assets.publishing.service.gov.uk/media/698dd6c67149b335a315b348/Defra_Water_White_Paper_2026__with_correction_slip_.pdf), [Outdoor Swimming Society UK wild swim groups](https://www.outdoorswimmingsociety.com/uk-wild-swimming-groups/), [Outdoor Swimmer on participation growth](https://outdoorswimmer.com/news/open-water-swimming-has-doubled-in-popularity-since-2017/), [British Rowing on Thames water quality](https://www.britishrowing.org/2026/07/rowing-on-the-river-thames-staying-safe-when-the-water-quality-is-poor/).
