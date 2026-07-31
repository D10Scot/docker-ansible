# Planning Constraints Checker — Plan & Decision Document

*Research date: 31 July 2026. Scope: planning **constraints/policy** data (conservation areas, Article 4 directions, TPOs, listed buildings, flood zones, green belt, national landscapes) — explicitly **not** planning-application alerts, which the prior assessment correctly found saturated.*

**Research access caveat, stated up front:** this session's egress policy blocked all direct HTTP to `planning.data.gov.uk`, `*.gov.uk`, and every commercial site. Only `raw.githubusercontent.com` / the GitHub API and a web-search tool were reachable. I therefore could **not** execute a live API call. Instead I verified the platform against its own authoritative source repositories — `digital-land/specification` (the dataset registry), `digital-land/config` (the authoritative collection configuration, i.e. every registered data source per authority), `digital-land/organisation-dataset`, and `digital-land/digital-land.info` (the FastAPI application that *is* the API) — and cross-validated the derived coverage numbers against MHCLG's own published figures. Where a number is derived rather than observed live, it is marked. One cross-check came out exactly right (see §3.4), which gives reasonable confidence in the method. Section 13 lists what remains unverified.

---

## 1. Decision summary

**Verdict: DON'T BUILD** (as scoped — a consumer "what planning constraints affect this property" checker).

**Confidence: High** on the competitive finding and the data facts; **Medium** on the durability of the incumbents.

**Rationale.** The prior research ranked this #4 principally because "consumer-grade tools are thin relative to B2B proptech incumbents." That premise is false as of mid-2026 and is the single thing that changes the verdict. A fresh search surfaces **at least ten live, free, consumer-facing UK planning-constraint checkers** — planningconstraints.com (free unlimited checks over 30+ datasets, £9.99 PDF report), Mayfair Studio's free permitted-development checker (constraints + PD eligibility + build-cost estimate, ~90 seconds, no signup), PlanningConsult/Planning Handbook (free 15-layer screen, all UK LPAs), theplanningconsultant.com, BILTD, conservationareachecker.com, Vestige, PlanWiser, PlanSavvy and whatcanibuild.co.uk. The reason for this crowding is structural and permanent: MHCLG's API accepts a raw `latitude`/`longitude` and returns intersecting constraint polygons across every dataset in one request, so the entire spatial-analysis burden — normally the hard part and the moat — is carried by the government for free. What remains is a form, a map and copywriting. Barrier to entry is roughly a weekend, which is exactly why the market looks the way it does, and why any entrant is immediately commoditised. The £9.99 report price point is already set by an incumbent, so monetisation starts as a race to the bottom.

The genuinely under-served problem is not *"which polygons touch my house"* — that is solved and free — it is *"what does that mean for the thing I want to build"*, which is **legal interpretation, not data** (§4), and which carries real professional-negligence exposure (§11). Meanwhile the two datasets that most determine that answer, Article 4 directions and TPOs, sit at **38%** and **28%** authority coverage respectively (§3.4) — so the tool cannot answer its own headline question reliably for roughly seven English authorities in ten. Build only if you are content to compete on content marketing and SEO against incumbents who already rank, using identical free data, at a price they have already anchored.

---

## 2. The opportunity

**The real problem.** A homeowner planning a rear extension or loft conversion has one question: *do I need permission, and what will they let me do?* Getting it wrong is expensive — an enforcement notice can require demolition. The information needed is scattered across the council's constraint map (of variable quality), the GPDO, the local plan, and any Article 4 direction. Householder developments generate **151,900 planning decisions a year in England** (year to March 2026, 51% of all decisions, 89% granted) — and that counts only those who *applied*. The larger population is those who considered work, or relied on permitted development, or never started.

**Why now (real tailwinds, honestly weighted):**

- **Platform maturity.** planning.data.gov.uk is live, fully open, OGL3, no authentication, with a genuine spatial API (§3).
- **MHCLG "Extract" (June 2026).** An AI tool, free to every English council, that converts historic conservation-area, Article 4 and TPO documents into standardised data — the exact three datasets that are weakest. Coverage should climb materially over the next 12–24 months. *This is a tailwind for the data and a headwind for a business built on handling gaps.*
- **Mandation has begun, but not here.** Regulations laid April 2026 use the Levelling-up and Regeneration Act 2023 planning-data powers for the first time — but they cover **plan and timetable data**, not constraints. Constraint publication remains voluntary/incentivised.
- **NTS Material Information Part C.** Estate agents must now disclose conservation-area status, listed-building status and TPOs in listings, established by *reasonable investigation of official sources* — not by asking the seller. This is a genuine B2B demand driver, and notably a *different* customer from the homeowner.
- **Home-buying reform.** Digital property logbooks and sales packs are committed to become required; a property smart-data scheme consultation is due 2027.

**The honest counterweight:** every one of these tailwinds is equally available to the ten incumbents, and the strongest (Extract) actively erodes the only defensible differentiator.

---

## 3. Data deep dive — verified

### 3.1 What I tested and observed

| Check | Method | Result |
|---|---|---|
| Dataset registry | `raw.githubusercontent.com/digital-land/specification/main/specification/dataset.csv` | **HTTP 200, 95,807 bytes, 279 dataset records** |
| Field schemas | `specification/dataset-field.csv` (184,759 bytes) | 200 — per-dataset field lists extracted |
| Collection config | `digital-land/config/collection/<name>/{source,endpoint}.csv` | 200 for all probed collections |
| Organisation registry | `digital-land/organisation-dataset/.../organisation.csv` | 200 — 441 orgs, 378 active |
| API implementation | `digital-land.info/application/{routers/entity.py, search/filters.py, core/models.py, data_access/os_api.py}` | 200 — parameters/formats/auth read from source |
| **Live API call** | — | **BLOCKED by egress policy (`connect_rejected`, 403). Not verified live.** |

### 3.2 The API (verified from source, not live)

The public API is a FastAPI app. Entity search accepts:

- **Spatial:** `longitude` + `latitude` (point intersection); `geometry` (WKT); `geometry_entity`; `geometry_reference`; `geometry_curie`; `geometry_relation` — a full DE-9IM enum (`within` (default), `intersects`, `contains`, `covers`, `coveredby`, `overlaps`, `crosses`, `touches`, `disjoint`, `equals`).
- **Filtering:** `dataset[]`, `typology[]`, `organisation_entity[]`, `entity[]`, `curie[]`, `prefix[]`, `reference[]`, `entries` (`all`/`current`/`historical`), `start_date`/`end_date`/`entry_date` with `match`/`before`/`since`/`empty` operators, `field[]`.
- **Search:** `q` — documented as "a postcode, or a Unique Property Reference Number (UPRN)".
- **Paging:** `limit` **1–500, default 10**; `offset`.
- **Formats:** `json`, `geojson`, `html` (`SuffixEntity` enum).

**Authentication: none.** No API-key or token middleware exists on the entity API. `CORSMiddleware` is registered, so browser-direct calls work. The only OAuth in the codebase is an `/os` router used for Ordnance Survey *basemap* tiles — irrelevant to data access.

The documented multi-dataset point query (from the platform's own `/docs`, surfaced via search — I could not fetch it directly) has the form:

```
GET /entity.json?latitude=52.5306&longitude=-1.9561
    &dataset=article-4-direction-area&dataset=conservation-area…
```

**One request returns every intersecting constraint across all requested datasets.** This is the single most important commercial fact in this document: the government performs the spatial join. There is no proprietary GIS work left to do.

**Response shape** (`EntityModel`, kebab-case JSON aliases, `extra="allow"`): `entity`, `name`, `dataset`, `typology`, `reference`, `prefix`, `organisation-entity`, `geojson`, `geometry` (WKT), `point` (WKT), `quality`, `entry-date`, `start-date`, `end-date`, plus dataset-specific fields passed through.

**Bulk:** a `download-lambda` serves `/{dataset}.{csv|json|parquet}` from **S3 Parquet via DuckDB behind CloudFront**, with `organisation-entity`, `quality` and column (`field`) filters. **Vector tiles:** `tiles-builder-task` runs **tippecanoe**, writing tiles as files to S3 behind a CDN. So: **CSV, JSON, GeoJSON, Parquet and vector tiles — no MBTiles serving requirement.**

### 3.3 Datasets, licence, schema

**279 datasets** in the registry. Phase: **17 live, 70 beta, 174 alpha, 17 prioritised, 1 discovery**. Typology: geography 105, specification 57, category 54, organisation 16, document 11, legal-instrument 9. Theme: development 69, environment 40, administrative 31, heritage 31.

**Licence: `ogl3` for all 279 datasets** — a single value across the whole registry. Open Government Licence v3.0. Attribution splits: crown-copyright 239, historic-england 12, natural-england 11, ons-boundary 10, os-open-data 2, defra 1, forestry-commission 1, inspire-index-polygon 1.

Verified field lists for the priority datasets:

| Dataset | Phase | Fields |
|---|---|---|
| `conservation-area` | beta | 15 — `designation-date`, `document-url`, `documentation-url`, `geometry`, `point`, `legislation`, `name`, `notes`, `organisation`, `prefix`, `reference`, `entity`, entry/start/end-date |
| `article-4-direction-area` | beta | 16 — incl. **`permitted-development-rights`**, `article-4-direction` (link), `address-texts`, `uprns`, `geometry`, `point` |
| `article-4-direction` | beta | 12 — `description`, `document-url`, `documentation-url`, `name`, `notes`, `organisation`, … |
| `tree-preservation-zone` | beta | 17 — incl. `tree-preservation-zone-type`, `tree-species-list`, `uprn`, `address-text`, `tree-preservation-order` (link) |
| `tree` | beta | 20 — incl. `felled-date`, `tree-species` |
| `tree-preservation-order` | beta | 15 — incl. `confirmed-date`, `made-date`, `legislation` |
| `listed-building` | beta | 15 — incl. `listed-building-grade`, `wikidata`, `wikipedia` |
| `flood-risk-zone` | live | 12 — incl. `flood-risk-type`, `flood-risk-level` |
| `permitted-development-right` | beta | 12 — incl. `permitted-development-right-part`, `permitted-development-right-class` |

Note `article-4-direction-area.permitted-development-rights`: the schema *does* provide a machine-readable link from an Article 4 area to the specific GPDO rights withdrawn. This is the most interesting field on the platform (see §4).

### 3.4 Coverage — the crux

**Method.** `config/collection/<name>/source.csv` registers every data source with its owning organisation; `endpoint.csv` holds the URL and a retirement `end-date`. I joined the two, kept only sources whose endpoint is live, and counted distinct authorities. **Denominator: 309** English LPA-type bodies from `organisation.csv` (295 district-level — 164 non-metropolitan districts, 63 unitaries, 36 metropolitan districts, 32 London boroughs — plus 10 national park authorities and 4 development corporations).

**Trap avoided.** A naive count of `source.csv` rows suggests ~317–325 authorities per dataset and near-complete coverage. It is wrong. Most rows are **placeholder stubs with an empty `endpoint` field**, bulk-seeded on single dates (conservation-area 269 stubs dated 2021-08-26; Article 4 314 stubs dated 2021-08-31; TPO 315 stubs dated 2021-12-01). MHCLG created one stub per LPA to *track* who still owes data. **They contain no data.** Anyone estimating coverage from source counts will overstate it by a factor of ~3.

**Second correction.** MHCLG publishes conservation-area data *on behalf of* non-publishing authorities from the `digital-land/conservation-area-data` repo (`data/Output/Missing/<LPA-CODE>-conservation-area.csv`), attributed to MHCLG's own organisation, not the LPA's. Counting by attribution therefore *undercounts*. Resolving the LPA code from each filename gives the true picture.

**Verified coverage, English LPAs (n=309):**

| Dataset | LPAs with live data | % | Notes |
|---|---:|---:|---|
| **conservation-area** | **301** | **97%** | 140 published by the LPA itself; **161 hand-digitised by MHCLG**. 8 LPAs have nothing. |
| **article-4-direction** | **117** | **38%** | No MHCLG backfill exists. |
| **tree-preservation-order** | **87** | **28%** | No MHCLG backfill exists. |
| listed-building (points) | *all* | **100%** | National, Historic England (NHLE). |
| listed-building-outline | 81 providers | ~26% | 100,742 polygons; patchy. |
| local-plan | 79 | 26% | |
| brownfield-land | 276 | **89%** | **Statutory duty since 2017.** |
| flood-risk-zone, green-belt, national-park, AONB/national landscape, SSSI, ancient woodland, scheduled monuments, parks & gardens, battlefields, WHS, INSPIRE title boundaries | *all* | **100%** | Single national providers (EA, MHCLG, ONS, Natural England, Historic England, HMLR). |

**Only 85 of 309 LPAs (28%) have all three priority datasets. 224 (72%) are missing Article 4 or TPO data or both.**

**Cross-validation.** My method yields **145 distinct provider organisations** for conservation-area. MHCLG's own dataset page states **"145 data providers"** and 10,960 conservation areas. Exact match — the method is sound.

**The `brownfield-land` control.** At 89%, brownfield-land is the outlier, and it is the one constraint dataset backed by a **statutory duty** (Brownfield Land Register regulations, 2017). Voluntary datasets sit at 28–38%. This is strong evidence that coverage tracks mandation, not enthusiasm — and constraints are not yet mandated.

**Quality caveat that matters more than the headline.** 161 of the 301 conservation-area authorities (53%) are covered by MHCLG **manually tracing boundaries from scanned PDF appraisal documents** — the repo's README describes georeferencing map images in GIMP and hand-tracing polygons, and candidly notes that some areas are "impossible to process in an automated way." For a tool whose entire value is *"is my house inside this line?"*, a hand-traced boundary from a scanned PDF is a materially different product from an authoritative one, and there is no per-polygon provenance flag exposed to tell them apart.

**Named gaps.** As of today, **London Borough of Croydon** has no conservation-area boundary at all. Article 4 coverage across London boroughs is 17/32; TPO is 10/32. Metropolitan districts: 17/36 and 15/36. Missing Article 4/TPO data disproportionately affects dense urban authorities — precisely the high-intent extension markets.

---

## 4. The data-vs-interpretation gap

This determines whether the product can honestly answer its own headline question. It cannot, fully.

**What the data answers well (facts about location):**
- Is this point inside a conservation area / green belt / national landscape / flood zone 2 or 3 / SSSI?
- Is there a listed building here, and at what grade?
- Is there an Article 4 direction here, and *(where the LPA has published it)* which GPDO Part/Class it withdraws.
- Is there a TPO zone here *(28% of authorities)*.

**What the data cannot answer:**

1. **The permitted-development rules themselves are not encoded.** The `permitted-development-right` dataset is a **reference list of GPDO Schedule 2 parts and classes** — `permitted-development-right-part` holds **21 parts** (1–20 plus 12A), sourced from MHCLG's dataset editor and described by the platform as *"experimental… created to support the development of a data specification for article 4 directions."* It contains **no dimensional limits, no conditions, no exclusions** — nothing about 3m vs 4m rear extensions, 50% curtilage, eaves heights, side-facing windows, Class E outbuilding rules, or the interaction with Article 2(3) land. **Those rules live in the GPDO (as amended — most recently by SI 2026/313) and in case law. Encoding them is your work, and it is the actual product.** It is also the part that can be wrong.
2. **Property-specific facts the platform does not hold.** Whether the dwelling is a house or a flat (PD rights largely do not apply to flats); whether PD rights were removed by a **planning condition** on the original permission (extremely common on post-1980 estates, and *not in any national dataset*); whether prior extensions have consumed the volume/area allowance; whether the building is curtilage-listed.
3. **Judgement calls.** Whether a design is "in keeping"; whether materials are of "similar appearance"; how a specific conservation-area appraisal treats rear extensions; how this LPA actually behaves.
4. **Boundary precision.** For 53% of conservation-area coverage the boundary is hand-traced (§3.4). A property on the edge cannot be adjudicated safely.

**Conclusion.** The platform reliably answers **"what designations touch this point, where we have data"**. It cannot answer **"what could I build here"** without a rules engine you write and maintain against changing legislation, plus property facts you cannot obtain. Any product claiming the latter is either hedged into uselessness or is issuing unlicensed planning advice. This is the crux of §11.

---

## 5. Competitive landscape

### 5.1 Free consumer tools — verified live via search, July 2026

The prior assessment's "consumer-grade tools are thin" is **no longer true**:

| Tool | Offering |
|---|---|
| **planningconstraints.com** | Free unlimited checks; **30+ constraint datasets from 5 official sources**; postcode/address/UPRN/grid-ref/map-pin entry; boundaries on a map; **£9.99 Full Survey Report** (PDF + CSV + plain-English guidance). Also runs a constraint-topic blog. |
| **mayfairstudio.co.uk/planning-permission-check** | Free, no signup, **~90 seconds**: PD eligibility, conservation area, Article 4, listed building, flood risk, recommended application route, **build-cost estimate**. Also publishes deep data-journalism content (e.g. "The Planning Constraint Map of England: 17 Datasets Analysed", "Complete List of Article 4 Directions in London"). |
| **consult.planninghandbook.com** (PlanningConsult) | Free **15-layer** constraint screen by postcode, all UK LPAs. |
| **theplanningconsultant.com/check** | Free instant check, 8 constraint categories, no account. |
| **whatcanibuild.co.uk** | PD/constraint reports plus nearby granted decisions; per-area "Permitted Development Explorer" pages. Owns the obvious brand name. |
| **getbiltd.com**, **conservationareachecker.com**, **vestigelondon.com**, **planwiser.co.uk**, **plansavvy.co.uk**, **planningpermissionchecker.co.uk** | Free conservation-area / constraint checkers, several London-focused. |

Several are thin SEO plays by architects and planning consultants using the checker as lead-gen — which is itself the tell: **the tool is cheap enough to be a marketing expense**, so it will always be given away by someone whose money is made elsewhere.

**Councils** also publish their own constraint maps (East Riding, Spelthorne, Staffordshire Moorlands, Lambeth, Thurrock and many more), typically with the disclaimer that the map is a guide and not exhaustive.

### 5.2 B2B incumbents — pricing (July 2026)

| Product | Price |
|---|---|
| **Searchland** Standard | **£195 per licence per month** (annual); Pro/MAX on request. Sells a dedicated **Planning Constraints API**. |
| **LandTech** Unlimited (LandInsight) | **£3,620/year** (~£302/month) |
| **Nimbus Maps** Advanced | **£3,000/year** (£250/month) |

These prices are real but they are **not** evidence that constraint data is worth £200/month. They bundle ownership/title data, off-market sourcing, site assessment, comparables, CRM and outreach. The constraint layer is a component, and the licensed HMLR ownership data is the actual moat — data you cannot redistribute under OGL. **Do not read B2B pricing as the value of the free layer.**

There is also at least one **data reseller** (homedata.co.uk) packaging UK conservation areas as a paid API — reselling a free OGL dataset, which tells you how low the effort floor is.

### 5.3 Portals

Neither Rightmove nor Zoopla shows planning constraints on listings by default. Rightmove has rolled out material-information fields, but they are **agent-entered**, not data-derived. Zoopla added crime/flood/planning-application context **behind sign-in**. All three portals have been criticised for NTSELAT non-compliance. This is a genuine gap — but it is a **B2B gap** (sell verified Part C data to agents/portals), not a consumer one.

### 5.4 So where is the wedge?

Honestly: **there is no defensible consumer wedge.** The three candidates and why each fails:

- *"Better UX"* — undifferentiated; incumbents already do postcode → map → expandable findings, free.
- *"Honest coverage"* (say "we have no Article 4 data for your council", which no incumbent does) — genuinely correct, genuinely rare, and a real trust advantage. But it is a **feature, not a business**, it is trivially copied, and MHCLG's Extract programme is actively deleting the problem it solves.
- *"Real PD rules engine"* — the only defensible technical asset, because it is the one thing not given away. But it is also the highest-liability component, requires ongoing legal maintenance against GPDO amendments, and still cannot see planning conditions that removed PD rights.

The only durable opportunity is **B2B compliance** (§10) — and that is a different company.

---

## 6. Product definition

*Presented as the strongest available scope, conditional on overriding the §1 verdict.*

**Target user:** the homeowner at the *pre-architect* stage — considering a rear extension, loft conversion or outbuilding, wanting to know whether it is realistic before spending £1,500+ on drawings. Secondary: prospective buyers doing diligence on a property they are about to offer on.

**The single "killer" feature — the only one worth building:**
> **A verified coverage and provenance statement attached to every answer.** Not "no constraints found" but: *"For **Croydon** we have **no conservation-area boundary data**, **no Article 4 data** and **no TPO data**. This check cannot tell you whether your property is affected. Here is the council page to check, and here is exactly what to ask."* And where data does exist: *"This conservation-area boundary was **digitised by MHCLG from a scanned PDF appraisal**, not supplied by the council — treat boundary position as indicative."*

Every competitor inherits the API's silence and presents absence-of-data as absence-of-constraint. That is the field's systematic, trust-destroying flaw, and it is fixable purely from the config data analysed in §3.4. It is also, candidly, easy to copy.

**In scope (MVP):**
- Address/postcode/UPRN → point → constraint lookup across the ~15 highest-value datasets.
- Map with constraint boundaries and the property pin.
- **Per-dataset, per-authority coverage and provenance badge** (verified / MHCLG-digitised / **no data held**).
- Plain-English explanation per constraint: what it is, what it restricts, what consent it triggers.
- "What to do next" — the specific council page, the LDC route, when to get a professional.
- Shareable permalink + printable summary.

**Explicitly out of scope (MVP):**
- **Any statement that a specific project does or does not need planning permission.** No verdicts.
- Dimensional PD calculators (3m/4m/50%) — the liability core; defer until §11 is settled.
- Planning-application alerts (saturated — prior assessment).
- Ownership/title data (licensed, cannot redistribute).
- Wales, Scotland, NI (platform is England-only).
- Build-cost estimates, architect matching, feasibility drawings.

---

## 7. Technical plan

**Architecture — deliberately boring.**

- **Do not proxy the API per request.** Latency and availability would be outside your control, and `limit` caps at 500. **Ingest the bulk Parquet/CSV downloads into PostGIS** on a nightly schedule; serve lookups from your own database. This gives sub-50ms point-in-polygon queries, offline resilience, and — critically — lets you compute the coverage/provenance layer that is the product's only differentiator, which the API cannot express.
- **Spatial query:** `ST_Contains`/`ST_Intersects` against a GiST index on constraint geometries. Store in EPSG:4326; use a buffered "near, not in" query (~25m) to flag edge cases honestly.
- **Coverage layer:** ingest `digital-land/config` `source.csv` + `endpoint.csv` + `organisation.csv` nightly and materialise a `(dataset, authority) → {live, mhclg_backfill, none}` table. This is the differentiator; it comes from the same repos analysed in §3.4.
- **Vector tiles:** MHCLG already builds tippecanoe tiles onto S3 behind a CDN. Consume theirs if hotlinking is acceptable; otherwise run tippecanoe on the same bulk data and serve PMTiles from object storage + CDN — no tile server process.
- **Basemap:** MapLibre GL + OS Maps API (OS Data Hub) or a raster fallback. The platform itself uses OS OAuth for basemaps.
- **Geocoding — the one real cost.** The platform's own implementation calls **`api.os.uk/search/places/v1/postcode` and `/uprn`**, which require an **OS Data Hub premium key** (`OS_CLIENT_KEY`). OS Data Hub gives ~**£1,000/month of free premium transactions**, which covers a lot but is a metered dependency and a commercial risk at scale. Free alternative for MVP: **postcodes.io** (free, OGL, postcode → lat/long) plus **OS Open UPRN** and **OS Open Names** (free OGL bulk downloads) loaded into PostGIS. Postcode-centroid accuracy is ~100m and **not adequate** for edge-of-boundary adjudication — which must be disclosed in the UI, and is a further argument for the "near a boundary" flag.
- **Stack:** any boring server framework + PostgreSQL/PostGIS + server-rendered pages. Full dataset is small — the whole platform is comfortably single-VM.

**Rough running cost:** VM/managed app £15–25/mo; managed PostGIS £15–40/mo; object storage + CDN £5–15/mo; domain/email ~£3/mo; OS Data Hub £0 within free allowance. **≈£40–85/month**, plus geocoding overage risk if OS Places is used at volume.

---

## 8. Effort & timeline

For one competent developer already comfortable with PostGIS and web mapping:

| Workstream | Days |
|---|---:|
| Ingest pipeline (bulk Parquet/CSV → PostGIS, nightly refresh, ~15 datasets) | 4–6 |
| Coverage/provenance layer from `config` repos (the differentiator) | 2–3 |
| Geocoding (postcodes.io + OS Open UPRN, disambiguation UI) | 2–3 |
| Lookup API + point-in-polygon + "near boundary" logic | 2 |
| Map UI, tiles, constraint rendering | 4–5 |
| Plain-English content for ~15 constraint types (**the real work — writing, not code**) | 5–8 |
| Coverage/provenance UX, disclaimers, legal review | 2–3 |
| SEO landing-page generation, analytics, deploy | 3–4 |
| **MVP total** | **24–34 dev-days (~5–7 weeks)** |

Add **10–15 days** if a PD rules engine is in scope — and budget for a planning professional's review, which is not optional.

**Ongoing maintenance: 1–3 days/month.** Nightly ingest breakage is the main burden — 621 live conservation-area endpoints alone, many on flaky council ArcGIS/WFS servers (though MHCLG absorbs collection failures upstream, which helps). Schema drift is real: 174 of 279 datasets are `alpha` and 70 `beta`. Add **legislative maintenance** if a rules engine exists: the GPDO was amended as recently as SI 2026/313, and every amendment is a correctness risk.

---

## 9. Distribution

**SEO — the entire channel, and also the problem.** Intent is strong and specific, but incumbents already rank for all of it and several publish better content than a solo entrant will.

- *Transactional:* "am i in a conservation area", "conservation area checker", "is my house in a conservation area", "article 4 direction checker", "check tpo on my property", "is my house listed", "planning constraints checker", "do i need planning permission for an extension".
- *Programmatic long-tail (the scalable play):* "conservation areas in **[borough]**", "article 4 directions **[borough]**", "**[postcode]** planning constraints", "permitted development **[council]**" — ~300 authorities × ~6 templates ≈ 1,800 pages. Mayfair Studio and whatcanibuild.co.uk are already executing exactly this.
- *Defensible angle:* "**does [council] publish its Article 4 data?**" — nobody owns this, and you have the verified answer for all 309 authorities. It is genuinely novel and links naturally to the tool.

**Press hooks (strongest asset — and possibly the best standalone output of this research):**
- *"72% of English councils have no Article 4 or tree-protection data on the government's own planning platform."* Verified, quantified, novel.
- *"More than half of England's conservation-area boundaries were hand-traced from scanned PDFs by civil servants."* Also verified, and a genuinely good story.
- *"Croydon: England's only London borough with no conservation-area boundary data."*
- Targets: Planning Resource, LGC, The Register, Estate Agent Today / Today's Conveyancer, local BBC.

**Communities:** r/HousingUK (**488k members**), r/DIYUK, BuildHub self-build forum, Homebuilding & Renovating (largest UK extender/self-builder audience), local Facebook conservation-area and residents' groups (highest intent, lowest volume). **Seed by publishing the coverage research, not the tool** — the data story earns links; the tool does not.

---

## 10. Sustainability

**Consumer monetisation — realistically, poor.**

- **Freemium PDF report.** Already price-anchored at **£9.99** by planningconstraints.com. At a plausible 1–2% conversion you need ~10,000 monthly visitors for ~£1,000–2,000/month gross, against ten competitors on identical free data. Viable as a side project; not as a business.
- **Affiliate to architects/planning consultants.** Higher value per lead (£20–100), and several incumbents *are* architects using the checker as lead-gen — meaning they can pay more for the traffic than you can earn from it, because they capture the whole £1,500+ project. **You cannot win an auction against your own affiliates.**
- **Ads.** Volumes are too low.

**B2B — the only route with real margin, and it is a different company:**
- **NTS Material Information Part C compliance for estate agents.** Agents must establish conservation-area, listed-building and TPO status by reasonable investigation of official sources. A bulk/batch API returning a **timestamped, evidenced Part C answer per listing** — including an explicit "no authoritative data held for this authority" — is a compliance product with recurring revenue and a defensible audit-trail value proposition. Conveyancers and property-pack providers (Open Property Data Association, digital sales packs) are the adjacent buyers.
- Reality check: this competes with Searchland's Planning Constraints API and Landmark/HMLR search products, requires sales rather than SEO, and needs professional indemnity insurance.

**Honest conclusion:** the consumer product does not sustain itself. The B2B compliance product might — but it is a sales-led company with a different customer, different risk profile and different skills, and it should be evaluated on its own terms rather than reached by drifting.

---

## 11. Liability & responsible scope

**The risk is concrete, not theoretical.** A documented case exists of an **architect who wrongly advised that works were permitted development; the local authority served an enforcement notice requiring the extension to be removed.** That is the exact failure mode, and the loss is the cost of the build plus demolition. Telling a homeowner "you can build this without permission" is functionally professional advice, and a disclaimer does not reliably neutralise a statement a reasonable consumer relied on. Under the Consumer Rights Act 2015, terms excluding liability for negligent misstatement are subject to a fairness test; blanket exclusions are not dependable.

**Note also:** "planning consultant" is not a protected title and giving planning advice is not a regulated activity — so there is no licensing barrier. The exposure is **negligent misstatement**, not regulatory.

**Responsible scope — the rules I would hold to:**

1. **Report designations; never adjudicate projects.** "This property is within the X Conservation Area" — never "you don't need permission for this."
2. **Absence of data is never absence of constraint.** Where an authority publishes nothing, say so explicitly and name the authority. This is both the ethical minimum and the product's differentiator.
3. **Disclose provenance and precision.** Flag MHCLG-digitised boundaries as indicative; flag postcode-centroid geocoding; flag properties within ~25m of any boundary as "cannot be determined from this data — verify with the council."
4. **State what is not covered.** Planning conditions removing PD rights, curtilage listing, prior extensions consuming allowance, flat vs house — none are in the data. Say so prominently, not in a footer.
5. **Route to authority, always.** Every result ends with the council's own constraint page and the **Lawful Development Certificate** route (~£145–349 depending on type/date) as the only way to obtain a binding answer.
6. **No PD verdicts in MVP.** If a rules engine is ever added, present it as an **educational checklist the user completes about their own property**, with the user supplying the facts, and route unambiguously to an LDC.
7. **Insurance and review.** Professional indemnity cover before any interpretive output; a chartered planner's review of all rules content.

Existing tools mostly disclaim in generic footer terms while presenting confident on-screen verdicts — that gap between presentation and disclaimer is where the liability actually sits, and it is worth not imitating.

---

## 12. Risks & kill criteria

| Risk | Severity | Assessment |
|---|---|---|
| **Market already commoditised** | **Critical** | **Already materialised.** ≥10 free tools; £9.99 anchor set; API does the spatial work; entry cost ≈ one weekend. This alone is decisive. |
| Article 4 / TPO coverage at 38% / 28% | High | Verified. The tool cannot reliably answer its headline question for 72% of authorities. |
| **MHCLG Extract closes the coverage gap** | High | Live to all councils **June 2026**. Erodes the sole differentiator, on a government timetable you don't control. |
| **MHCLG builds the consumer view** | High | The platform already has a `find_an_area` feature using OS postcode/UPRN search, a public map, and a `site-assessment-prototype` repo (created June 2026). The data owner is moving up the stack. |
| Liability from PD guidance | High | Enforcement-notice precedent exists. Manageable only by refusing to give verdicts — which removes the feature users want. |
| Boundary quality (53% hand-traced from PDFs) | Medium-High | Verified from MHCLG's own repo. Edge cases are unresolvable and legally consequential. |
| SEO dominated by architect lead-gen | Medium-High | They monetise at £1,500+/project; you monetise at £9.99. You lose the auction. |
| Ingest fragility / alpha schema drift | Medium | 174/279 datasets `alpha`. Ongoing tax. |
| OS geocoding dependency | Low-Medium | £1,000/mo free allowance; free OGL fallbacks exist at lower precision. |

**Kill criteria — stop if any is true:**
- Any two of the free incumbents are still shipping improvements in six months (they are venture- or practice-subsidised; you are not).
- Article 4 coverage passes ~70% of LPAs via Extract — the honest-coverage differentiator is then worthless.
- MHCLG ships a consumer-grade "check your property" journey on planning.data.gov.uk.
- Organic search fails to reach 1,000 sessions/month by month 4.
- Report conversion is under 0.5% on 5,000+ sessions.
- Legal review concludes that meaningful PD guidance cannot be given without PI cover you cannot afford.

**Pre-mortem, one line:** *It failed because the government did the hard part for free, ten people noticed before we did, and the only thing we could add was a legal opinion we weren't qualified or insured to give.*

---

## 13. Open questions

**Must be resolved before any commitment:**

1. **Live API verification (blocking).** Egress policy prevented any live call. Confirm by hand: multi-dataset point query returns intersecting polygons; actual response latency; `limit=500` paging behaviour; whether undocumented rate limits exist; whether CORS genuinely permits browser-direct calls in production.
2. **Bulk download URLs.** The `download-lambda` URL *pattern* is verified from source; the actual host (`files.planning.data.gov.uk`?) and per-dataset file sizes are not. Confirm total ingest volume.
3. **Vector tile URL and hotlinking policy.** Tiles exist on S3+CDN; the public URL template and whether third-party use is acceptable are unconfirmed.
4. **Are the ten competitors real businesses or thin SEO shells?** I verified they exist and what they claim via search; I could not load them. Check quality, traffic (Similarweb/Ahrefs), company filings, and whether any are abandoned. **If most are shells, the verdict softens toward BUILD LATER with the honest-coverage wedge.** This is the highest-value follow-up.
5. **Actual published record counts.** Verified: conservation-area 10,960 / 145 providers; listed-building-outline 100,742 / 81 providers. Not verified: article-4-direction-area, tree-preservation-zone, flood-risk-zone, listed-building point counts.
6. **Extract's real trajectory.** How many authorities have actually used it since June 2026, and what is MHCLG's target date for the three national datasets? This single number determines whether the coverage wedge has a 6-month or 3-year life.
7. **Does `article-4-direction-area.permitted-development-rights` get populated in practice?** The field exists in the schema; whether LPAs actually fill it (and in what format) decides whether Article 4 → specific-PD-right mapping is real or aspirational. **Check this early — it is the most valuable field on the platform.**
8. **Are `listed-building` records genuinely national?** Attribution is Historic England, but confirm the platform mirrors the full NHLE (~400,000 entries) rather than a subset.
9. **PI insurance cost** for a constraint-reporting product with any interpretive element.
10. **Coverage denominator.** I used 309 LPA-type bodies derived from `organisation.csv`. MHCLG variously cites 311 and ~317. Reconcile before publishing any coverage statistic externally — the press hook depends on it being exactly right.
11. **Flood data currency.** The EA's NaFRA2 refresh changed flood-risk outputs; confirm which vintage `flood-risk-zone` carries before showing flood answers to consumers.
