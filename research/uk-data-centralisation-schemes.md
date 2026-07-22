# UK Data Centralisation Schemes — Landscape Report (as of July 2026)

Stage 3 of the research: government/regulator-driven schemes that force or organise previously fragmented data into central open (or licensed) feeds — in the vein of the Fuel Finder scheme. Companion to the [dataset catalogue](uk-public-datasets-catalogue.md) and [viability assessment](uk-public-datasets-assessment.md).

**Scope note:** statuses verified via web search against official sources (gov.uk, FCA, Ofgem, Elexon, PDP, CAA) where possible. Gov.uk pages blocked direct fetching, so some detail comes from search summaries of official pages plus reputable secondary sources; anything not confirmed from an official source is flagged. The overarching legal enabler for most new schemes is the **Data (Use and Access) Act 2025 (DUAA)**, which received Royal Assent 19 June 2025 and contains both the Smart Data powers (Part 1) and the NUAR provisions.

---

## 1. Fuel Finder (the baseline)

- **Sponsor / legal basis:** DESNZ (with CMA as monitor/enforcer). Statutory scheme born from the CMA's 2023 road fuel market study; CMA's ongoing road-fuel monitoring function sits under the Digital Markets, Competition and Consumers Act 2024, with the scheme implemented via secondary legislation (exact SI name not verified).
- **What's centralised:** every UK petrol forecourt (~8,300 sites) must report price per fuel grade, forecourt details (address, operator, brand), amenities and opening hours to a designated aggregator — **VE3 Global Ltd** (£3m contract) — **within 30 minutes of a pump price change**. EPOS-integrated stations report via API automatically.
- **Status:** **Live.** Launched 2 February 2026; CMA's three-month grace period ended 1 May 2026, enforcement now active. Early "teething issues" reported (some stations publishing wrong prices, e.g. 1.3p/litre errors) — data quality is improving but not perfect.
- **Access model:** **Open and free to all third parties.** REST API with OAuth 2.0 client-credentials auth, plus a flat file published twice daily. Official onboarding via gov.uk: [Access the latest fuel prices and forecourt data via API or email](https://www.gov.uk/guidance/access-the-latest-fuel-prices-and-forecourt-data-via-api-or-email) and [Provide or access open data about road fuel prices](https://gov.uk/government/publications/provide-or-access-open-data-about-road-fuel-prices).
- **Consumer-app potential:** route-optimised fill-up planners, fleet cost tools, price-drop alerts. Ecosystem forming fast (PetrolPrices.co.uk, RAC/AA apps, fuel-finder.uk already integrated) but the amenity/opening-hours data and historic-price angle are underexploited.
- **Sources:** [Fuels Industry UK explainer](https://www.fuelsindustryuk.org/consumer-information/fuel-finder-scheme-essential-information-for-industry-and-consumers/), [Forecourt Trader on VE3 contract](https://forecourttrader.co.uk/news/government-contract-for-fuel-finder-scheme-awarded-to-ve3-global/704185.article), [Forecourt Trader on teething issues](https://forecourttrader.co.uk/news/fuel-finder-data-sees-drivers-told-petrol-costs-13p-a-litre-and-government-admits-to-teething-issues/715174.article), [VE3 Fuel Finder page](https://ve3.global/fuel-finder).

---

## 2. Smart Data 2035 Strategy (the umbrella programme)

- **Sponsor / legal basis:** DBT; Part 1 of DUAA 2025 gives ministers power to **compel** businesses to share customer and business data with authorised third parties.
- **What it is:** published **end of March 2026**, the strategy targets **5+ active smart data schemes by 2030, 20+ by 2035**, backed by ~£36m over four years. Ten sectors identified: **banking (payments), finance, energy, road fuels, property, retail, digital markets, transport, telecoms, agrifood**. Consultations in **banking, energy and property expected during 2026**, with regulations potentially 2027/28. No telecoms SI laid as of May 2026.
- **Why it matters:** this is the pipeline every other consumer-data scheme will come from. Watch DBT consultations in H2 2026.
- **Sources:** [Smart Data Strategy on GOV.UK](https://www.gov.uk/government/publications/smart-data-strategy) ([PDF](https://assets.publishing.service.gov.uk/media/69c11f9ed588c92c483e4b66/smart-data-strategy.pdf)), [CMS analysis](https://cms.law/en/gbr/legal-updates/smart-data-2035-the-uk-government-publishes-its-smart-data-strategy), [Gowling WLG on energy/property implications](https://gowlingwlg.com/en-gb/insights-resources/articles/2026/uk-smart-data-strategy-2035), [Global Government Finance summary](https://www.globalgovernmentfinance.com/uk-smart-data-2035-strategy/).

---

## 3. Open Banking → Open Finance & commercial VRP

- **Sponsor / legal basis:** FCA (with PSR being folded in); DUAA 2025 + HM Treasury legislation expected in 2026 granting the FCA formal open banking rule-making powers ("Long-Term Regulatory Framework" consultation due before end of 2026).
- **Status:**
  - FCA published **"Open finance: Our vision for a smart data future" (open finance roadmap) in April 2026**.
  - **Commercial Variable Recurring Payments went live Q1 2026** via the **UK Payments Initiative (UKPI)** — a scheme company formed by 31 firms — covering utilities, financial-services top-ups and payments to local/central government. FCA/PSR will assess industry adoption toward the end of 2026.
  - FCA **Smart Data Accelerator** (with Raidiam) sandboxing open-finance use cases (savings, investments, pensions, insurance data next).
- **Access model:** regulated ecosystem — FCA authorisation (AISP/PISP or agent-of model) needed to touch account data; not open data.
- **Consumer-app potential:** enormous but crowded and permissioned; solo devs typically build on top of an existing TPP (TrueLayer, GoCardless, Plaid). cVRP-based "smart bill payer"/subscription-switching apps are the fresh niche.
- **Sources:** [FCA open finance roadmap PDF](https://www.fca.org.uk/publication/corporate/open-finance-roadmap.pdf), [FCA statement on UKPI launch](https://www.fca.org.uk/news/statements/open-banking-launch-uk-payments-initiative-scheme), [PSR cVRP delivery update Dec 2025](https://www.psr.org.uk/media/xgjcblmb/cvrp-update-on-delivery-_-dec-2025.pdf), [Lewis Silkin on UKPI](https://www.lewissilkin.com/en/insights/2026/06/11/uk-payments-initiative-launches-new-open-banking-recurring-payments-scheme-102n1ql).

---

## 4. Pensions Dashboards Programme (MaPS)

- **Sponsor / legal basis:** DWP / Money and Pensions Service; Pensions Dashboards Regulations 2022 (+ FCA rules for providers).
- **What's centralised:** find-and-view of essentially **every UK pension pot** (state, DB, DC) via a central digital architecture. **70m+ records connected, ~85% of target coverage** as of mid-2026.
- **Status:** final **connection deadline 31 October 2026**. Public launch (MoneyHelper dashboard first) expected in **FY 2027-28**, with six months' notice of the go-live date. Commercial dashboards follow under FCA regulation.
- **Access model:** **closed.** No open API — data flows only to authorised dashboard providers, displayed to the individual user, no data export in initial phases. High regulatory bar (FCA-regulated dashboard operator status).
- **Consumer-app potential:** long-term huge (pension consolidation prompts, "lost pot" finders) but effectively inaccessible to a solo developer until commercial dashboard rules and any delegated-access model mature.
- **Sources:** [PDP connection deadline page](https://www.pensionsdashboardsprogramme.org.uk/connection/deadline), [PDP deadline Q&A](https://www.pensionsdashboardsprogramme.org.uk/publications/blogs/pensions-dashboards-connection-deadline-your-questions-answered), [Pensions Expert coverage](https://www.pensions-expert.com/dashboards/dashboards-update-connection-coverage-reaches-85-as-final-deadlines-approach/70257.article), [TPR guidance](https://www.thepensionsregulator.gov.uk/trustees/contributions-data-and-transfers/dashboards-guidance/when-your-scheme-needs-to-connect-with-dashboards).

---

## 5. National Underground Asset Register (NUAR)

- **Sponsor / legal basis:** DSIT (Geospatial Commission function, delivery involving Ordnance Survey); statutory footing under **DUAA 2025** (NUAR provisions incl. s.56 area).
- **What's centralised:** location/attribute data on **all buried pipes and cables** from every "undertaker" (utilities, telecoms, councils). Platform build operationally complete around end-2025.
- **Status:** implementation via **at least two tranches of regulations**. **Tranche 1 regulations consultation held (closed)**; a January 2026 geospatial blog set out the "comprehensive NUAR" vision and a proposed minimum information specification. Mandatory upload period **unlikely to start before spring 2026 at the earliest; enforcement unlikely before spring 2027**; full population expected as uploads flow through 2027. A **spring 2026 public consultation** on *expanding access* beyond safe-digging users was planned — not verified as launched by July 2026.
- **Access model:** **restricted** — currently limited to those planning/executing street works ("safe dig" purpose). Not open data; wider access (e.g. for conveyancing, insurance) is exactly what the 2026 consultation covers.
- **Consumer-app potential:** low for now (access-gated); watch the access-expansion consultation. B2B potential (utility strike avoidance, surveying) is where the ecosystem forms.
- **Sources:** [Geospatial blog — Royal Assent](https://gdsgeospatial.blog.gov.uk/2025/06/19/what-royal-assent-means-for-the-national-underground-asset-register), [Geospatial blog Jan 2026 — comprehensive NUAR](https://gdsgeospatial.blog.gov.uk/2026/01/28/towards-a-comprehensive-national-underground-asset-register-integrated-into-the-existing-ecosystem/), [Tranche 1 regulations consultation](https://www.gov.uk/government/consultations/national-underground-asset-register-tranche-1-regulations/national-underground-asset-register-tranche-1-regulations), [NUAR FAQs](https://www.nuar.uk/faqs), [Travers Smith analysis](https://www.traverssmith.com/knowledge/knowledge-container/the-new-national-underground-asset-register-what-does-it-mean-for-the-energy-infrastructure-sector/).

---

## 6. Planning Data Platform — planning.data.gov.uk

- **Sponsor / legal basis:** MHCLG. Participation currently funded/contractual rather than statutory (Digital Planning Improvement Fund: **£50k per LPA**); mandation powers exist in planning legislation but rollout is incentive-led (mandation status: not verified as commenced).
- **What's centralised:** planning/housing datasets from English LPAs normalised to national standards. Four priority datasets per LPA: **conservation areas, listed buildings, Tree Preservation Orders, Article 4 directions**; a **planning decision data specification** is in development (Jan 2026 blog).
- **Status:** **live and expanding** — 49 more LPAs joined in early 2026; coverage still partial across England's ~300 LPAs.
- **Access model:** **fully open** — bulk downloads, API, no auth, open licence.
- **Consumer-app potential:** "what constraints affect this house" checkers, extension-feasibility tools, planning-alert subscriptions. Ecosystem exists (Searchland, LandTech aimed at professionals) but consumer-grade tools are thin.
- **Sources:** [About the platform](https://www.planning.data.gov.uk/about/), [MHCLG Digital blog — decision data model](https://mhclgdigital.blog.gov.uk/2026/01/08/building-a-data-model-for-planning-decisions/), [MHCLG Digital blog — more LPAs join](https://mhclgdigital.blog.gov.uk/2026/01/12/more-local-planning-authorities-commit-to-making-their-planning-data-open-and-join-open-digital-planning), [Local Digital planning data](https://www.localdigital.gov.uk/digital-planning/planning-data/).

---

## 7. Home-buying data / Property Smart Data

- **Sponsor:** MHCLG + HM Land Registry (DBT for the smart data scheme angle).
- **Status & timeline:** October 2025 consultation → **government response and reform roadmap published June 2026** (Commons statement 22 June 2026). Committed: digital identity checks, e-signatures, **digital property logbooks and digital sales packs to become required** (legislation by end of this Parliament); **call for evidence in 2026** on data-sharing barriers; **consultation in 2027 on a property smart data scheme**; agent Code of Practice later in 2026. HMLR pilots of data-rich digital property packs report average **7 weeks pack-to-completion** and zero fall-throughs (HMLR's own figures — treat as promotional). HMLR's Local Land Charges migration passed 2m searches by March 2026.
- **Access model:** TBD — currently HMLR datasets (price paid, INSPIRE polygons, some licensed products) plus future logbook/pack standards. The property smart data scheme is the one to watch.
- **Consumer-app potential:** high later — "property passport" apps, move-readiness scores. Ecosystem (PropTech, Open Property Data Association) already positioning.
- **Sources:** [HMLR blog — upfront data](https://hmlandregistry.blog.gov.uk/2026/03/24/making-home-buying-and-selling-faster-with-upfront-data/), [Hansard 22 June 2026 roadmap statement](https://hansard.parliament.uk/commons/2026-06-22/debates/26062228000015/HomeBuyingAndSellingReformRoadmap), [MHCLG consultation](https://consult.communities.gov.uk/home-buying-and-selling/home-buying-and-selling-reform), [Propertymark summary](https://www.propertymark.co.uk/resource/home-buying-and-selling-roadmap-promises-robust-support-for-agents-as-sector-transforms.html).

---

## 8. Energy: MHHS, tariff data, heat networks

**a) Market-wide Half-Hourly Settlement (Elexon/Ofgem, under the BSC):**
- Elexon central systems went live **22 September 2025**; meter migration began October 2025 (2m+ done), **~80% expected migrated by October 2026**, completion May 2027 (M15), settlement cutover **July 2027** (M16). Elexon will process ~500bn half-hourly readings/year and is building a **Smart Data Repository** so consumers can consent to share consumption data with third parties — a genuine consented-data API opportunity from ~2027.
- Sources: [Elexon MHHS page](https://www.elexon.co.uk/bsc/operational/market-wide-half-hourly-settlement/), [Elexon Feb 2026 next steps](https://www.elexon.co.uk/2026/02/23/elexon-sets-out-the-next-steps-for-market-wide-half-hourly-settlement-at-utility-weeks-customer-first-forum-2026/), [S&P on Elexon data access plan](https://www.spglobal.com/energy/en/news-research/latest-news/electric-power/071124-britains-elexon-sets-out-market-wide-half-hourly-electricity-meter-data-access-plan).

**b) Tariff Data Specification / tariff interoperability (DESNZ → Retail Energy Code):**
- DESNZ confirmed the TDS will be governed under the REC; **SLC11C licence provisions and REC Schedule 35 implemented 18 May 2026**; **Phase 1a — public tariff pricing data via standardised supplier APIs — goes live 18 February 2027**. This is effectively "Fuel Finder for energy tariffs" and is under-noticed.
- Sources: [RECCo announcement](https://www.retailenergycode.co.uk/desnz-confirms-the-retail-energy-code-will-host-new-tariff-data-specification/), [Tariff Interoperability consultation](https://www.gov.uk/government/consultations/tariff-interoperability).

**c) Energy smart data scheme (DBT/DESNZ):** consultation expected during 2026 per Smart Data 2035; use cases include EV chargepoint accuracy, price-comparison switching, decarbonisation advice. Not yet legislated.

**d) Heat networks (Ofgem):** regulation went **live 27 January 2026** (Energy Act 2023 framework); **10 March 2026** guidance sets mandatory quarterly/annual data reporting by heat network operators. Regulatory data collection, **not** an open feed yet — but expect published market data. Sources: [Ofgem consumer protection guidance](https://www.ofgem.gov.uk/guidance/heat-networks-regulation-consumer-protection), [Ofgem blog — regulation now live](https://www.ofgem.gov.uk/blog/heat-networks-regulation-now-live).

**e) Open Energy / Icebreaker One & Ofgem Data Sharing Infrastructure:** Ofgem's DSI is in MVP/pilot phase with IB1 as governance advisory partner; active 2026 consultations on digitalisation governance. Infrastructure-level, pre-product. Source: [IB1 responses](https://ib1.org/2026/02/04/ib1-response-to-ofgems-energy-digitalisation-governance-architectural-coordination-letter/).

---

## 9. Water: real-time storm overflow data

- **Sponsor / legal basis:** Defra/Ofwat-regulated duty on water companies under **s.81 Environment Act 2021** (near-real-time publication: discharge start location within 1 hour, end within 1 hour), extended toward emergency overflows by the **Water (Special Measures) Act 2025** (s.2 duties; commencement of the extension not fully verified).
- **What's centralised:** Event Duration Monitoring from all ~15,000 storm overflows in England, surfaced through the industry's **Stream** open data platform (11 water companies, built with IB1/Esri) and the **National Storm Overflow Hub** map.
- **Status:** **live** — the s.81 duty and the national hub/API are operational.
- **Access model:** **open API + open datasets** on Stream (open licences).
- **Consumer-app potential:** swim/paddle safety alerts, angling/river-health apps, accountability dashboards. Incumbents exist (Surfers Against Sewage's Safer Seas app, Top of the Poops) but hyperlocal alerting and combined water-quality mashups (with sonde data coming under s.82 continuous water-quality monitoring from 2026) are open ground.
- **Sources:** [Stream storm overflows page](https://www.streamwaterdata.co.uk/pages/storm-overflows-data), [s.81 text](https://www.legislation.gov.uk/ukpga/2021/30/section/81/data.htm?view=plain), [IB1 Stream](https://ib1.org/water/stream/), [Commons Library briefing Mar 2026](https://researchbriefings.files.parliament.uk/documents/CBP-10027/CBP-10027.pdf).

---

## 10. Transport

- **Find Transport Data** (DfT): live metadata catalogue, roads-first, expanding to other modes — [findtransportdata.dft.gov.uk](https://findtransportdata.dft.gov.uk/).
- **Bus Open Data Service**: mature, mandated (Bus Services Act 2017 regs) — timetables (TransXChange), live locations (SIRI-VM), fares (NeTEx), free with registration — [data.bus-data.dft.gov.uk](https://data.bus-data.dft.gov.uk/).
- **Rail Data Marketplace** (Rail Delivery Group/DfT): consolidating rail feeds; **National Rail Data Portal retiring early 2026** with feeds migrating to RDM (APIs, Kafka streams, files; mostly free, some premium e.g. fares APIs). Watch Great British Railways for further centralisation. Sources: [RDM](https://www.raildeliverygroup.com/our-services/essential-services/rail-data-marketplace.html), [Open Rail Data Wiki](https://wiki.openraildata.com/index.php/Rail_Data_Marketplace).
- **MaaS / micromobility:** DfT MaaS Code of Practice is **voluntary**; e-scooter trials extended to **May 2028**; no statutory mobility data mandate yet. ([Pinsent Masons](https://www.pinsentmasons.com/out-law/news/uk-mobility-as-a-service-code-targets-improved-data-sharing))
- **Airspace/drones:** CAA UTM certification consultation **open until 28 August 2026**; BVLOS roadmap iterating; data-sharing between UTM providers and ATM is being designed now — pre-commercial, B2B. ([Coptrz on the CAA UTM consultation](https://shop.coptrz.com/blogs/news/caa-utm-consultation-and-what-it-means-for-uk-bvlos-drone-flights))

---

## 11. Health (brief — not consumer-open)

**NHS Federated Data Platform** (NHS England, Palantir-built): drive for provider onboarding by April 2026; the Medium Term Planning Framework expects **all trusts and ICBs onboarded by 2028/29**. For direct care/population health only; external research goes through the **NHS Research Secure Data Environment Network** (accredited-researcher access, never open). No consumer-app surface. Sources: [NHS England FDP](https://www.england.nhs.uk/digitaltechnology/nhs-federated-data-platform/), [FDP FAQs](https://www.england.nhs.uk/digitaltechnology/nhs-federated-data-platform/fdp-faqs/).

---

## 12. National Data Library (DSIT)

- **Status:** slower and vaguer than billed. In practice a **relaunch/extension of data.gov.uk**, backed by £100m+ from the Spending Review. As of **June 2026** only non-personal aggregated data is available; a kickstarter pilot is connecting **health, education and childcare data in Hammersmith & Fulham, Leeds and Liverpool**. DSIT promised fuller detail in spring 2026; substantive new datasets for developers: not yet.
- **Sources:** [data.gov.uk/about](https://www.data.gov.uk/about/), [Global Government Forum on launch](https://www.globalgovernmentforum.com/uk-launches-national-data-library-with-early-years-kickstarter-project/), [Computer Weekly](https://www.computerweekly.com/news/366637775/UK-governments-National-Data-Library-works-up-steam).

---

## 13. Retail / groceries price transparency

- **No mandatory scheme yet.** The CMA published a **discussion paper on smart data and price transparency schemes** (drawing lessons from fuel/open banking), and **retail is one of the ten Smart Data 2035 sectors** — but as of mid-2026 there is no supermarket-price equivalent of Fuel Finder, only the existing unit-pricing enforcement work and the concluded loyalty-pricing investigation (Nov 2024, found loyalty prices genuine). Treat "Open Groceries" as a 2027+ possibility to monitor via DBT retail-sector consultation.
- **Sources:** [techUK on the CMA discussion paper](https://www.techuk.org/resource/cma-discussion-paper-smart-data-and-price-transparency-schemes.html), [Lewis Silkin on loyalty investigation](https://www.lewissilkin.com/insights/2024/11/27/cma-finds-that-supermarket-loyalty-schemes-offer-essentially-genuine-savings-on-y-102jppb).

---

## 14. Rental housing: Private Rented Sector Database

- **Sponsor / legal basis:** MHCLG; **Renters' Rights Act 2025**.
- **What's centralised:** compulsory national register of **every private landlord and rental property in England**, keyed to UPRNs, with contact details, property info and safety certificates (gas, electrical, EPC). Penalties: £7,000 first civil penalty, up to £40,000/prosecution; unregistered landlords barred from most s.8 possession claims.
- **Status:** Phase 2 of the Act's rollout — database **expected operational late 2026**, registration phased through 2027. (Timeline from the government's implementation roadmap as reported by law firms; exact go-live date not yet fixed.)
- **Access model:** **publicly searchable** record promised; whether a public API exists is **not yet specified** — unverified.
- **Consumer-app potential:** "check your landlord" tools, rental due-diligence layered onto listings, council-enforcement dashboards. No incumbent ecosystem yet — genuinely greenfield, but access mechanics unknown.
- **Sources:** [Hogan Lovells on the implementation roadmap](https://www.hoganlovells.com/en/publications/renters-rights-act-implementation-roadmap-now-published), [Goodlord explainer](https://blog.goodlord.co/understanding-the-private-rented-sector-database), [mydeposits explainer](https://www.mydeposits.co.uk/content-hub/renters-rights-act-the-new-private-rented-sector-database/).

---

## 15. Gambling (brief)

**GamProtect** single customer view (launched 11 September 2024): operators share data on at-risk customers; industry-run, ICO-blessed, **not open data and no consumer-app surface**. Statutory levy (~£90–100m/yr, first invoiced 1 Sept 2026) funds harm research. Relevant only as a data-centralisation precedent. Sources: [NEXT.io on ICO approval](https://next.io/news/ico-approves-data-sharing-for-gambling/), [Gambling Commission levy guidance](https://www.gamblingcommission.gov.uk/print/statutory-gambling-levy).

---

## 16. EU schemes affecting the UK market (brief)

- **FiDA (Financial Data Access Regulation):** still in trilogue as of mid-2026; adoption expected ~mid-2026, phased application from late 2027+. Extends open banking to investments, pensions, insurance, mortgages EU-wide. UK-serving fintechs with EU customers will need dual-track compliance; also competitive pressure on the FCA's open finance timetable. ([Bankenverband trilogue note](https://bankenverband.de/en/digital-world/trilogue-negotiations-framework-financial-data-access-fida-regulation), [Capco primer](https://www.capco.com/intelligence/capco-intelligence/fida-primer-for-2026-and-beyond))
- **EU Data Act** (applicable since Sept 2025): connected-device/IoT data portability — affects UK manufacturers selling into the EU; may seed comparable UK IoT-data expectations.
- **PSD3/PSR1:** EU payments framework overhaul progressing on a 2026+ timeline; will reshape API standards that UK open banking historically tracked.

---

# Top 5 for an early-mover solo developer (ranked)

1. **Fuel Finder** — live today, genuinely open (OAuth2 REST API + flat files, free), fresh enough (enforcement only since May 2026) that data-quality tooling, historic-price analytics, alerts and fleet niches are unclaimed even though consumer comparison incumbents exist.
2. **Storm overflow real-time data (Stream / s.81 duty)** — live, open API, statutory near-real-time freshness, passionate user base (swimmers, anglers, campaigners); incumbents exist but hyperlocal alerting and cross-dataset mashups (bathing water + s.82 water-quality sondes from 2026) are open.
3. **Energy tariff data (REC Tariff Data Specification)** — mandated standardised supplier pricing APIs go live **18 February 2027**; almost no consumer-facing developers are watching this. Building now = day-one tariff comparison/switch-timing tools without scraping. Pair with Elexon's consented half-hourly consumption data (Smart Data Repository, ~2027) for "right tariff for your actual usage."
4. **planning.data.gov.uk** — live, fully open, standardised, and growing LPA coverage through 2026; consumer-grade property-constraint and planning-alert apps are underbuilt relative to the B2B proptech incumbents.
5. **Private Rented Sector Database** — operational late 2026 with public searchability; zero incumbent ecosystem. Higher risk (access mechanics/API unconfirmed), but a "check your landlord" product has obvious demand from ~11m renters if the data is programmatically reachable.

*Near-misses:* Rail Data Marketplace (accessible but mature/crowded); pensions dashboards (huge but access-gated behind FCA authorisation until at least 2027-28); property smart data scheme (promising but consultation not until 2027).
