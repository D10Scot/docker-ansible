# Gritter Tracker & Name Archive — Plan & Decision Document

*Researched 31 July 2026. Prior assessment ranked this idea #5 (WEDGE) in the UK open-datasets catalogue.*

> **Read this caveat first.** All outbound HTTPS from the research environment was denied by egress policy. Every host I tried returned `HTTP 000` with a proxy `403` on `CONNECT`: `www.traffic.gov.scot`, `www.arcgis.com`, `services.arcgis.com`, `trunk-road-gritter-tracker-scotgov.hub.arcgis.com`, `gis.southlanarkshire.gov.uk`. **I was therefore unable to perform a single live fetch of any endpoint named in this document.** Everything below is reconstructed from search-indexed page content, vendor and press documentation, and GitHub code search. Where a claim is not live-verified I say so. Section 12 lists what must be checked with an actual `curl` before anyone commits a day of work.

---

## 1. Decision summary

**Verdict: BUILD LATER — start the licensing conversation and the name archive in August 2026, build the live layer in September–October, launch by 1 November 2026.**

**Confidence: MEDIUM.** Medium rather than high for one specific reason: I could not touch the live endpoint. The product's central assumption — that the gritter *name* is a queryable attribute on a machine-readable feed rather than a label baked into a map popup — is strongly suggested by the evidence but is **not proven**. That single unknown is the difference between a 20-day build and a dead end.

**Rationale.** The prior assessment's read was broadly right but two of its premises need correcting. First, the data position is *better* than "undocumented API": Transport Scotland publishes the tracker through an official ArcGIS Hub site (`trunk-road-gritter-tracker-scotgov.hub.arcgis.com`), and the ArcGIS Hub pattern normally carries download and GeoServices/WMS/WFS endpoints. Second, the licensing position is *worse* than "probably OGL": Traffic Scotland operates a deliberate, gated channel for programmatic data (DATEX II, approval required, `datex2@trafficscotland.org`) and explicitly reserves the right to block users whose usage degrades the service. The existence of a formal gated route materially undercuts any "it's a public map, help yourself" argument. Permission must be sought before production polling — that is a plan item, not a footnote. Against that, the wedge is real and I verified it hard: **there is no comprehensive national archive of UK gritter names, no aggregator, and zero open-source projects touching this data.** GitHub code search for `gritter traffic.gov.scot` returns three hits, all of them personal homepages linking the tracker as a "fun thing on the internet" — nobody has written a line of code against it. The build should not start today because the live feed is dormant until roughly November and you cannot develop, test, or launch against a feed that is off. Use the dormant months for the parts that need no live data.

---

## 2. The opportunity

**The viral phenomenon is unusually well-evidenced.** Scotland's gritter-naming tradition dates to 2006, when primary school pupils were first asked for suggestions. It has since become a reliable annual media event:

- The official ArcGIS tracker attracted **"well over a million visits in one winter season alone"** (Esri UK's own case-study figure), with Esri citing "huge spikes in usage… particularly during extreme weather or following publicity."
- A single Amey South-West Trunk Roads naming appeal drew **over 6,000 submitted names**. A separate appeal covered by BBC News drew **1,200+ entries**.
- Brands buy in unprompted: IRN-BRU named a gritter *Grits You Thru* (2020); Tunnock's named one *Caramelt Wafer* (2021).
- There are **100+ named Scottish gritters**, plus fleets across England and Wales — Surrey runs 39 named vehicles, East Riding of Yorkshire 21.
- Press treats it as an annual fixture: The Scotsman runs a refreshed "funniest Scottish gritter names" listicle every year (2025 additions: *Clearopathra*, *Den-ice Law*); BBC News has covered "the return of the gritter-naming phenomenon"; Google Maps Mania has covered the map at least twice, in December 2020 ("Gritty McGritface — Scotland's Live Gritter Map") and November 2025 ("The McGritter Tracker is Back!").

Verified names in circulation include *Gritney Spears*, *Sled Zeppelin*, *Skate Bush*, *Gritty McGritface*, *Basil Salty*, *Sir Andy Flurry*, *Chilly Connolly*, *Sir Grits Hoy*, *Skid Vicious*, *Sweet Child O' Brine*, *Yes Sir Ice Can Boogie*, *Robert Brrrrns*, *Snoel Gallagher*, *Spready Mercury*, *David Plowie*, *Nicole Saltslinger*, *William Wilberfrost*, *Thaw Enforcement*, *Walter The Salter*, *Usain Salt*, *Salter Clause*, *Bobby Moore Grit*, *Albus Dumblethaw*, *Thistle Do Nicely* (Scotland), *A Fine Gritty* (Norfolk), *Proper Job* (Cornwall).

**The utility need is separate and genuinely underserved.** UK road gritting is split by authority: Transport Scotland's operating companies grit trunk roads; councils grit everything else. A citizen asking "has my road been treated?" does not know or care which body owns their road, but must find and use a different map for each — if one exists at all. The demand is documented in the negative: councils cite "reducing the number of calls received by the contact centre" as the justification for buying trackers; Calderdale Council reinstated gritting on 70 roads after public complaints; law firms publish steady content on council liability for ungritted roads. There is no single place to answer the question nationally.

**Why now, and the timing trap.** "Now" is August. The live feed is off. The correct reading of "why now" is: *the naming competitions are announced in October and the season starts in November, so the window to build is the next ten weeks.* Miss it and you wait a full year. That is the actual urgency — not the data, the calendar.

---

## 3. Data deep dive

### 3.1 What I actually observed

**Nothing, directly.** Every fetch attempt failed at the network layer before reaching any server:

```
services.arcgis.com                                HTTP:000
www.arcgis.com                                     HTTP:000
trunk-road-gritter-tracker-scotgov.hub.arcgis.com  HTTP:000
gis.southlanarkshire.gov.uk                        HTTP:000
```

Proxy diagnostics recorded `connect_rejected … gateway answered 403 to CONNECT (policy denial)` for `www.traffic.gov.scot:443` among others. This is an environment restriction, not evidence about the endpoints. I did not attempt to route around it.

Note separately that **even with working network access, a July fetch would likely have shown a dormant or empty layer** — see seasonality below. Anyone verifying this should expect an empty feature set out of season and should not read that as a broken endpoint.

### 3.2 Architecture (from Esri UK's published case study — reliable, but vendor marketing)

- Esri UK consultants built **a bespoke API streaming from nine separate GPS tracking systems**, one per Transport Scotland operating company, unifying them onto a single live map. The operating companies include **Amey** (South-West and North-East trunk roads) and **BEAR Scotland** (100+ winter vehicles, 200+ trained operatives).
- Hosted and managed by **Esri UK's Managed Cloud Service** — i.e. this is a commercially hosted service Transport Scotland pays for, not a civic open-data platform. That framing matters for section 3.5.
- Public map: `https://www.traffic.gov.scot/gritter-tracker`
- ArcGIS Online item: `https://www.arcgis.com/home/item.html?id=dca3977ac9724a578130674f692a1315` ("Transport Scotland's Gritter Tracker")
- Web app viewer: `https://scotgov.maps.arcgis.com/apps/webappviewer/index.html?id=2de764a9303848ffb9a4cac0bd0b1aab`
- **ArcGIS Hub site: `https://trunk-road-gritter-tracker-scotgov.hub.arcgis.com/`** — described in indexed content as allowing users to "discover, analyze and download data in CSV, KML, Zip, GeoJSON, GeoTIFF or PNG formats, with API links available for GeoServices, WMS, and WFS." This is the single most important lead in the document and the first thing to verify.

### 3.3 Fields and behaviour (documented, not observed)

| Attribute | Evidence | Confidence |
|---|---|---|
| Current position of active gritters | Case study + map description | High |
| Direction of travel | "all trucks, and their direction of travel" | High |
| Historic trail ("snail trail") | Default 2 hours; zoom in for 12+ hours; one source says 24 hours | High on existence, low on exact window |
| Time road was last gritted | Google Maps Mania: trail "allows you to view the age range of when the road was last gritted" | Medium |
| **Vehicle name** | "anyone can access the app and **search for their favourite gritter by name**" | **Medium — inferred, not proven** |
| Depot / gritter count at depot | "see the number of gritters at a depot" | Medium |
| Supplementary layers | 3D terrain models, traffic-delay data | Medium |

**The name field is the load-bearing unknown.** A name search box in the UI implies the name is in the queried data, but Esri web apps can also filter client-side over a small preloaded set, or hold names in a popup template rather than a queryable attribute. If the name is not an attribute, the entire leaderboard concept requires a separate manual name-to-vehicle-ID mapping — which is still doable, but roughly doubles the ongoing maintenance.

### 3.4 Cadence and seasonality

Cadence is described only as "near real-time"; the actual refresh interval and any rate limits are **unknown**.

Seasonality — sources conflict slightly and both figures matter:

- **Live gritter tracker map: 1 November – 31 March** (The Scotsman).
- **Wider winter service / salt treatment information service: 1 October – 15 May** (Traffic Scotland; corroborated by Esri as "typically 1st October until 15th May").

Under either definition, **31 July 2026 is firmly out of season.** The feed should be assumed dormant today.

### 3.5 Licensing and terms — stated plainly

This is the part the prior assessment under-weighted, and it cuts against the idea more than it cuts for it.

**What is clearly open:**
- Transport Scotland states that information on its website (excluding logos) "may be used and re-used free of charge in any format or medium, under the terms of the **Open Government Licence**." That covers *website information*. It does not obviously extend to a commercially-hosted live telemetry service.
- **"Gritting Routes – Scotland"** is unambiguously, properly published open data — aggregated from Scottish local authorities by the **Improvement Service Spatial Hub** (`data.spatialhub.scot/dataset/gritting_routes-is`), mirrored to **opendata.scot** and **data.gov.uk**, with **OGC WFS and WMS endpoints**. Line geometry, two layers (road gritting and footpath gritting), quality-assured and dissolved by route name and local authority. Per-council equivalents exist for Fife, Aberdeenshire, Moray, Angus and others. **This is clean, licensed, national, and answers the "is my road on a gritting route?" question with zero legal ambiguity.**

**What is not clearly open — the live tracker:**
- Traffic Scotland's *documented* route for programmatic data is the **Developer Hub**, which offers a **DATEX II feed to approved subscribers only**: users "need to be registered and approved," with applications via the developer portal and `datex2@trafficscotland.org`.
- Stated conditions include: **credit Traffic Scotland as the data source**, and **Traffic Scotland "reserves the right to remove/block users if their use of data is causing a degradation of the Traffic Scotland service."**
- The gritter tracker **does not appear as a dataset on data.gov.uk or opendata.scot.** Searches for Scottish gritting open data surface the *routes* datasets repeatedly and the live tracker never. Absence of an open-data listing for a live feed, when the same publisher lists other datasets diligently, is meaningful.

**Plain assessment.** The existence of a deliberate, approval-gated channel for machine access is the decisive fact. When a public body builds a front door and asks you to knock, quietly using the side window is not defensible on an "it's OGL" theory — and the express reservation of the right to block degrading users is precisely the clause you would be relying on nobody enforcing. The ArcGIS Hub *may* resolve this cleanly: if that Hub site exposes the layer with a download button and an OGL licence field, the layer is published open data and you are fine. That is unverified and is open question #2.

**Therefore, as a plan item, not a caveat: seek permission first.** Before any production polling, email Transport Scotland and `datex2@trafficscotland.org` stating exactly what you intend to build, the poll frequency, that you will cache centrally so end-user traffic never reaches their service, and that you will attribute prominently. This is a novelty public-interest project promoting their own work — the odds of a positive or at least neutral response are good, and the cost of asking is one email. **Do not scrape the vendor portals** (Exactrak, TrueViewVisuals) under any circumstances; those are commercial products of private companies and the terms position there is far sharper than with a public body.

**Fallback if permission is refused:** the product still exists. Gritting Routes (OGL), the name archive (compiled from council press releases and FOI), and the council ArcGIS REST services that are already published openly together carry roughly 70% of the value. Only the live Scotland trunk-road layer is lost.

---

## 4. National scope assessment

The prior assessment framed this as Scotland-only. **A national product is the stronger option** — but it is harder than it looks, and the difficulty is vendor fragmentation rather than volume.

### 4.1 Authorities with public gritter trackers or named fleets (all named below were verified as existing via indexed council/press pages)

**Scotland:** Transport Scotland (trunk roads, Esri), West Lothian, Dumfries & Galloway, South Lanarkshire, North Lanarkshire, Stirling, Moray, Orkney, East Dunbartonshire, Ayrshire Roads Alliance (East + South Ayrshire), Aberdeenshire, Fife, Angus.

**England:** Lancashire ("Lancashire Gritting Live", 18-hour blue-arrow treated-route trail), Leeds, Essex (Essex Highways), Hertfordshire, Westmorland & Furness, St Helens, Suffolk, Surrey (39 named vehicles), Cumberland, Shropshire, Oxfordshire, BCP (Bournemouth Christchurch & Poole), Kirklees, Barking & Dagenham, East Riding of Yorkshire (21 named gritters), Cheshire West & Chester, Sefton, Manchester City Council, Gateshead, Brighton & Hove, Sunderland, Derbyshire, Calderdale, Lewisham, Royal Greenwich, Harrow, Norfolk, Cornwall. Devon has tendered for a system (Find a Tender notice CP2306-22, "Winter Service Vehicle Fleet (Gritter) Tracking System").

That is **40+ authorities** identified from a non-exhaustive search. The true national figure is plainly higher; naming and tracking are near-universal practice among UK highway authorities now.

**National Highways** (England's strategic road network) — I found gritter fleet coverage in trade press but **no public live tracker equivalent to Traffic Scotland's**. This is a notable gap: England's motorway network has no public gritter map. Unverified whether one exists behind a different name.

### 4.2 The vendor landscape — this is what determines feasibility

Council trackers are not bespoke. They cluster into three technology families, and the family determines whether aggregation is easy, hard, or off-limits:

1. **Esri / ArcGIS REST (easy — machine-readable, publicly served).** Confirmed public REST service directories include:
   - `gis.southlanarkshire.gov.uk/arcgis/rest/services/Gritting/` — with `GritterTracking`, `GritterTrackingGritters` (layer *"Gritter – current position"*, point geometry, carrying **gritter direction and driving status**) and `GritterTrackingMonitor` (layer *"Gritter – previous movements"*)
   - `mapservices.leeds.gov.uk/arcgis/rest/services/Public/Gritting/MapServer`
   - `gis.gateshead.gov.uk/server/rest/services/GrittingRoutes_MIL1/MapServer`
   - `gis.lancashire.gov.uk/arcgis/rest/services/Hosted/Gritting_Bins/FeatureServer`
   - `gis.brighton-hove.gov.uk/server/rest/services/Highways/Highways_GritBins/FeatureServer`
   - `arcgis.sunderland.gov.uk/arcgis/rest/services/My_Nearest_Data/Public_Grit_Bins/FeatureServer`

   South Lanarkshire's schema is a near-perfect template: current position + previous movements + driving status, in a standard, self-describing, paginated ArcGIS REST format. Write one adapter and it works for the whole family.

2. **TrueViewVisuals / RoadsOnline "Gritter Tracker" (`grittertracker.co.uk`) — commercial, multi-tenant.** Clients include **Ayrshire Roads Alliance** (`ara.grittertracker.co.uk/ARA/Winter/Home/Map`), **Dumfries & Galloway**, and **Manchester City Council**. Marketed as "a complimentary bolt-on to existing GPS vehicle tracking… citizen access on web, mobile, smart speaker, and in-car."

3. **Exactrak "Where Is My Gritter?" (`exactrak.co.uk/where-is-my-gritter/`) — commercial, and already a partial aggregator.** A multi-council public portal integrating "live gritter tracking data from **Navtrak** via an API." Exactrak (founded 2004, West Midlands) explicitly markets it to authorities as a shared hub they can link to instead of building their own, and explicitly pitches fleet-naming as the engagement hook.

### 4.3 Feasibility verdict

**Aggregate the ArcGIS family; link to the rest.** Family 1 is genuinely straightforward — a single adapter, a config file of endpoints, and each new council is an afternoon. Families 2 and 3 are commercial products with no published API, and scraping them is both technically brittle and a materially worse terms position than dealing with a public body.

So the honest national scope is: **Transport Scotland (permission pending) + the ArcGIS-published councils (open) + a complete national *name archive* and *routes* layer (open) + outbound links to vendor-run trackers.** That is still, by a distance, the most complete national picture anyone has assembled — because the name archive and route data are national even where live positions are not.

**Recommendation: national product, staged coverage.** Ship 5–8 live authorities well rather than 30 badly. The name archive carries national coverage from day one and is the thing that actually goes viral.

---

## 5. Competitive landscape

**Verified alive:**

| Incumbent | Status | What it covers | Gap it leaves |
|---|---|---|---|
| Traffic Scotland Gritter Tracker | Alive, seasonal (Nov–Mar), 1M+ visits/season | Scottish **trunk roads only**; live map with name search | No leaderboard, no history, no archive, no cross-year memory, no local roads, dead 7 months a year |
| ~40+ individual council trackers | Alive, seasonal | One authority each | Fragmented; citizen must know which authority owns their road |
| Exactrak "Where Is My Gritter?" | Alive | Multi-council, but **only Exactrak/Navtrak telematics clients** | Vendor-locked; no names archive; no gamification; not a consumer brand |
| TrueViewVisuals `grittertracker.co.uk` | Alive | Ayrshire Roads Alliance, D&G, Manchester | Same vendor-lock limitation |
| The Scotsman gritter-name listicles | Alive, refreshed annually | Scottish names, editorial prose | Static article; not filterable, not searchable, not national, goes stale |
| Tempcover "UK's favourite gritter names" | Alive | Content-marketing listicle by an insurer | SEO play, not a product; no data behind it |
| Google Maps Mania | Alive (Dec 2020, Nov 2025 posts) | A **blog covering** the maps | Not a product — this is a *distribution channel*, and proof of recurring appetite |
| @ukgritters, @Yorkshire_Grit, council winter accounts (e.g. @KirkleesWinter) on X | Alive | Grassroots enthusiasm and operational updates | No central hub; no archive |

**Verified absent — and this is the finding that matters:**

- **No comprehensive national gritter-name archive exists.** Searches for a database of every UK gritter name return only per-council press releases and per-region listicles. Each council runs its own competition and publishes its own list; nobody has ever assembled them.
- **Zero open-source projects.** GitHub repository search for "gritter tracker" returns 35 results, every one of which is a fitness or habit app called "Grit". GitHub code search for `gritter traffic.gov.scot` returns exactly **three** hits — a personal blog listing it under "things on the internet that I like", a podcast show-notes file, and a personal homepage's links section. Nobody has written code against this data. Code search for `"gritter" arcgis FeatureServer query` returns **zero** results.
- **No consumer app.** No gritter app in the iOS or Android stores; Transport Scotland's "app" is a web app.

**The wedge, restated precisely:** the incumbents own *live position, one authority at a time, five months a year*. Nobody owns **memory** — the cross-year, cross-authority, structured record of which gritters exist, what they are called, who named them, when they appeared, and which are the best. Memory is the half that works in July.

---

## 6. Product definition

**Target user — two, and they need different front doors:**

- **The sharer** (primary, drives all growth). Anyone amused by *Sled Zeppelin*; UK-wide and internationally curious. Wants a list, a ranking, an argument, and a shareable image. Peaks late October (naming competitions) and on snow days.
- **The checker** (secondary, drives retention and legitimacy). A driver, parent, or cyclist at 6am on an icy morning asking "is my route treated?" Wants a postcode box and a fast answer. Cares nothing for puns.

**MVP — in scope:**

1. **The National Gritter Name Archive.** Every named UK gritter, by authority, by year, searchable and filterable. Structured data, not prose. Each gritter gets its own permanent page (`/gritter/sled-zeppelin`) with authority, depot, year introduced, naming origin, and — where a live feed exists — whether it is out right now. *This is the asset. Everything else is built on it.*
2. **Postcode lookup → "your gritters".** Enter a postcode, get the authority responsible, its named fleet, whether your road is on a gritting route (from OGL Gritting Routes data), and a link to the live tracker if one exists.
3. **Live map (staged coverage).** Transport Scotland (subject to permission) plus the ArcGIS-published councils. Current positions, treated-in-last-N-hours trails, prominent attribution to each source.
4. **The leaderboard.** Ranked by public vote, plus derived stats where live data allows: most-active gritter this season, most miles treated, most nights out.
5. **Hall of Fame.** Retired and historic names, preserved. Councils delete this stuff; being the only place it survives is a durable moat.
6. Share cards — auto-generated OG images per gritter and per authority.

**Explicitly out of scope for MVP:**

- Scraping Exactrak or TrueViewVisuals portals. Not now, not later, absent a partnership.
- Native mobile apps. A fast PWA is correct for a five-month seasonal product.
- Grit bin locations. Available from several councils but a different product with a different audience.
- Real-time push alerts ("your road was just gritted"). Attractive, but implies a reliability promise you cannot keep on top of third-party feeds you don't control, on the exact night it matters most. Do not promise safety-critical information.
- Weather forecasting or road-surface-temperature prediction.
- Long-term per-vehicle GPS replay (see §7 on driver privacy).
- Coverage-gap accusations ("this road was missed"). Tempting and journalistically juicy, but you would be publishing implicit negligence claims from an incomplete third-party feed. Absent gritting data does not mean absent gritting.

**The single killer feature: the annual "Britain's Best Gritter Name" knockout bracket.**

A seeded, 64-name, public-vote tournament run each January across the whole national archive. Every round produces a shareable image, a fresh reason to return, a reason for each losing council's local paper to write an aggrieved story, and — critically — a **result**: a named annual champion. Journalists cannot write about a database, but they can always write about a winner. It converts a static archive into an annual event, it runs entirely on data you own, and it needs no live feed at all. It is the highest-leverage thing in this document.

---

## 7. Technical plan

**Architecture — static-first, single-poller, cache-everything.**

```
[ upstream feeds ]        [ ingest ]              [ serve ]
Transport Scotland ArcGIS ─┐
Council ArcGIS REST ×N ────┼─► poller (cron)  ──► Postgres/PostGIS ──► API (cached) ──► CDN ──► PWA
Gritting Routes WFS (OGL) ─┤   60–120s in season      │                                        (MapLibre GL)
Name archive (manual/FOI) ─┘   off entirely off-season└─► nightly static rebuild of archive pages
```

**Polling and courtesy — this is a design constraint, not an optimisation.** The single greatest risk to the product is being blocked, and Traffic Scotland's terms reserve exactly that right for usage that degrades their service. So:

- **One** origin poller. Never let a client request touch an upstream. Every visitor is served from CDN cache.
- 60–120s interval **during season only**; the poller does not run April–September.
- Descriptive `User-Agent` including a contact URL and email, so anyone investigating traffic can find you in ten seconds.
- Honour `Cache-Control`; conditional requests; exponential backoff; a hard circuit breaker that disables a source after repeated errors and alerts rather than retrying.
- Publish the polling policy on the site. If asked to stop, stop the same day.

This posture is also the argument to make when seeking permission: a cached aggregator with 50,000 users generates *less* load on Transport Scotland than 50,000 users hitting their map directly.

**Storage — two schemas with different lifecycles.**

- `vehicles` — slowly changing: name, authority, operator, depot, first_seen, last_seen, retired_at, naming_origin. Tiny, permanent, hand-curated where needed. This is the crown jewels; back it up properly and publish it as open data yourself.
- `positions` — time-series, high volume. **Downsample aggressively:** full resolution 7 days → snap to route segments with a "last treated" timestamp for 90 days → daily coverage aggregates thereafter. Raw GPS is discarded.

**Driver privacy — take this seriously.** A continuous GPS trace of a *named, individually identifiable* vehicle is effectively a trace of a named driver's shift. Retaining that indefinitely on a novelty website is a genuine data-protection problem and would be an embarrassing story. Mitigations: aggressive downsampling as above; no per-vehicle historical replay beyond 7 days; no journey-time or speed derivation; no dwell-time analysis. Publish the retention policy.

**Frontend.** Astro or Next.js with static generation for the archive (thousands of cheap, fast, SEO-friendly pages), a small client island for the live map. MapLibre GL with a self-hosted Protomaps basemap or OS Open Zoomstack — avoids per-tile pricing entirely, which matters when a viral day multiplies traffic 50×.

**Hosting and cost.**

| Component | Choice | Off-season | In-season | Viral day |
|---|---|---|---|---|
| Static site + CDN | Cloudflare Pages (free egress) | £0 | £0 | £0 |
| Poller | Cloudflare Worker cron / £4 VPS | £0 | £4 | £4 |
| Database | Managed Postgres small / SQLite + Litestream | £0–7 | £7–15 | £15 |
| Basemap tiles | Self-hosted Protomaps on R2 | £0–2 | £2–5 | £5–15 |
| Domain, email, monitoring | — | £2 | £2 | £2 |
| **Total** | | **~£2–10/mo** | **~£15–30/mo** | **~£40 spike** |

**Roughly £150–250 for an entire winter season, and near-zero for the seven months off.** Cloudflare's free egress is what makes a viral spike survivable; on a per-GB-egress host a single front-page day could cost more than the whole season. Choose accordingly.

---

## 8. Effort & timeline

**MVP, one competent developer:**

| Work | Days |
|---|---|
| Name archive: schema, data collection (council sites, press releases, FOI where needed), 40+ authorities | 5–7 |
| Static site, archive pages, search/filter, SEO, OG image generation | 4–5 |
| Postcode → authority → routes lookup (Gritting Routes WFS + boundaries) | 2–3 |
| ArcGIS ingest adapter + 5 council integrations | 4–6 |
| Transport Scotland live layer (*if permitted and if the name field exists*) | 3–5 |
| Leaderboard, voting, bracket mechanics | 3–4 |
| Polish, monitoring, deployment | 2–3 |
| **Total** | **23–33 dev-days** |

Call it **five to seven weeks part-time**, or **four weeks full-time**. Note this is meaningfully more than the prior assessment's "very low technical bar" implies — because the effort is not in the code, it is in the *data collection* for the archive. Assembling 40+ councils' name lists by hand is the single largest line item and cannot be automated. It is also exactly what makes the result defensible.

**Ongoing maintenance:** ~2 days each October (new names, new competitions, re-verify endpoints after summer changes); ~1–2 days/month November–March (feeds break, councils reorganise sites); near zero April–September.

**Seasonal build calendar:**

| When | What | Depends on live feed? |
|---|---|---|
| **Aug 2026** | Send permission request to Transport Scotland / `datex2@trafficscotland.org`. Verify the ArcGIS Hub licence position. FOI/email councils for name lists. Build the archive data set. Register domain. | No |
| **Sept 2026** | Build the site, archive, postcode lookup, routes layer. Build the ArcGIS ingest adapter and test it against council services that stay online year-round. | No |
| **Early Oct 2026** | **Soft launch the archive.** Naming competitions are announced now — this is a real traffic peak that needs no live data. Publish a "Name Our Gritters 2026" tracker page collating every open competition nationally. | No |
| **Mid–late Oct 2026** | Live feeds return. Integrate, test against real moving vehicles, fix what the dormant-season testing missed. | Yes |
| **1 Nov 2026** | **Full launch** with live map, timed to the season opening. Press push. | Yes |
| **Dec 2026** | "Gritter names of 2026" content moment; ride the first cold snap. | Partial |
| **Jan 2027** | **Run the Best Gritter Name bracket.** Peak moment. | No |
| **Mar 2027** | Season wrap: stats, "most active gritter", hall-of-fame inductions. Poller off. | No |

The critical scheduling insight: **the archive launches before the feed comes back.** October's naming-competition news cycle is a free launch window that does not depend on the risky data at all — so if permission is refused, you have already launched.

---

## 9. Distribution

This is the strongest asset in the whole idea and should be planned as carefully as the code.

**Viral mechanics, ranked by expected return:**

1. **The January bracket.** Knockout tournaments are the most reliably viral format on the UK internet, and this one produces a shareable image every round plus a citable annual champion. Seed it by public nomination so people arrive already invested.
2. **"Your local gritter is ___" postcode share card.** Personalised, instant, image-based. Every share is a rich preview card carrying the brand. This is the single highest-conversion mechanic on a snow morning.
3. **The annual award press release.** Issue a proper release naming Britain's Best Gritter Name of the Year. Journalists need a *result* to report; hand them one, with quotes and an image, on a slow news day in January.
4. **Local-press multiplication.** This is a national story told 40 times locally. Each council's names are a *local* story for the local BBC/ITV region, the local daily, and the council's own comms team — who will happily amplify because it flatters them. Forty small pickups beat one national.
5. **Cold-snap "who's out tonight" page.** A single URL that answers "are the gritters out?" — the thing people share into WhatsApp groups at 6am.
6. **Publish the archive as open data yourself.** A downloadable CSV of every UK gritter name makes you the citable source, earns backlinks from journalists and Wikipedia, and costs nothing. This is the most durable SEO asset available.

**Press targets:** BBC Scotland and BBC local regions, STV, The Scotsman (already runs this beat annually), Daily Record, Metro, LadBible/UNILAD, The Poke, and — near-certain pickup given two prior posts on this exact subject — **Google Maps Mania**. Secondary: Boing Boing, Kottke, b3ta, Hacker News (the data-engineering angle only, not the puns).

**SEO terms to own:** `gritter names`, `gritter names 2026`, `funny gritter names`, `Scotland gritter names`, `gritter tracker`, `[council] gritter tracker` × 40, `has my road been gritted`, `is my road gritted [town]`, `name our gritters`, `gritter tracker live`. The current holders are stale listicles from The Scotsman and Tempcover — beatable, because a structured, always-current, filterable, per-gritter-page database out-competes a prose article that is rewritten once a year on every ranking signal that matters.

**Communities:** r/Scotland, r/CasualUK, r/unitedkingdom, r/MapPorn, r/dataisbeautiful; Bluesky UK weather/transport circles; X (@ukgritters, @Yorkshire_Grit, council winter accounts); Facebook local community groups — unglamorous but overwhelmingly the largest channel for the *utility* audience on a snow day; Mumsnet (school-run gritting anxiety is a real recurring thread).

---

## 10. Sustainability

**State it plainly: this is not a business.** A product with five usable months, a novelty core, and a public-sector data dependency will not produce meaningful revenue. Budget it as a reputation and portfolio asset that must cost less than a few hundred pounds a year. Anyone modelling this as income is modelling wrong.

Options, ranked by realism:

1. **Cost recovery only (recommended).** Hosting is ~£150–250/season. A "buy the server a bag of salt" Ko-fi link on a site with genuine December traffic plausibly covers it. Honest, on-brand, zero overhead.
2. **Sponsorship of the annual award (the one credible revenue line).** **IRN-BRU and Tunnock's have already literally paid to have gritters named after their products.** That is not a cold prospect list — it is documented, demonstrated appetite for exactly this association. A £1,000–5,000 seasonal sponsorship of "Britain's Best Gritter Name, in association with —" is genuinely plausible for a site with real Dec–Jan traffic and press coverage. Pursue only *after* one winter of demonstrated numbers; you have nothing to sell until then.
3. **Merchandise.** Print-on-demand mugs and tea towels of gritter names have an obvious Nov–Dec gift market. **But check the IP position first** — the names are outputs of council-run public competitions and may be council property or subject to entrant terms. Editorial republication is almost certainly fine; commercial merchandise is not obviously fine. Do not skip this check.
4. **Display advertising — don't.** Seasonal traffic at this scale earns perhaps £100–400 across a whole winter while measurably degrading a product whose entire appeal is charm.
5. **B2B white-label trackers for councils — out of scope.** A real market (Exactrak and TrueViewVisuals are in it) but a completely different company, requiring procurement relationships and competing with entrenched telematics vendors.

**Against a seasonal curve:** expect roughly 70–80% of annual traffic in a six-week Dec–mid-Feb window, concentrated into a handful of cold snaps; a secondary October peak from naming competitions; and 5–15% of peak in the April–September trough, sustained entirely by the archive's evergreen search traffic. That trough is enough to keep SEO alive and the domain warm. It is not enough to sustain anything requiring monthly revenue. Design the cost base for the trough and the *infrastructure* for the spike.

---

## 11. Risks & kill criteria

| # | Risk | Likelihood | Impact | Mitigation | Kill criterion |
|---|---|---|---|---|---|
| R1 | Live endpoint changed, moved, or access-restricted without notice | **High** | High | Permission-first; adapters isolated behind one interface; graceful degradation to archive + routes | None — survivable by design |
| R2 | **Terms breach / being blocked.** Traffic Scotland expressly reserves the right to block degrading users | Medium | **High** (reputational as well as technical) | Ask before polling; single cached poller; identifiable UA; published policy; stop on request | If Transport Scotland refuses and offers no alternative → **drop the live Scotland layer entirely**, keep everything else. Do not proceed regardless. |
| R3 | The gritter **name is not a queryable field** | Medium | **High** — the leaderboard depends on it | Verify before building (§12 Q5); fallback is a manual vehicle-ID→name map | If names require manual mapping for >200 vehicles across >5 authorities, cut live gamification and ship the archive alone |
| R4 | Seasonality caps the ceiling | **Certain** | Medium | Near-zero cost base; October archive launch; January bracket; evergreen archive SEO | None — accept it |
| R5 | Transport Scotland adds a leaderboard themselves | Low–Medium | Medium | They cannot go national — they own trunk roads only. National scope and cross-year memory are the defensible parts | If they ship a *national, cross-authority, historic* archive, stop. (Unlikely: outside their remit.) |
| R6 | Vendor-portal legal exposure (Exactrak, TrueViewVisuals) | Low *if* the rule is followed | High | **Never scrape them.** Link out, or partner | Immediate stop if any scraping is contemplated |
| R7 | Driver privacy / data-protection complaint over retained named-vehicle GPS | Low–Medium | High | Aggressive downsampling; 7-day replay limit; no speed/dwell derivation; published retention policy | Complaint received → purge and reduce retention immediately |
| R8 | Aggregation fragility — 40 councils, 40 breakages | High | Low–Medium | Ship 5–8 sources well; circuit breakers; per-source status page showing what's stale | None |
| R9 | **It simply doesn't catch fire** | Medium | Medium | Distribution planned before build; October launch window | **If the Nov 2026–Feb 2027 season delivers <20,000 sessions and no press pickup, do not build a second winter.** Leave the archive up as a static asset and walk away. |

---

## 12. Open questions

**These must be answered before committing development time. Questions 1–5 are blocking.**

1. **Everything here is un-fetched.** Network egress was fully denied in this environment (`HTTP 000` / proxy `403` on `CONNECT`) for every host tried. **First action: actually `curl` `https://trunk-road-gritter-tracker-scotgov.hub.arcgis.com/`, the ArcGIS item `dca3977ac9724a578130674f692a1315`, and `https://gis.southlanarkshire.gov.uk/arcgis/rest/services/Gritting/?f=json` from an unrestricted network.** Expect a dormant/empty live layer in July; that is not a failure. Budget half a day; it changes the confidence level of this entire document.
2. **Does the ArcGIS Hub expose the live gritter layer for download/API, and what licence field does it carry?** If it shows a download button and an OGL licence, the whole §3.5 problem dissolves and the verdict strengthens to BUILD. If the Hub is a bare landing page with no data, the permission route becomes mandatory. **This is the highest-value single check in the document.**
3. **The exact service URL, layer IDs, and field schema for the Scotland live layer.** Unknown. Notably, *nobody on GitHub has ever called it* — so there is no shortcut and no precedent to copy.
4. **Poll cadence and rate limits.** Unknown. Ask as part of the permission request rather than probing for them.
5. **Is the gritter name a queryable attribute or a UI-layer label?** The map has name search, which is suggestive but not proof. If it is only in a popup template, the leaderboard needs a manual mapping layer. See R3.
6. **Will Transport Scotland grant permission, and on what terms?** Unknowable without asking. Cost of asking: one email. Send it in August.
7. **How many of the 40+ council trackers are actually machine-readable?** I confirmed six public ArcGIS REST services. A proper survey — visiting each authority's tracker and checking the network tab — is roughly two days of work and should precede any promise of national live coverage.
8. **Does National Highways run a public gritter tracker for English motorways?** I found none. If confirmed absent, that is a notable coverage gap worth stating publicly — and possibly worth asking them about.
9. **Can gritter names be used commercially (merchandise)?** They are outputs of council-run public competitions. Editorial reuse is almost certainly fine; commercial reuse is unclear. Resolve before selling anything.
10. **Would Exactrak or TrueViewVisuals partner rather than compete?** Both already aggregate multiple councils and both market public engagement as their selling point. A data-sharing arrangement would give near-complete national coverage in one conversation. Worth one email each — potentially the highest-leverage unexplored option in this document.
11. **What fraction of the official tracker's 1M+ seasonal visits could a third party realistically capture?** Unknown, and the 1M figure belongs to the incumbent with all the official promotion behind it. Do not plan on it.
