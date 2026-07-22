# Assessment: UK Open Dataset → Consumer App Opportunities

Stage 2 of the research: each dataset from the [catalogue](uk-public-datasets-catalogue.md) was assessed (via web search, July 2026) for existing competition and solo-developer viability.

Methodology: for each dataset the leading app idea(s) were searched and the competitive landscape classified as **SATURATED** (strong, popular incumbents), **OCCUPIED** (incumbents exist but weak/dated/niche), or **OPEN** (no notable consumer product found). Viability (1–10) weighs data access friction, freshness, licence, technical difficulty and realistic audience size for a solo/small-team build.

---

## Crime, Safety & Emergency Services

**1. Street-Level Crime (data.police.uk)** — **SATURATED.** Official police.uk crime maps plus at least four independent clones already live: [PoliceMap.uk](https://policemap.uk/), [CrimeSpotter UK](https://crimespotter.co.uk/), [CrimeRate](https://crimerate.co.uk/crime-map) (3D street view), and [Plumplot](https://www.plumplot.co.uk/) (crime bundled with house prices/salaries). This is literally the CrashMap-analogue space and it's full.
Viability: 3/10. Differentiation: none obvious for a plain heatmap; a real wedge would need something incumbents don't do (predictive risk scoring, insurance-quote integration). Verdict: **AVOID**.

**2. London Fire Brigade Incidents** — **OCCUPIED.** LFB runs its own [Incident Mapping tool](https://lfbincidentmapping.london-fire.gov.uk/) and the ODI built a [borough fire-risk map](https://london-fire.labs.theodi.org/). Crucially, LFB explicitly does **not** commit to response times below borough level, so a genuine "how fast to my postcode" tool would be building on data the brigade itself won't validate that granularly. London-only audience caps upside further.
Viability: 4/10. Differentiation: a "causes of fire by season/borough" story-telling explorer is a plausible small wedge. Verdict: **WEDGE** (narrow).

---

## Property, Land & Buildings

**3. HM Land Registry Price Paid** — **SATURATED.** Zoopla's [Sold House Prices](https://www.zoopla.co.uk/house-prices/) and Rightmove's [House Prices](https://www.rightmove.co.uk/house-prices.html) tools are free, comprehensive, monthly-updated and app-backed, covering "what did my neighbours pay" exactly.
Viability: 3/10 for a generic clone. Differentiation: a 30-year gentrification/price-growth *animation* is a more defensible niche than a lookup tool. Verdict: **AVOID** (lookup) / **WEDGE** (visual storytelling angle only).

**4. EPC Register** — **OCCUPIED/SATURATED.** A long tail of near-identical postcode lookup clones already exists: [Homedata](https://homedata.co.uk/tools/epc-checker), [EPC Lookup](https://epclookup.co.uk/search/), [Find Your EPC](https://findyourepc.com/), [Pinpoint](https://pinpoint.finance/epc-rating-checker/). None is dominant, which signals a commoditised, low-differentiation niche rather than an opening.
Viability: 4/10 (registration friction adds cost). Differentiation: a genuinely mapped "worst-insulated streets" heatmap / retrofit-priority layer is more sophisticated than the existing single-address lookups. Verdict: **WEDGE**.

**5. National Heritage List (listed buildings)** — **OCCUPIED.** Historic England's own [Map Search](https://historicengland.org.uk/listing/the-list/map-search) plus a third-party [English Heritage Map app](https://apps.apple.com/us/app/english-heritage-map/id6748280322) and a [Route Builder](https://www.northeastheritagelibrary.co.uk/post/the-route-builder-a-how-to-guide) walking-tour generator already cover this well.
Viability: 4/10 (small enthusiast audience). Differentiation: overlay with live planning applications to flag conservation risk is genuinely underserved. Verdict: **WEDGE**.

**6. VOA Council Tax Bands** — **SATURATED.** [TaxBandCheck](https://taxbandcheck.co.uk/) and [CouncilTaxChecker](https://counciltaxchecker.co.uk/) already do the exact "compare your band to neighbours, find the overpayment" pitch, with several more SEO-clone competitors.
Viability: 3/10. Differentiation: none found beyond UX polish. Verdict: **AVOID**.

**7. Planning Applications (PlanIt)** — **SATURATED.** At least five active competitors: [PlanningAlert](https://planningalert.co.uk/), [PlanWatch](https://planwatch.co.uk/) (free, all 378 authorities), [Plottr](https://www.plottr.co.uk/), [Plota](https://plota.co.uk/), Planning Insights — the "new applications near me" alert space is fully commoditised and mostly free already.
Viability: 3/10. Differentiation: minimal. Verdict: **AVOID**.

---

## Transport & Travel

**8. TfL Unified API** — **SATURATED.** TfL's own app, Citymapper and Google Maps dominate; almost every London transit idea using this API has multiple strong incumbents.
Viability: 3/10 generically. Differentiation: step-free/accessible journey planning is comparatively underserved. Verdict: **AVOID** (generic) / **WEDGE** (accessibility niche).

**9. Bus Open Data Service (BODS)** — **SATURATED.** [bustimes.org](https://bustimes.org/) is a beloved, comprehensive, free, open-source "where's my bus" tracker covering 16k+ vehicles nationwide (not just London).
Viability: 3/10 for a clone. Differentiation: a rural bus-desert/equity visualiser combining timetables with population is a real gap bustimes.org doesn't fill. Verdict: **AVOID** (tracker) / **WEDGE** (equity angle).

**10. NaPTAN** — Infrastructure/glue data, not a standalone consumer product (it's what bustimes.org, Citymapper etc. build on top of). Viability: 6/10 as a building block. Verdict: **N/A / infra only**.

**11. Darwin/Network Rail Open Rail Data** — **SATURATED, and technically hard.** [Realtime Trains](https://www.realtimetrains.co.uk/), National Rail's own live boards, plus DepartUK, On Rails, UK Train Times, Railtime and NexTrain all already deliver live departures/delay tracking. On top of that the access route (STOMP message broker) is the highest technical barrier in the whole catalogue.
Viability: 2/10. Verdict: **AVOID**.

**12. ORR Estimates of Station Usage** — **OPEN.** Press coverage exists (Brilliant Maps' [busiest-stations map](https://brilliantmaps.com/busiest-uk-rail-stations/), news round-ups of the UK's quietest station "Elton and Orston, 68 entries/year") but no dedicated *interactive, ongoing* consumer app was found — it's a one-off journalism dataset, not a maintained product.
Viability: 6/10 — trivial Excel/CSV data, OGL, great "ghost station" storytelling hook, but annual (not real-time) data means low repeat-visit utility. Differentiation: nobody has built the persistent explorer/growth-animation version. Verdict: **BUILD** (as a strong one-shot data-story site rather than a daily-use app).

**13. DVSA Anonymised MOT Results** — **SATURATED** (more crowded than the catalogue implies). Multiple live products already mine this exact data: [AutoRank](https://autorank.co.uk/), [PlateInsight](https://www.plateinsight.co.uk/vehicle-explorer/), [Lisense](https://lisense.uk/vehicle-insights), [VehicleScore](https://vehiclescore.co.uk/reliability), [KnowYourCar](https://know-yourcar.co.uk/), plus blackcircles' MOT Index and motdata.uk.
Viability: 3/10. Verdict: **AVOID**.

**14. GB Road Traffic Counts (AADF)** — **OPEN.** DfT's own [interactive map](https://roadtraffic.dft.gov.uk/) exists but no popular independent "how busy is my road" consumer app was found; roadtrafficstats.uk is minor/unbranded.
Viability: 5/10 — clean OGL bulk data, but audience is thin (this scratches an intellectual-curiosity itch, not an urgent need). Verdict: **BUILD** (modest-scale).

**15. National Highways WebTRIS** — **OPEN but weak value proposition.** No dedicated consumer app found, but the data is *historic* sensor data, not live — so it can't compete with Google Maps/Waze/the official National Highways app for the "when should I travel" use case people actually want solved in real time.
Viability: 4/10. Verdict: **HARD** (open, but the historic-only nature undercuts the obvious consumer use case).

**16. Street Manager Roadworks** — **SATURATED.** [RoadworksTrackr](https://roadworkstrackr.co.uk/), [LiveRoad](https://liveroad.app/) and [RoadworksRadar](https://www.roadworksradar.uk/) already stream the exact Street Manager feed into "avoid the roadworks" maps.
Viability: 3/10. Verdict: **AVOID**.

**17. DVLA Vehicle Licensing Statistics (small-area)** — **OPEN.** Regit and One Home have published *articles* using this data ("EV deserts", Stockport as EV hotspot) but no ongoing interactive consumer explorer exists — it's PR/journalism content, not a maintained tool.
Viability: 6/10 — clean OGL CSVs, good story appeal (EV adoption inequality), annual cadence limits stickiness. Differentiation: build the persistent interactive map the journalists' one-off pieces lack. Verdict: **BUILD**.

**18. EV Chargepoints (post-NCR)** — **SATURATED.** [Zapmap](https://www.zapmap.com/) is dominant (2M+ downloads, 4.6★, live availability on ~80% of chargers, payment integration across 40 networks). Total incumbent lock.
Viability: 2/10. Verdict: **AVOID**.

**19. CAA Flight Punctuality Statistics** — **OCCUPIED.** [Owedly's league table](https://owedly.org/league/) already builds exactly this from CAA data, and Flighty/AirHelp cover the adjacent live-delay/compensation space very well.
Viability: 4/10. Differentiation: seasonal delay-risk forecasting for holiday planners is a real, narrower gap. Verdict: **WEDGE**.

**20. Traffic Scotland Gritter Tracker** — **OCCUPIED** (officially provided, and gritter-naming already goes viral organically every winter via press coverage, e.g. the ["McGritter Tracker" feature on Google Maps Mania](https://googlemapsmania.blogspot.com/2025/11/the-mcgritter-tracker-is-back.html)). No independent gamified layer (leaderboard, name-history archive, coverage-gap alerts) exists on top of the official map.
Viability: 5/10 — seasonal (Nov–Mar only), API not formally documented (a real risk), but very low technical bar and proven viral appeal. Differentiation: a novelty leaderboard/history archive the official tracker doesn't offer. Verdict: **WEDGE**.

---

## Health

**21. NHS English Prescribing Dataset** — **SATURATED.** This *is* the dataset behind [OpenPrescribing](https://openprescribing.net/), an Oxford-built, mature, free, comprehensive academic-grade tool that already does peer comparison, trend maps and stewardship dashboards.
Viability: 2/10. Verdict: **AVOID**.

**22. Food Hygiene Ratings (FHRS)** — **SATURATED.** The FSA-linked [Scores on the Doors](https://www.scoresonthedoors.org.uk/) app/site is the canonical, comprehensive product (613k establishments), and ratings are already surfaced inside Just Eat/Uber Eats-style apps too.
Viability: 3/10. Verdict: **AVOID**.

---

## Environment, Weather & Energy

**23. EA Real-Time Flood Monitoring** — **SATURATED.** GOV.UK's own [check-for-flooding service](https://check-for-flooding.service.gov.uk/), plus [FloodRadar](https://www.floodradar.co.uk/), [RiverLevels.uk](https://riverlevels.uk/), PostcodeCheck and MapTools.uk all already do postcode-based live river-level/warning lookups.
Viability: 3/10. Verdict: **AVOID**.

**24. EA Bathing Water Quality** — **SATURATED.** Surfers Against Sewage's [Safer Seas & Rivers Service](https://www.sas.org.uk/water-quality/sewage-pollution-alerts/safer-seas-rivers-service/) is a beloved, free, well-funded charity app covering 550+ locations with live sewage-discharge alerts — already built extremely well.
Viability: 2/10. Verdict: **AVOID**.

**25. Carbon Intensity API (NESO)** — **SATURATED.** Numerous existing tools already do "best time to run the dishwasher": [GridPulse](https://apps.apple.com/us/app/gridpulse/id6762229397), [WWF Green Energy Forecast](https://www.wwf.org.uk/challenges/green-energy-time), WhenToPlugIn, [Greener Charge](https://greenercharge.uk/).
Viability: 2/10. Verdict: **AVOID**.

**26. Elexon BMRS** — **SATURATED**, arguably the most crowded space in the whole catalogue: [MyGridGB](https://www.mygridgb.co.uk/), [grid.iamkate.com](https://grid.iamkate.com/) (widely loved simple dashboard), [Gridwatch](https://gridwatch.co.uk/), Energy Dashboard, UK Grid Live, Electricity Maps.
Viability: 2/10. Verdict: **AVOID**.

**27. Met Office HadUK-Grid / local climate** — **OCCUPIED, genuine gap.** [Showyourstripes.info](https://showyourstripes.info/) and Carbon Copy's [local warming-stripes for all 379 UK council areas](https://carboncopy.eco/blog/warming-stripes) exist, but these are **static downloadable images**, not an interactive, data-rich, per-postcode explorer (rainfall/sunshine records, extremes, 1km-grid granularity vs. council-area aggregates).
Viability: 5/10 — NetCDF/geospatial tooling and CEDA registration raise technical difficulty. Differentiation: interactivity + finer-grained (1km) local data beyond what the static-image generators offer. Verdict: **WEDGE**.

**28. Defra National LIDAR Programme** — **SATURATED** for the flagship idea (solar-suitability): [Solar Wizard](https://homeowners.retrofitwest.co.uk/solar-wizard-the-ultimate-solar-panels-assessment-tool/) (Centre for Sustainable Energy), Solarable, Mapscaping, Energy Saving Trust, sunsave.energy all already do postcode-based roof-suitability scoring.
Viability: 3/10 for solar. The secondary ideas (3D flythroughs, hillshade relief maps) are less contested but require heavy GIS/raster skills for a small hiking-niche audience. Verdict: **AVOID** (solar) / **HARD** (3D/terrain ideas — open but high technical cost, thin audience).

---

## Nature & Biodiversity

**29. NBN Atlas Species Occurrences** — **SATURATED** for the core idea. [iNaturalist(UK)](https://www.inaturalist.org/) and [iRecord](https://irecord.org.uk/) are the dominant, well-established "what wildlife is near me" recording/mapping platforms, and they already feed the NBN Atlas itself.
Viability: 3/10 for a generic species-near-me clone. Differentiation: a focused invasive-species spread tracker (Asian hornet, Japanese knotweed) is narrower and closer to open, though official Asian Hornet Watch-style tooling may already partially cover this — verify before committing. Verdict: **AVOID** (generic) / **WEDGE** (invasive-species tracker, unverified opening).

**30. London Public Realm Trees** — **SATURATED.** The GLA's own official [London Tree Map](https://apps.london.gov.uk/public-realm-trees) already covers exactly this (1.1M trees, species, climate-suitability scoring), plus the independent [TreeTalk](https://bigthink.com/strange-maps/london-tree-map/) app (700k trees, personalised walk generator) and the Woodland Trust's Tree ID app.
Viability: 3/10. Verdict: **AVOID**.

---

## Bonus / Civic & Quirky — batch assessment

| Item | Competition | Verdict |
|---|---|---|
| postcodes.io | Infra/glue, not a consumer product itself | N/A (building block) |
| Nomis/Census, IMD | Backbone layers used inside other apps; several existing demographic lookup sites | OCCUPIED — build as a layer, not a standalone |
| OS OpenData | Base map layers | N/A (infra) |
| Companies House bulk/PSC | Company lookup tools exist (Endole, Company Check) but PSC **ownership-network graph visualisation** is genuinely underdone as a consumer product | **WEDGE** — viability 6/10 |
| Ofcom Connected Nations | OCCUPIED: official checker + thinkbroadband + HouseCheckup already do postcode broadband lookups | AVOID/WEDGE (niche "not-spot" campaigning angle only) |
| DWP Stat-Xplore | No consumer benefit-uptake map found; genuinely open but audience is policy-wonk/journalist, not mass consumer | **BUILD** (niche), viability 5/10 |
| Electoral Commission donations | [Party Money](https://jhammant.github.io/party-money/) and [MPData](https://mpdata.uk/) already visualise this | OCCUPIED — WEDGE only |
| IPSA MP expenses | Official search UI + an R package (`ipsar`) exist for researchers, but **no polished public-facing comparison/outlier-finder app** was found | **OPEN** — viability 6/10 |
| TheyWorkForYou | SATURATED — dominant, free, mySociety-run, open data + API | AVOID |
| OpenSky ("what's that plane") | SATURATED — Flightradar24, Plane Finder, and AR apps like "Overhead" already dominate | AVOID |
| OpenBenches | The dataset publisher already built the exact consumer product | SATURATED (self-built) — AVOID for a clone |
| Global Fishing Watch (UK waters) | No UK-specific consumer app found, but AIS data pipeline is technically heavy and audience (fishing industry/conservation) is small | OPEN but **HARD** |

---

## Overall pattern

The UK civic-tech/consumer-data space is **mature almost everywhere the catalogue's own "app ideas" pointed** — of the 30 primary datasets, roughly two-thirds land on SATURATED for their headline idea (crime, price paid, council tax, planning, buses, trains, EV charging, prescribing, food hygiene, flooding, bathing water, carbon intensity, grid mix, solar suitability, species-near-me, London trees). Genuine openings cluster in datasets that are **data-rich but journalistically under-exploited** (annual/statistical, not live) rather than the flashy real-time ones everyone has already built against.

---

## Top 5 Recommendations

| Rank | Dataset | Idea | Verdict | Why it wins |
|---|---|---|---|---|
| 1 | **IPSA MP Staffing & Business Costs** | MP-expenses comparison + outlier finder | **BUILD** | Genuinely no polished consumer tool found despite ready CSV data (OGL-equivalent, no registration); recurring news hook every expenses-scandal cycle gives free distribution; low technical bar. |
| 2 | **ORR Estimates of Station Usage** | Interactive busiest/quietest-station explorer with growth animation | **BUILD** | Trivial, clean, OGL Excel/CSV data; strong inherent story ("68 passengers/year" ghost stations already goes viral in press) but no persistent interactive product exists — journalists have only done one-off maps. |
| 3 | **DVLA Vehicle Licensing (small-area)** | Interactive EV-adoption / "most popular car near me" map | **BUILD** | Existing coverage (Regit, One Home) is PR journalism, not a maintained app; clean annual OGL data; strong, growing public interest in EV transition inequality. |
| 4 | **Companies House bulk/PSC data** | Ownership-network graph + company-density map | **WEDGE** | Basic company lookup is occupied, but PSC ownership-network visualisation for journalists/due-diligence users is a distinct, underserved angle on very accessible bulk data. |
| 5 | **Traffic Scotland Gritter Tracker** | Novelty leaderboard/history archive layered on the official live map | **WEDGE** | Official tracker exists and already goes viral organically each winter, but nobody has built the gamified leaderboard/archive layer on top — highest viral-per-effort ratio in the catalogue; seasonality and an undocumented API are the main risks. |

**Honourable mentions (not top 5 due to weak wedge or thin audience):** Met Office HadUK-Grid local warming-stripes interactive (real gap vs. static image generators, but NetCDF/geospatial skills required); DWP Stat-Xplore benefit-uptake maps (genuinely open, but audience is niche); London Fire Brigade cause-of-fire explorer (narrow wedge, London-only).

**Consistent AVOID cluster:** street crime, price paid, council tax bands, planning alerts, live rail departures, EV chargepoint finders, food hygiene ratings, flood/bathing-water alerts, carbon-intensity "best time to run the dishwasher," live grid-mix dashboards, MOT reliability lookups, London tree maps, and NBN species-near-me — all have one or more strong, often free/charity-backed incumbents that a solo developer cannot realistically out-execute without a sharp, defensible wedge.
