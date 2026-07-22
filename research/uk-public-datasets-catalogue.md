# UK Open Data Catalogue for CrashMap-style Consumer Apps

A curated set of 30 verified public/open datasets that could power map-based, lookup, or visualisation apps in the spirit of CrashMap. All were confirmed via search/fetch as of July 2026. Licences noted where confirmed; most are Open Government Licence v3.0 (OGL). Always double-check current licence/rate-limit terms before building.

---

## Crime, Safety & Emergency Services

### 1. Street-Level Crime & Stop-and-Search — Police (data.police.uk)
- **Publisher:** Home Office / UK police forces
- **Contents:** Individual street-level crime records (category, approximate location snapped to anonymised points, month, outcome status), stop-and-search records, neighbourhood boundaries and team info. Covers all 45 forces in England, Wales and Northern Ireland (PSNI has no stop-and-search). Monthly, back to ~2011.
- **Access:** Free REST API (no key) with point/radius/postcode/custom-polygon queries, plus monthly bulk CSV downloads broken down by force and 2021 LSOA. OGL v3.0.
- **App ideas:** (1) A "what's happening on my street" crime heatmap and trend tracker by postcode. (2) Stop-and-search transparency dashboard showing demographic/outcome breakdowns by area. (3) Move-home comparison tool ranking neighbourhoods by crime mix.
- **Caveats:** Locations are approximate (snapped to representative points), so never exact. Outcomes lag. Category definitions shifted over time.
- **Source:** https://data.police.uk/docs/

### 2. London Fire Brigade Incident & Mobilisation Records
- **Publisher:** London Fire Brigade via GLA London Datastore
- **Contents:** Every incident LFB attended since 1 Jan 2009 (date/time, location to ward/postcode, incident type), plus fire-engine mobilisation records (response times, appliances). Monthly updates.
- **Access:** CSV/Excel bulk download; interactive dashboard to ward/postcode. OGL.
- **App ideas:** (1) Response-time map showing how fast an engine reaches your postcode. (2) "Causes of fire" explorer (cooking, arson, false alarms) by borough. (3) Seasonal/bonfire-night incident spike visualiser.
- **Caveats:** London only. Large historic files.
- **Source:** https://data.london.gov.uk/dataset/london-fire-brigade-incident-records-em8xy/

---

## Property, Land & Buildings

### 3. HM Land Registry Price Paid Data
- **Publisher:** HM Land Registry
- **Contents:** Every property sale lodged for registration in England & Wales since 1995 — price, date, full address/postcode, property type, new-build flag, tenure. Tens of millions of records.
- **Access:** CSV/text bulk (full + monthly updates), plus linked-data SPARQL. Updated 20th working day monthly. OGL v3.0, commercial use permitted.
- **App ideas:** (1) Street-level sold-price map with per-postcode price history sparklines. (2) "What did my neighbours pay" lookup. (3) Gentrification/price-growth animation over 30 years.
- **Caveats:** Excludes some transfers (repossessions, transfers of portfolios, commercial-only in some cases). Address matching to coordinates requires joining to a postcode/OS gazetteer.
- **Source:** https://landregistry.data.gov.uk/app/ppd/ppd_data

### 4. Energy Performance Certificates (EPC)
- **Publisher:** MHCLG (Open Data Communities)
- **Contents:** ~30 million domestic and non-domestic EPCs for England & Wales — energy rating (A–G), floor area, construction, heating type, estimated costs, CO2, address. Display Energy Certificates for public buildings too.
- **Access:** Search UI, bulk CSV (zipped by local authority), and REST API. Requires free GOV.UK One Login registration (data contains personal info + restrictive terms).
- **App ideas:** (1) Map of housing stock energy efficiency showing worst-insulated streets. (2) Retrofit-priority tool for a local authority. (3) Home-buyer "running cost" estimator by address.
- **Caveats:** Registration required; personal data handling obligations. Certificates expire (10 years) so records can be stale.
- **Source:** https://epc.opendatacommunities.org/

### 5. National Heritage List for England (Listed Buildings etc.)
- **Publisher:** Historic England
- **Contents:** All listed buildings, scheduled monuments, registered parks/gardens, battlefields, protected wrecks — as point and polygon GIS, with grade, list entry, description. Updated daily.
- **Access:** GIS shapefiles/GeoJSON/CSV/KML via download page and ArcGIS Open Data Hub (WFS/WMS APIs). OGL.
- **App ideas:** (1) "Heritage near me" walking-tour map with listing descriptions. (2) Filter by grade (I/II*/II) to find rare local landmarks. (3) Overlay listed buildings on planning applications to flag conservation risk.
- **Caveats:** Point data doesn't capture building footprints; polygon coverage incomplete for some entries.
- **Source:** https://historicengland.org.uk/listing/the-list/data-downloads/

### 6. VOA Council Tax Bands
- **Publisher:** Valuation Office Agency (HMRC)
- **Contents:** Council Tax band (A–H) per dwelling, band value ranges, and aggregate dwelling counts by band and area.
- **Access:** Public band-lookup UI by postcode; aggregate open datasets (e.g. by ward) via data.gov.uk and London Datastore. No official full-property bulk API.
- **App ideas:** (1) "Is my council tax band wrong?" neighbour-comparison tool (bands set on 1991 values). (2) Band distribution map showing affluence proxy by area. (3) Combined with Price Paid, a band-vs-actual-value mismatch finder.
- **Caveats:** No official bulk download of every property's band; per-address lookup only through the UI. Aggregate open data is coarser.
- **Source:** https://www.gov.uk/government/statistics/quality-assurance-of-administrative-data-in-the-uk-house-price-index/valuation-office-agency-council-tax-valuation-lists

### 7. Planning Applications — PlanIt
- **Publisher:** PlanIt (aspeakman) aggregating 400+ UK councils
- **Contents:** Planning applications across England, Scotland and Wales — address, description, status, decision dates, geolocation. Frequently updated.
- **Access:** Free JSON/GeoJSON API (e.g. `/api/applics/geojson`) with bbox, date and postcode filters.
- **App ideas:** (1) "What's being built near me" alert map with email notifications for new applications in a radius. (2) Development pressure heatmap. (3) Objection-deadline tracker for a neighbourhood.
- **Caveats:** Aggregator, not an official government source; coverage/latency varies by council. Full historic scraper access is commercial. Also see official Street Manager below and Planning.data.gov.uk.
- **Source:** https://www.planit.org.uk/

---

## Transport & Travel

### 8. TfL Unified API
- **Publisher:** Transport for London
- **Contents:** Live tube/bus/rail arrivals, line status, disruptions, journey planning, StopPoints, cycle-hire (Santander) dock availability, road corridors, air quality, timetables.
- **Access:** REST API (JSON). Works without a key (rate-limited); free registered key gives up to ~500 req/min. OGL-based TfL open-data terms.
- **App ideas:** (1) Live "next arrivals" board widget for a chosen stop. (2) Cycle-hire dock-availability map with predictive "will there be a bike" scoring. (3) Step-free accessible-journey planner.
- **Caveats:** London-focused. Rate limits bite on busy endpoints (journey planning). Some data is near-real-time, not instantaneous.
- **Source:** https://tfl.gov.uk/info-for/open-data-users/api-documentation

### 9. Bus Open Data Service (BODS)
- **Publisher:** Department for Transport
- **Contents:** Legally-mandated feed of English bus operator data — timetables (TransXChange/GTFS), real-time vehicle locations (SIRI-VM & GTFS-RT, ~10s updates), and fares (NeTEx).
- **Access:** Browse/download UI + API (registration + key). Open data. Python `bods-client` available.
- **App ideas:** (1) National live bus-tracker map (a "where's my bus" outside London). (2) Rural bus-service-desert visualiser combining timetables with population. (3) Fare-comparison tool across operators on a corridor.
- **Caveats:** Data quality varies by operator; real-time coverage patchy in places. Registration required.
- **Source:** https://data.bus-data.dft.gov.uk/

### 10. NaPTAN (National Public Transport Access Nodes)
- **Publisher:** Department for Transport
- **Contents:** Every public-transport access point in GB — bus stops, rail/tram/metro/ferry/air terminals — with coordinates, identifiers, names. Daily updates. Companion to NPTG gazetteer.
- **Access:** New portal + API, download by area code or whole national set (CSV/XML). Free, OGL.
- **App ideas:** (1) "Nearest stop to any address" backbone for any transit app. (2) Accessibility map of stops with/without shelters or step-free access. (3) Stop-density vs population equity analysis.
- **Caveats:** It's infrastructure metadata (where you board), not services or times — pair with BODS/timetables.
- **Source:** https://www.data.gov.uk/dataset/ff93ffc1-6656-47d8-9155-85ea0b8f2251/naptan

### 11. Darwin / Network Rail Open Rail Data
- **Publisher:** Rail Delivery Group (Darwin) / Network Rail
- **Contents:** Real-time train running — arrival/departure predictions, platforms, delays, cancellations (Darwin Push Port XML), plus Network Rail movement/TD/schedule feeds.
- **Access:** Free after registration (Rail Data Marketplace / datafeeds.nationalrail.co.uk / opendata.nationalrail.co.uk). Open T&Cs since 2014.
- **App ideas:** (1) Live departure board for any station. (2) Delay-history "which service is chronically late" tracker. (3) Real-time train-position map for GB rail.
- **Caveats:** Registration and message-broker (STOMP) plumbing needed; steeper technical barrier than a REST API. High data volume.
- **Source:** https://www.nationalrail.co.uk/developers/darwin-data-feeds/

### 12. ORR Estimates of Station Usage
- **Publisher:** Office of Rail and Road
- **Contents:** Annual estimated entries/exits and interchanges for every GB rail station, from ticket-sales data. Long time series.
- **Access:** Excel/CSV download from ORR Data Portal. OGL.
- **App ideas:** (1) "Busiest and quietest stations" map (ghost stations with a handful of annual users make great stories). (2) Ridership growth/decline animation. (3) Station-usage vs local population/house-price cross-analysis.
- **Caveats:** Estimates (modelled from ticketing), annual not real-time; methodology revisions between years.
- **Source:** https://dataportal.orr.gov.uk/statistics/usage/estimates-of-station-usage

### 13. DfT / DVSA Anonymised MOT Test Results
- **Publisher:** DVSA
- **Contents:** Every MOT test since 2005 — make/model, first-use date, odometer reading, test result, and detailed failure/advisory reasons. Hundreds of millions of records.
- **Access:** Annual bulk downloads (open.data.dvsa.gov.uk). Separately, a live MOT History bulk/API product exists (requires approved API key).
- **App ideas:** (1) "How reliable is this car?" tool showing failure rates and common failure items by make/model/age. (2) Average-mileage-by-model curves for used-car buyers. (3) Rust-belt map correlating corrosion failures with coastal/gritted regions.
- **Caveats:** Anonymised (no VRM in bulk historic set). Very large files. The live per-vehicle API needs registration/approval.
- **Source:** https://www.data.gov.uk/dataset/c63fca52-ae4c-4b75-bab5-8b4735e1a4c9/anonymised-mot-tests-and-results

### 14. GB Road Traffic Counts (AADF)
- **Publisher:** Department for Transport
- **Contents:** Annual Average Daily Flow by vehicle type at ~48,000 count points on major + sampled minor roads, back to 1993, with coordinates. Also raw manual counts.
- **Access:** Zipped CSV bulk + interactive map at roadtraffic.dft.gov.uk. OGL.
- **App ideas:** (1) "How busy is my road" lookup with cars/HGV/cycle split. (2) Cycling-growth vs motor-traffic dashboard by area. (3) Pollution-proxy map from HGV flows near schools.
- **Caveats:** Estimates/models for minor roads; count points don't cover every road.
- **Source:** https://roadtraffic.dft.gov.uk/downloads

### 15. National Highways WebTRIS
- **Publisher:** National Highways
- **Contents:** Historic traffic sensor data (flow, speed, occupancy) from MIDAS/TMU/TAME loops across the English strategic road network (motorways + major A-roads), up to 10 years, monthly updates.
- **Access:** Free JSON REST API (no registration) at webtris.nationalhighways.co.uk/api. OGL.
- **App ideas:** (1) Motorway congestion-by-time-of-day heatmaps. (2) "Best time to travel" predictor for a given junction pair. (3) Speed-compliance visualiser in smart-motorway sections.
- **Caveats:** Historic not live; SRN only (not local roads); sensor gaps/outages.
- **Source:** https://webtris.nationalhighways.co.uk/api/swagger/ui/index

### 16. Street Manager Roadworks
- **Publisher:** Department for Transport
- **Contents:** Every utility street work and highway-authority road work in England — permits, locations, dates, works type, progress. ~3 million permits raised; every English highway authority participates.
- **Access:** Streaming/API open data (free account registration). data.gov.uk guidance.
- **App ideas:** (1) "Avoid the roadworks" live map and route-impact alerts. (2) "Who keeps digging up my street" utility-accountability tracker. (3) Planned-disruption calendar for a neighbourhood.
- **Caveats:** England only; registration required; the streaming feed needs plumbing.
- **Source:** https://www.gov.uk/guidance/find-and-use-roadworks-data

### 17. DVLA/DfT Vehicle Licensing Statistics (small-area)
- **Publisher:** DfT (from DVLA VID)
- **Contents:** Licensed vehicle counts by make/model, body type, fuel, and small geographies (LSOA/postcode-district via registered-keeper address). VEH0120 model-level tables; small-area tables via the Transport Statistics Geography Portal.
- **Access:** CSV/ODS downloads on GOV.UK, annual (May) + quarterly key tables. OGL.
- **App ideas:** (1) "EV adoption near me" map by postcode district. (2) Most popular car by neighbourhood (Range Rovers vs hatchbacks). (3) Fleet-age/emissions map for clean-air-zone planning.
- **Caveats:** Keeper address ≠ where driven (company registrations skew to HQ postcodes). Aggregated for privacy.
- **Source:** https://www.gov.uk/government/statistical-data-sets/vehicle-licensing-statistics-data-files

### 18. National Chargepoint Registry (successor open EV data)
- **Publisher:** OZEV/DfT (was Cenex-run)
- **Contents:** Public EV chargepoints — location, connector types, power, real-time availability, payment methods.
- **Access:** Was XML/CSV/JSON + API under OGL. **NCR was decommissioned 28 Nov 2024**; public chargepoint operators are now legally required to publish open data directly, and aggregators (e.g. UK Power Networks Open Data, Open Charge Map) carry it.
- **App ideas:** (1) Live "available charger near me" map with connector filtering. (2) Charging-desert map for route planning. (3) Operator-reliability scoreboard.
- **Caveats:** The central NCR is gone — source from operator open-data feeds / mandated APIs or aggregators now. Verify current canonical endpoint.
- **Source:** https://www.national-charge-point-registry.uk/ and https://ukpowernetworks.opendatasoft.com/explore/assets/ozev-ukpn-national-chargepoint-register/

### 19. CAA UK Flight Punctuality Statistics
- **Publisher:** Civil Aviation Authority
- **Contents:** On-time performance for 10 monitored UK airports and top ~75 routes — delay distributions by airline/route/month. Also airport passenger stats.
- **Access:** CSV downloads (caa.co.uk and data.gov.uk). Quarterly. OGL.
- **App ideas:** (1) "Which airline is least likely to delay my flight" comparison. (2) Route-level punctuality map. (3) Seasonal delay-risk forecaster for holiday planning.
- **Caveats:** Aggregated stats, not individual flights; methodology changed Oct 2024. For live flights use OpenSky (below).
- **Source:** https://www.caa.co.uk/data-and-analysis/uk-aviation-market/flight-punctuality/

### 20. Traffic Scotland Trunk Road Gritter Tracker
- **Publisher:** Transport Scotland
- **Contents:** Live GPS locations and recent trails of gritters on Scotland's trunk-road network (Nov–Mar), aggregating 9 operators' feeds. Famous punny gritter names (Gritney Spears, Sled Zeppelin).
- **Access:** Bespoke Esri API feeding the public map. Public-facing.
- **App ideas:** (1) "Has my road been gritted" checker. (2) Gritter-name leaderboard / novelty tracker (huge viral appeal each winter). (3) Coverage-gap map on icy nights.
- **Caveats:** Trunk roads only (local roads are council-run); seasonal; API is not a formally documented open endpoint — check terms.
- **Source:** https://www.traffic.gov.scot/gritter-tracker

---

## Health

### 21. NHS English Prescribing Dataset (EPD)
- **Publisher:** NHS Business Services Authority
- **Contents:** Every primary-care prescription dispensed in England — drug (BNF/SNOMED), quantity, cost, per GP practice, monthly. ~17 million rows/month. This is the data behind OpenPrescribing.
- **Access:** Open Data Portal CSV/ZIP + Data API. Monthly, ~2-month lag. OGL.
- **App ideas:** (1) "What does my GP practice prescribe" explorer with peer comparisons. (2) Antibiotic-stewardship or antidepressant-trend maps. (3) Branded-vs-generic waste/savings finder by area.
- **Caveats:** Primary care only (no hospital); practice-level not patient-level; huge volume. OpenPrescribing offers a friendlier pre-built API.
- **Source:** https://opendata.nhsbsa.net/dataset/english-prescribing-dataset-epd-with-snomed-code

### 22. Food Hygiene Ratings (FHRS API)
- **Publisher:** Food Standards Agency
- **Contents:** ~599,000 food establishments across England, Wales, Scotland and NI — hygiene rating (0–5), address, business type, inspection date, coordinates, per 363 local authorities.
- **Access:** Free REST API (XML/JSON, no registration/key) at api.ratings.food.gov.uk, plus bulk downloads. OGL.
- **App ideas:** (1) "Rate my takeaway" map filtering by min rating near you. (2) Zero-rated-restaurant watchlist / naming map. (3) Rating-trend tracker per venue over inspections. (Classic CrashMap-style build.)
- **Caveats:** Ratings reflect last inspection only (can be years old). Scotland uses a pass/improvement-required scheme, not 0–5.
- **Source:** https://api.ratings.food.gov.uk/help

---

## Environment, Weather & Energy

### 23. Environment Agency Real-Time Flood Monitoring & Rainfall
- **Publisher:** Environment Agency / Defra
- **Contents:** Live flood warnings/alerts and areas, plus ~3,000+ river/water-level & flow stations and ~1,000 telemetry rain gauges (15-min readings), with historic hydrology archive (billions of readings).
- **Access:** Free REST API (JSON), no registration. OGL (with attribution statement). Companion Hydrology and Tide Gauge APIs.
- **App ideas:** (1) "Is my house about to flood" live river-level + warning dashboard by postcode. (2) Rainfall-radar-style accumulation map. (3) Wild-swimming river-level safety checker.
- **Caveats:** Beta API; transfer frequency varies by site (more frequent in flood conditions). Levels are gauge readings, not property-level flood modelling.
- **Source:** https://environment.data.gov.uk/flood-monitoring/doc/reference

### 24. Environment Agency Bathing Water Quality
- **Publisher:** Environment Agency
- **Contents:** Water-quality classifications and weekly sample results (E. coli, intestinal enterococci) for ~400+ designated bathing waters (coast + inland) in England, May–Sept, plus pollution risk forecasts and bathing-water profiles.
- **Access:** Linked-data web API (JSON/XML/CSV/Turtle) at environment.data.gov.uk/bwq. OGL.
- **App ideas:** (1) "Is it safe to swim today" beach/river map with live sampling and pollution alerts. (2) Sewage-discharge correlation visualiser. (3) Season-long water-quality league table for swim spots.
- **Caveats:** Monitoring season only; weekly samples are point-in-time; designated sites only (not every beach/river).
- **Source:** https://environment.data.gov.uk/bwq/

### 25. Carbon Intensity API (NESO)
- **Publisher:** National Energy System Operator (with EDF Europe, Oxford, WWF, Met Office)
- **Contents:** GB electricity carbon intensity and generation mix (gas/wind/solar/nuclear/imports) — actual, and forecast 96+ hours ahead, national + 14 DNO regions, half-hourly.
- **Access:** Free REST API (JSON), no key. carbonintensity.org.uk. OGL.
- **App ideas:** (1) "Best time to run your dishwasher / charge your EV" greenest-hour widget. (2) Regional live generation-mix map. (3) Smart-home automation trigger for low-carbon periods.
- **Caveats:** Generation emissions only; forecasts are modelled; regional values are indicative.
- **Source:** https://carbonintensity.org.uk/

### 26. Elexon BMRS Insights (electricity system data)
- **Publisher:** Elexon
- **Contents:** Half-hourly GB generation outturn by fuel type (FUELHH), demand, balancing-mechanism unit output, imbalance prices, wind/solar forecasts, and more.
- **Access:** Free public API (no key) at developer.data.elexon.co.uk, JSON/streaming. BMRS Open Data Licence.
- **App ideas:** (1) Real-time "what's powering Britain right now" gauge. (2) Wind-vs-gas share animation across a day. (3) Power-station-level generation map (join to BMU locations).
- **Caveats:** Domain-heavy (energy trading terminology); some datasets are settlement estimates revised later.
- **Source:** https://bmrs.elexon.co.uk/

### 27. Met Office HadUK-Grid & Weather DataHub
- **Publisher:** Met Office (archive via CEDA)
- **Contents:** HadUK-Grid — gridded UK climate observations (temperature, rainfall, sunshine etc.) at 1km resolution, 1836–present. Weather DataHub — atmospheric model forecasts (Global 10km, UK 2km, ensembles) via API.
- **Access:** HadUK-Grid: free NetCDF download from CEDA Archive, OGL. DataHub: free tier up to 1GB/month, GRIB2, requires account.
- **App ideas:** (1) "How has my town's climate changed since 1900" local-warming-stripes generator. (2) Rainfall/sunshine record-breaker map. (3) Custom local weather-forecast visualiser.
- **Caveats:** HadUK-Grid is NetCDF (needs geospatial tooling); DataHub free tier is quota-limited; CEDA registration for archive.
- **Source:** https://www.metoffice.gov.uk/research/climate/maps-and-data/data/haduk-grid/

### 28. Defra National LIDAR Programme
- **Publisher:** Environment Agency / Defra
- **Contents:** High-resolution elevation — Digital Terrain and Surface Models (DTM/DSM) at 1m (composite) and finer, covering all of England (302 survey blocks, 2017–2023), ±15cm vertical accuracy. 5km GeoTIFF tiles.
- **Access:** Free download via environment.data.gov.uk/survey interactive map. OGL.
- **App ideas:** (1) 3D city/terrain flythroughs and building-height maps. (2) Solar-panel roof-suitability calculator. (3) "How high above sea level / at flood risk" property tool; hillshade relief maps for hikers.
- **Caveats:** Large raster files; requires GIS skills; England only.
- **Source:** https://environment.data.gov.uk/dataset/2e8d0733-4f43-48b4-9e51-631c25d1b0a9

---

## Nature & Biodiversity

### 29. NBN Atlas Species Occurrences
- **Publisher:** National Biodiversity Network Trust
- **Contents:** 220+ million UK species occurrence records (birds, plants, insects, mammals, invasives) with locations, dates, recorder, from thousands of datasets. UK is 2nd-largest GBIF publisher.
- **Access:** Web API (occurrence search, details, CSV/TSV download; WMS map tiles). Licences vary by dataset (many CC-BY/OGL-like); check per record.
- **App ideas:** (1) "What wildlife lives near me" species map by postcode. (2) Invasive-species (e.g. Asian hornet, Japanese knotweed) spread tracker. (3) Seasonal migration/first-sighting phenology visualiser.
- **Caveats:** Recording effort is biased (more records near people/reserves); some records blurred/access-restricted for sensitive species; licence per dataset varies.
- **Source:** https://docs.nbnatlas.org/

### 30. London Public Realm Trees
- **Publisher:** GLA / GiGL via London Datastore
- **Contents:** Locations and species of 1.1 million+ public trees across all 32 boroughs + City of London, TfL, Royal Parks etc., with size/age for some. Latest update May 2025.
- **Access:** CSV/GIS download, London Datastore + data.gov.uk. OGL.
- **App ideas:** (1) "Find the nearest [species] tree" / blossom-spotting map in spring. (2) Canopy-cover equity map by ward. (3) Pollen/allergy-risk planner by tree species distribution.
- **Caveats:** London only; not a complete inventory (collation ongoing, inconsistent borough formats).
- **Source:** https://data.london.gov.uk/dataset/local-authority-maintained-trees/

---

## Bonus: Reference, Civic & Quirky (worth knowing)

- **postcodes.io** — Free, no-auth UK postcode geocoding/lookup API serving ONS Postcode Directory + OS Open Names. Essential glue for turning any postcode into coordinates + admin/electoral/health geographies. https://postcodes.io/
- **Nomis / Census 2021** — ONS official census & labour-market stats to output-area level, via API (and `nomisr`). Backbone for any demographic choropleth. https://www.nomisweb.co.uk/
- **English Indices of Deprivation 2019 (IMD)** — LSOA-level deprivation deciles across 7 domains. Instant "deprivation map" layer; pairs with almost everything above. https://opendatacommunities.org/data/societal-wellbeing/imd2019/indices
- **Ordnance Survey OpenData** (OS Open Greenspace, Open Names, OpenMap Local, Open Roads, Boundary-Line) — free GB geospatial base layers under OGL. https://osdatahub.os.uk/downloads/open
- **Companies House** — free monthly bulk company snapshot (CSV), PSC bulk (JSON), free accounts data product, and a real-time Streaming API. Ideas: company-density maps, dissolved-company churn, PSC ownership-network graphs. https://chguide.co.uk/bulk-data/
- **Ofcom Connected Nations** — postcode-level fixed broadband and mobile coverage/speeds, annual, OGL. Ideas: "not-spot" map, broadband-speed-by-street lookup. https://www.ofcom.org.uk/phones-and-broadband/coverage-and-speeds/data-downloads2
- **DWP Stat-Xplore** — JSON API of welfare/benefit statistics (Universal Credit, PIP, Pension Credit etc.) to small-area level, free (rate-limited). Ideas: benefit-uptake maps. https://stat-xplore.dwp.gov.uk/webapi/online-help/Open-Data-API.html
- **Electoral Commission donations & spending register** — searchable political donations/loans (from July 2017). Ideas: "who funds my party/MP" money-flow visualiser. https://search.electoralcommission.org.uk/
- **IPSA MP staffing & business costs** — CSV downloads of every MP's expense claims. Ideas: MP-expenses comparison and outlier finder. https://www.theipsa.org.uk/mp-staffing-business-costs
- **UK Parliament / TheyWorkForYou** — Parliament's own APIs (Members, Divisions, Hansard, Bills) are free/open; TheyWorkForYou's own API is now paid (~£20/mo). Ideas: voting-record scorecards, "how did my MP vote". https://www.theyworkforyou.com/api/
- **OpenSky Network** — free (non-commercial) live + historic ADS-B flight tracking; feed the network for higher limits. Ideas: "what's that plane overhead", noise-over-my-house tracker. https://openskynetwork.github.io/opensky-api/
- **OpenBenches** — crowd-sourced memorial-bench map, 42k+ benches, free GeoJSON API (CC-BY-SA). Ideas: "memorial bench near me" strolling app; poignant-inscription explorer. https://openbenches.org/
- **Global Fishing Watch / EMODnet Human Activities** — free AIS-derived fishing-effort and maritime-activity APIs. Ideas: "fishing pressure in UK waters" map, offshore-wind vs fishing conflict visualiser. https://globalfishingwatch.org/our-apis/

---

## Practical notes for building

- **Geocoding glue:** postcodes.io + OS Open Names/Boundary-Line turn most of these (crime, prescribing, price paid) into mappable layers. Many datasets key on **LSOA / output area / postcode**, so a consistent lookup layer is the first thing to build.
- **Licence pattern:** the overwhelming majority are **OGL v3.0** (commercial use fine with attribution). Exceptions to watch: EPC (registration + personal-data terms), NBN Atlas (per-dataset licences), OpenSky (non-commercial), TheyWorkForYou API (paid), OpenBenches (CC-BY-SA).
- **Best "quick win" CrashMap-clones** (no-key REST API, mappable points, strong story): **Food Hygiene Ratings**, **Police street-level crime**, **EA flood/river levels**, **EA bathing water**, **Carbon Intensity**, **National Highways WebTRIS**, and **PlanIt planning applications**.
- **Highest "viral" potential:** Traffic Scotland gritter names, OpenBenches, bathing-water "safe to swim" alerts, and "what did my neighbours pay" (Price Paid).
