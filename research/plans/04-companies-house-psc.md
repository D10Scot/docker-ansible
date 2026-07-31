# Company Ownership Network Explorer — Plan & Decision Document

**Dataset:** Companies House bulk company data (Prod217) + PSC (People with Significant Control) bulk data
**Proposed product:** Ownership-network graph visualiser + company-density map
**Prior assessment rank:** #4, verdict WEDGE, viability 6/10
**This document:** stress-test of that verdict
**Date of research:** 31 July 2026

---

## 1. Decision summary

**Verdict: DON'T BUILD** (as specified — a public ownership-network graph visualiser over PSC data).

**Confidence: Medium-High (7/10).**

**Rationale.** The prior assessment's WEDGE verdict rests on two assumptions that did not survive verification. First, it assumed the ownership graph is *in* the data and merely needs rendering. It is not. I verified against Companies House's own OpenAPI models that a corporate PSC's `registration_number` is an **optional free-text string** — not a validated company number — sitting next to a free-text `place_registered`; only `legal_authority` and `legal_form` are required. There is separately **no global identifier for a PSC individual**: the same person appearing on ten companies produces ten unrelated records, and ECCTA's new personal code is explicitly *not* published. So both node-identity problems — company→company and person→person — are unsolved entity-resolution problems, not rendering problems. Every serious practitioner I examined confirms this: Global Witness/DataKind resolved corporate PSCs with a hardcoded list of UK-ish strings and documented that leading zeros are stripped from company numbers, creating duplicate nodes; a purpose-built canonical PSC→BODS mapper published in June 2026 assigns corporate registration numbers the scheme `"unknown"`; OpenSanctions emits the number unresolved and defers to downstream entity resolution. Second, the assessment assumed the graph-visualisation niche is underserved. Fresh searches show **Bringo** (free tier, relationship map over shareholders/directors/PSCs, hourly refresh), **Endole** (group structure), **DataLedger** (ownership chains via API, from £10/mo), **OpenCorporates** (44 staff, 204M companies), and **OpenSanctions** (`gb_coh_psc`, entity-resolved, free to download) all occupying it. The one genuine opening — Open Ownership closed its Register on 29 November 2024 — is better read as a warning: a funded transparency NGO with lawyers ran this exact product for seven years and shut it down. Layered on top is the heaviest legal load in the whole catalogue: you would be a UK GDPR controller republishing ~15 million records of personal data, **without** the DPA 2018 Sch 2 Pt 1(5) exemption that Companies House itself relies on to refuse erasure requests, while ECCTA's expanding suppression regime means a stale snapshot can re-expose an at-risk person's address that CH has deliberately removed. A narrow, defensible variant exists (§5.4: corporate-only edges plus a company-density map, zero individuals) and is worth 10–15 days if the itch must be scratched, but it is a much smaller product than the one proposed and should not be ranked #4.

---

## 2. The opportunity

### The problem, stated honestly

"Who actually owns this company?" is a real and frequently-asked question. Companies House publishes the answer in pieces — a PSC list per company, on separate pages, with no links between them — and answering it for a structure more than one layer deep means manually opening a chain of company pages and eyeballing names. Four groups feel this:

- **Investigative journalists** tracing money, property, or influence through layered structures.
- **Due-diligence / AML-KYB analysts** establishing ultimate beneficial ownership for onboarding.
- **Property and landlord researchers** wanting to know who is behind an LLP that owns 40 flats.
- **Curious citizens** checking a landlord, employer, or a company that has just gone bust owing them money.

The manual pain is real. That is not in dispute.

### Why now — and why the "why now" is weak

The genuine timing arguments:

- **Open Ownership closed its Register on 29 November 2024**, removing the best-known free UK/global beneficial-ownership graph. Its underlying data remains downloadable at `bods-data.openownership.org`, but the *interface* is gone.
- **ECCTA 2023 identity verification became mandatory on 18 November 2025**, with all existing directors and PSCs required to verify by 18 November 2026. Records now carry a verification-status flag, so "which PSCs are unverified?" becomes a newly answerable and newsworthy question during 2026.
- Beneficial-ownership transparency remains a live political topic.

The counter-arguments to "now" are stronger:

- The ECCTA rollout is simultaneously **shrinking** what is publishable. The suppression regime widened on 27 January 2025 and again on 21 July 2025, and CH has signalled that unverified records may eventually be hidden from search. The direction of travel for a republisher is *less* data and *more* obligation, not more.
- Commercial entry into this space accelerated over 2024–26 (Bringo, DataLedger, HouseMetric, landregistry.company, homedata.co.uk). This is a market being actively colonised, not one lying fallow.

**Net:** a real user pain, a weak and deteriorating "why now".

---

## 3. Data deep dive

### 3.0 What I could and could not test

Be clear about method. **This environment's egress policy blocked all direct HTTP to `*.companieshouse.gov.uk`, `*.company-information.service.gov.uk`, `gov.uk` and most third-party sites** (403 at CONNECT from the policy proxy), and the WebFetch tool returned 403 for every URL including `example.com`. I therefore could **not** issue live HEAD requests against the bulk files or exercise the REST API with a key.

What I *could* do, and did, was verify against primary and near-primary artefacts reachable over GitHub:

| # | What I did | Source |
|---|---|---|
| 1 | Cloned and parsed Companies House's own OpenAPI model definitions for PSC resources | `companieshouse/specs.developer.ch.gov.uk` → `swaggertooling/openapi-pipeline/src/test/resources/spec/pscModels.json` |
| 2 | Fetched and counted CH's official PSC enumeration file | `raw.githubusercontent.com/companieshouse/api-enumerations/master/psc_descriptions.yml` |
| 3 | Fetched and parsed CH's official constants enumeration | `.../api-enumerations/master/constants.yml` |
| 4 | Cloned Global Witness / DataKind UK's PSC graph-build code and README | `Global-Witness/the-companies-we-keep-public` |
| 5 | Cloned a June-2026 canonical PSC→BODS mapper | `StephenAbbott/bods-mapper` |
| 6 | Fetched OpenSanctions' production CH ingest parser | `opensanctions/opensanctions` → `datasets/gb/coh/psc_parse.py` |
| 7 | Cloned the CH Guide documentation source (the site itself was unreachable) | `mrbrianevans/ch-guide` |
| 8 | Cloned OpenOwnership's PSC ingester, which contains an **archived copy of the real `en_pscdata.html` download page** (snapshot dated 2022-02-09) | `openownership/register-ingester-psc` → `spec/fixtures/files/en_pscdata.html` |

Anything below marked *(reported, not directly observed)* comes from search results rather than my own fetch. Live file sizes are the main casualty.

---

### 3.1 Product A — Basic Company Data (Prod217), monthly CSV

**Access.** No key, no registration. Landing page `http://download.companieshouse.gov.uk/en_output.html`; direct template:

```
http://download.companieshouse.gov.uk/BasicCompanyDataAsOneFile-YYYY-MM-01.zip
```

Also published in multi-part form. Released **monthly**, always named for the 1st of the month. Note the release is not always available on the 1st — a robust fetcher must fall back to the previous month. OpenSanctions' production crawler does not use the template at all; it scrapes the landing page for the link containing `BasicCompanyDataAsOneFile`, which is the more reliable pattern.

**Schema (verified, 55 columns).** Header observed verbatim:

```
CompanyName, CompanyNumber, RegAddress.CareOf, RegAddress.POBox,
RegAddress.AddressLine1, RegAddress.AddressLine2, RegAddress.PostTown,
RegAddress.County, RegAddress.Country, RegAddress.PostCode,
CompanyCategory, CompanyStatus, CountryOfOrigin, DissolutionDate,
IncorporationDate, Accounts.AccountRefDay, Accounts.AccountRefMonth,
Accounts.NextDueDate, Accounts.LastMadeUpDate, Accounts.AccountCategory,
Returns.NextDueDate, Returns.LastMadeUpDate,
Mortgages.NumMortCharges, Mortgages.NumMortOutstanding,
Mortgages.NumMortPartSatisfied, Mortgages.NumMortSatisfied,
SICCode.SicText_1 … SicText_4,
LimitedPartnerships.NumGenPartners, LimitedPartnerships.NumLimPartners,
URI,
PreviousName_1.CONDATE, PreviousName_1.CompanyName … PreviousName_10.*,
ConfStmtNextDueDate, ConfStmtLastMadeUpDate
```

Quirks worth knowing before you write a parser: the header has **inconsistent leading spaces** on some column names (OpenSanctions calls `.strip()` on every key for this reason); `CompanyNumber` is a **string with significant leading zeros** (`"07687209"`) and must never touch an integer type; dates are `DD/MM/YYYY`; `SICCode.SicText_N` packs code and description into one field as `"70229 - Management consultancy activities…"`.

**Enumerations (verified from CH's own `constants.yml`).** `CompanyStatus` has 12 canonical values (`active`, `dissolved`, `liquidation`, `receivership`, `converted-closed`, `voluntary-arrangement`, `insolvency-proceedings`, `administration`, `open`, `closed`, `registered`, `removed`). `CompanyCategory`/`company_type` has **37** values, including `registered-overseas-entity`, `llp`, `limited-partnership`, `scottish-partnership`.

**Volume.** The register held **5,479,045 companies at 31 March 2026** (CH official statistics, FYE2026, up 0.94% on FYE2025's 5.43M), against 815,280 incorporations and 787,261 dissolutions in the year. The bulk file covers companies on the register, so ~5.5M rows. Size: **~400MB ZIP / ~2GB CSV** *(documented figure, accurate as of 2021 — scaling by register growth suggests roughly 450–500MB / ~2.5GB today; not directly observed)*.

**Fitness for purpose.** Excellent, and unambiguously the strong half of this dataset. `RegAddress.PostCode` joins cleanly to postcodes.io or the ONS NSPL for lat/lon, so the **company-density map is trivially feasible** — as is the far more interesting derived metric, *registrations per address*, which surfaces the "company factory" mass-registration addresses that reliably make news.

**What it does not contain:** any parent/subsidiary field, any shareholder register, any officer data. There is no ownership signal in this file at all.

---

### 3.2 Product B — PSC snapshot, daily JSON Lines

**Access.** No key, no registration. Landing page `http://download.companieshouse.gov.uk/en_pscdata.html`. Two forms:

```
# single file
http://download.companieshouse.gov.uk/persons-with-significant-control-snapshot-YYYY-MM-DD.zip

# chunks, 500,000 records each
http://download.companieshouse.gov.uk/psc-snapshot-YYYY-MM-DD_{I}of{T}.zip
```

**Cadence: daily**, published before 10:00 GMT. Critically, **every file is a full snapshot, overwritten daily — there is no PSC delta/update file.** Incremental change detection requires either diffing consecutive snapshots yourself or running the Streaming API (§3.4). This is the single biggest driver of ongoing infrastructure cost.

**Format.** Newline-delimited JSON. One record per line, wrapped:

```json
{
  "company_number": "09145694",
  "data": {
    "address": {"premises":"2","address_line_1":"St. Andrews Road",
                "locality":"Henley-On-Thames","postal_code":"RG9 1HP","country":"England"},
    "ceased_on": "2018-05-14",
    "country_of_residence": "England",
    "date_of_birth": {"month": 2, "year": 1977},
    "etag": "3b8caf795c03af63921e381f7bb8300a51ebb73d",
    "kind": "individual-person-with-significant-control",
    "links": {"self": "/company/09145694/persons-with-significant-control/individual/bIhuKnMFctSnjrDjUG8n3NgOrlU"},
    "name": "Mrs Nga Thanh Wildman",
    "name_elements": {"title":"Mrs","forename":"Nga","middle_name":"Thanh","surname":"Wildman"},
    "nationality": "Vietnamese",
    "natures_of_control": ["ownership-of-shares-50-to-75-percent"],
    "notified_on": "2016-04-06"
  }
}
```

The **last line of the last chunk is a trailer record**, not a PSC — parsers must skip it:

```json
{"data":{"kind":"totals#persons-of-significant-control-snapshot",
         "persons_of_significant_control_count":9792999,
         "statements_count":627924,"exemptions_count":60,
         "generated_at":"2022-06-28T03:40:50+01:00"}}
```

**Record kinds (verified against OpenSanctions' production parser).** Nine `kind` values in circulation:

| kind | maps to |
|---|---|
| `individual-person-with-significant-control` | natural person |
| `corporate-entity-person-with-significant-control` | company (RLE) |
| `legal-person-person-with-significant-control` | other legal person |
| `super-secure-person-with-significant-control` | all particulars withheld by court order |
| `individual-beneficial-owner` | ROE-era natural person |
| `corporate-entity-beneficial-owner` | ROE-era company |
| `legal-person-beneficial-owner` | ROE-era legal person |
| `persons-with-significant-control-statement` | a statement *instead of* a PSC |
| `exemptions` | exemption record |

The `*-beneficial-owner` kinds carry Register of Overseas Entities records into the same file. Note also that OpenSanctions' parser now explicitly ignores an `identity_verification_details` key — **the ECCTA verification data is already appearing in these records.**

**Enumerations (verified by fetching CH's own file).** `psc_descriptions.yml` contains exactly:

- **86** `natures_of_control` codes (with 86 matching `short_description` strings)
- **28** `statement_description` values
- **2** `super_secure_description` values

These are far richer than "owns 25–50%". Codes distinguish direct holdings from holdings *as trustee of a trust* (`…-as-trust`) and *as member of a firm* (`…-as-firm`), and carry a separate ROE-specific family (`ownership-of-shares-more-than-25-percent-registered-overseas-entity`). Any credible product must render all 86, because the trust variants are precisely the ones investigators care about.

**Volume.** From the **archived real download page dated 2022-02-09** (verified in OpenOwnership's test fixtures): **20 chunks** — so ≤10M records, consistent with the 9,792,999 trailer count above. *(Reported, not observed:* a 2026-02-13 snapshot listed **31 chunks of 67–68MB each** — implying **~2.1GB zipped, ~11GB unzipped, and ~15M records**, a ~55% growth since 2022.) Documented per-chunk figures: ~65MB zipped / ~370MB unzipped / 500,000 records.

Not every record is a PSC: the trailer above shows 627,924 statements and 60 exemptions alongside 9.79M PSCs, so filtering is required before any count is quoted publicly.

**Ingest cost, concretely.** One academic pipeline records that streaming the 2021 JSONL into R took **about 2 hours**. A tuned Python/Rust ingest into Postgres should manage 15M lines in 15–40 minutes on a mid-range VPS, but this is a **daily** job over ~2GB of downloads, and it is a *full reload* every time.

---

### 3.3 THE CRUX — can ownership chains actually be reconstructed?

This is the question the whole idea turns on. **The answer is no, not reliably, and the gap is structural rather than incidental.** There are two independent failures.

#### 3.3.1 Company → company: the corporate PSC identifier is free text

I parsed Companies House's own OpenAPI model. The `corporateEntityIdent` object — the `identification` block on every corporate PSC — is defined as:

| field | type | required? |
|---|---|---|
| `legal_authority` | string | **yes** |
| `legal_form` | string | **yes** |
| `place_registered` | string | no |
| `registration_number` | string | no |
| `country_registered` | string | no |

Read that carefully. The two **required** fields are the two that are useless for linking. `registration_number` — the only field that could act as a foreign key — is **optional**, is typed as a bare `string`, is described only as "the registration number of the corporate entity with significant control", and is not constrained to be a Companies House number. It may legitimately be a Delaware file number, a BVI company number, a Jersey registry number, or nothing at all. `legal_person`'s `legalPersonIdent` is worse: `legal_authority` and `legal_form` only, with **no registration number field whatsoever**.

There is no `identification_type` discriminator on this object. CH's `constants.yml` does define an `identification_type` enumeration (`uk-limited-company`, `eea`, `non-eea`, `other-corporate-body-or-firm`, `registered-overseas-entity-corporate-managing-officer`, `limited-partnership-corporate-partner`) — but it is used on *other* resources (notably ROE corporate officers), not on the classic corporate-PSC `identification` block. *(I could not exhaustively confirm which PSC record subtypes carry it; flagged in §12.)*

To resolve a corporate PSC to a company you must therefore parse **free text**. Here is exactly what Global Witness and DataKind UK did, verbatim from their published notebook:

```python
def create_target_company_uid(x):
    uk_identifiers = ['Companies House','England','Wales','Companies House',
                      'United Kingdom','Scotland']
    if any(i in x['identification.place_registered'] for i in uk_identifiers) \
       and x['identification.registration_number'] != '':
        return x['identification.registration_number'].upper()
    elif any(i in x['identification.place_registered'] for i in uk_identifiers) \
       and x['identification.registration_number'] == '':
        return x['name'] + '_' + x['identification.place_registered'].replace(' ','_')
    else:
        return x['name'] + '_' + x['identification.place_registered'].replace(' ','_') \
               + '_' + x['identification.registration_number'].upper()
```

A substring check against six hardcoded strings, with a name-concatenation fallback. Note the duplicate `'Companies House'` in the list — this is exploratory research code, not a resolver. And their own README documents the failure mode:

> **Corrupt company numbers in PSC data** — In the PSC register leading zeros are occasionally removed from company numbers for UK corporate PSCs. These leads to duplicate companies appearing in the graph.

That is fatal in a specific way: `1234567` and `01234567` are *different nodes* in a naive graph, so the chain silently breaks in the middle rather than failing loudly. Zero-padding to 8 characters fixes the common case but breaks the many valid **prefixed** company numbers (`SC`, `NI`, `OC`, `SO`, `NC`, `FC`, `OE`, …) that must not be padded.

Two independent, more recent implementations confirm nothing has improved:

- **`bods-mapper` (June 2026)**, the canonical shared mapper extracted from the OpenCheck project, emits the corporate identifier as `{"id": reg_no, "scheme": "unknown", "schemeName": place_registered}`. A dedicated, current, purpose-built mapper declares the scheme **unknown** because it cannot determine which register the number belongs to.
- **OpenSanctions' production parser** writes `registration_number` onto a standalone `Company` entity and makes **no attempt** to link it to the CH company; resolution is deferred entirely to OpenSanctions' downstream entity-resolution engine.

**Conclusion:** corporate PSC → company is a **fuzzy record-linkage problem** requiring number normalisation, name normalisation, jurisdiction inference from free text, and confidence scoring. It is not a join.

#### 3.3.2 Person → person: there is no PSC identifier at all

This second failure is less discussed and at least as damaging.

The `links.self` URI ends in an opaque id (`bIhuKnMFctSnjrDjUG8n3NgOrlU`). It is scoped to `/company/{number}/…` — it identifies *this PSC entry on this company*, not the human. `bods-mapper` confirms the practitioner reading by constructing local ids as `f"{number}:psc:{pid}"`, deliberately namespacing by company number.

Global Witness's README states the consequence plainly:

> **Deduplication of PSCs** — Companies House does not supply a unique identifier for PSCs, therefore we have used a proxy unique identifier by combining first name, last name, month and year of birth and address. This is a conservative deduplication as many PSCs will use different addresses across different filings.

The proxy key is `forename + surname + month/year of birth` (+ address). The public register shows **only month and year of birth** — the day is suppressed — giving roughly 1-in-1,200 discriminating power on top of a name. For a common British name this produces **false merges** (two different David Smiths born March 1975 collapse into one node, fabricating a connection between unrelated companies) and, because addresses and name spellings drift between filings, simultaneous **false splits**. CH itself does not even link a person's *director* record to their *PSC* record: "Joe Bloggs" as director and "Mr Joe Bloggs" as PSC are two different people to Companies House.

**Does ECCTA fix this?** No. The identity-verification regime issues each verified individual an 11-character **personal code** (format `AB1-23CD-4EF4`) that is genuinely person-scoped and stable across all their roles. But it is **confidential and not published** — the public register shows only a *verified* indicator, not the code. So post-ECCTA you gain a boolean quality flag and still have no join key. This is worth stating clearly because it is the obvious thing a reader will hope solves the problem, and it does not.

#### 3.3.3 What this means for the product

The headline feature — "click a company, walk up the ownership chain to the ultimate owner" — is **not a visualisation feature. It is an entity-resolution product.** The rendering is a week; the resolution is the whole job, and it is never finished.

That reframing carries a consequence that should stop most builders: **when your resolver is wrong, the resulting page asserts, in public, that a named real person controls a company they have nothing to do with.** That is not a rendering bug. It is a defamation exposure and a UK GDPR accuracy breach (Art. 5(1)(d)) simultaneously, on a page you generated automatically 15 million times over.

Three further ceilings on what the graph can ever show, independent of resolution quality:

- **The 25% threshold.** PSC is *more than* 25% — not 25% or more. Four equal 25% shareholders produce a company with **no PSCs at all**. Minority and structuring holdings are invisible by design. The bulk products contain **no shareholder register**; share capital lives in confirmation-statement filings, not in any bulk file. Bringo's claim to map *shareholders* implies filing-level parsing that this dataset does not give you.
- **Non-compliance.** Global Witness's original analysis found tens of thousands of registration problems, and the register remains self-declared. Absence of a PSC edge is weak evidence of absence.
- **Super-secure PSCs.** Protected by court order; all particulars withheld. Legitimately unresolvable, and must be rendered as such rather than as a gap.

---

### 3.4 Product C — REST API and Streaming API

**REST API** (`api.company-information.service.gov.uk`). Free API key, HTTP Basic with the key as username. **Rate limit: 600 requests per 5 minutes per key** (= 2/sec sustained); exceeding it returns `429` for the remainder of the window. Increases are granted on request — one developer reports being doubled to 1,200/5min.

Do the arithmetic before planning around it: enriching 5.5M companies at 600/5min takes **~32 days of continuous polling**. The REST API is for on-demand lookups and freshness checks on individual records, and for nothing else. Bulk work must come from the bulk files.

**Streaming API** (`stream.companieshouse.gov.uk`). Seven long-lived HTTP streams: `companies`, `filings`, `officers`, `persons-with-significant-control`, `charges`, `insolvency-cases`, `disqualified-officers`. Separate streaming key. Events carry `resource_kind`, `resource_uri`, `resource_id`, a `data` block **identical in shape to the REST PSC resource**, and an `event` block with `timepoint`, `published_at` and `type`.

Two operational realities to price in: **CH disconnects all streams nightly (typically 02:00–03:00)**, so reconnection-with-timepoint-resume is mandatory; and the streams "go down (offline or errors) quite frequently". A third-party status page exists at `companies.stream`. The stream is also the *only* source of PSC deltas — and note it "carries no new/updated/closed" lifecycle signal, so cessation tracking requires your own state machine.

### 3.5 Product D — Accounts bulk data

Prod223 (daily, last 60 days) and Prod224 (monthly, last 12 months; historic monthly back to 2008). ZIPs of **iXBRL** `.html` and XBRL `.xml` files named `Prod{PRODUCT}_{RUN}_{COMPANYNUMBER}_{YYYYMMDD}.html`. Only **electronically filed** accounts are included — sampled electronic-filing rates rise from 0% (2005) to ~74% (2022), so historical coverage is materially incomplete. Out of scope for an ownership graph; relevant only if you later want financials.

### 3.6 Licence and re-use terms

Companies House's position, verified in substance across sources:

- Public-register information is made available under approvals issued under **s.47 Copyright, Designs and Patents Act 1988** and **Schedule 1 of the Database Regulations**, so the Registrar's **database right is not infringed** by extraction or re-utilisation.
- **"Companies House imposes no rules or requirements on how the information on the public register is used."**
- The Basic Company Data product as listed on data.gov.uk carries an open licence (variously described as OGL v3.0 / CC-BY).
- And the sting: *"Companies House is not responsible for your use of the company data. You are responsible for complying with any applicable data protection, copyright and other legislation… before you publish any information."*

**Read that as what it is: an intellectual-property permission, not a data-protection permission.** CH has explicitly and deliberately pushed the entire UK GDPR burden onto the re-publisher. See §10.

---

## 4. Competitive landscape

Verified fresh, July 2026. The prior assessment's premise that graph visualisation is "genuinely underdone" does not hold up.

### 4.1 Direct competitors — this is occupied

| Product | Status | Free? | What it does | Threat |
|---|---|---|---|---|
| **Bringo** (`bringo.co.uk`) | **Live, actively marketed** | **Free tier**, paid upgrade | Landing page is literally *"Corporate Relationship Map: See Who Really Owns Any UK Company"*. Interactive map of shareholders, directors, PSCs and related companies across a claimed 13.5M+ UK companies, **refreshed hourly**. Two UK registered entities behind it. | **Severe — this is the proposed product, already shipped, free** |
| **Endole** | Live, established (inc. 2014, Birmingham) | Freemium | Free database of every UK company and director; paid reports include **group structure** (parent/sibling/child), shareholders, share types, CCJs, financials. Claims 7M+ companies, 55,000+ customers. | High |
| **DataLedger** (`dataledger.uk`) | Live, new entrant | Freemium | Structured accounts + **PSC beneficial ownership**; "traverse parent and subsidiary chains via API". 25 free credits; plans from **£10/mo**; custom datasets from £295, financials+ownership from £395. Also gives away free monthly new/dissolved delta CSVs with no signup. | High — and it commoditises the API layer |
| **OpenCorporates** | Live, serious incumbent | Free web search; paid API/bulk | 204M companies, 170 jurisdictions; ~44 staff (Apr 2026); free tier plus three self-serve API tiers and Enterprise. Deep integration into investigative workflows (Maltego transform hub). | High |
| **OpenSanctions** (`gb_coh_psc`) | Live, updated daily | Data free to download; **commercial licence required for business use** | CH base data + PSC converted to FollowTheMoney, with real entity resolution, published daily in tabular and JSON form. Part of a KYB reference-data catalogue. | High — an entity-resolved version of exactly your dataset, free to non-commercial users |
| **Company Check** | Legacy brand, still referenced | Freemium | Basic company/director lookup. | Medium (lookup only, no graph) |

### 4.2 Adjacent and upstream

- **Companies House "Find and update company information"** — free, authoritative, shows PSC lists per company. **No graph or network view**, and I found no roadmap commitment to build one. This remains the genuine UX gap, but it is the gap Bringo already fills.
- **OCCRP Aleph** — live, free to vetted journalists/researchers/civil society by application. Hosts CH PSC data; FollowTheMoney is OCCRP's model. For the investigative-journalist segment specifically, **Aleph is the incumbent and it is free**.
- **Open Ownership** — **the Register closed 29 November 2024** after seven years. Data still downloadable via `bods-data.openownership.org`; the organisation pivoted "upstream" to standards and partnerships from 2025. The BODS v0.4 standard is live and well-supported.
- **Property adjacency** — HM Land Registry **CCOD** (UK companies owning property in England & Wales) and **OCOD** (overseas companies), free since 2017, monthly, **OGL v3.0**. Already exploited by HouseMetric, `landregistry.company`, and `homedata.co.uk` (corporate ownership by UPRN).
- **Enterprise tier** — Sayari, Moody's/Orbis/kompany, Dun & Bradstreet, Creditsafe, LexisNexis. Not competing for a solo developer's users, but they define what "good" means to any B2B buyer you approach.
- **Hobby/academic attempts** — `harricross/ch-graphs`, `lindacmsheard/graphdata_companies_house`, `psychemedia/companiesHouse_beneficialOwnership`, `eusporg/alphaicon`. All small, most dormant since ~2022. Evidence that people repeatedly *try* this and it repeatedly does not become a product.

### 4.3 So where is the actual gap?

Narrow, and mostly not where the prior assessment placed it:

1. **A free, public, permanent-URL, SEO-indexed ownership page per company.** Bringo gates behind an account; Endole gates behind payment; Aleph gates behind vetting; OpenCorporates' UK graph depth is limited. Nobody offers a genuinely open, linkable, citable page.
2. **Honest confidence signalling.** Every incumbent renders edges as facts. Nobody says "this link is inferred from the free-text string `Companies House` + registration number `1234567`, confidence 0.6". For a journalist who must stand up a claim, that provenance is worth more than the picture. **This is the most defensible idea in the document.**
3. **Registration-density / company-factory analytics.** Registrations-per-address is in the monthly CSV and involves **no personal data at all**. Under-productised relative to how often it makes news.
4. **PSC verification-status tracking through the Nov 2026 deadline.** A time-boxed, genuinely novel dataset — but it expires when the deadline passes.

Note that gaps 2, 3 and 4 are *analytical* products. Gap 1 is the graph — and gap 1 is the one that is both occupied and legally loaded.

---

## 5. Product definition

### 5.1 Target user

If built, the only coherent primary user is the **investigative journalist or researcher who needs a citable, provenance-carrying ownership trace** — someone who will accept "confidence 0.6, here is the raw string" as a *feature*. Curious citizens are better served by CH's own free service; compliance analysts cannot use an unvetted tool for regulated decisions.

### 5.2 The single "killer" feature

**Provenance-first chain tracing.** Every edge in the rendered graph is clickable and expands to show: the exact source record, the raw `identification.registration_number` and `place_registered` strings, the normalisation applied, the matching rule that fired, a confidence score, and the CH filing URL. Ambiguous links render as **dashed amber edges labelled "possible match"**, never as solid lines. Unresolvable corporate PSCs render as terminal nodes labelled with the raw free text, not silently dropped.

This is the one thing no incumbent does, and it is the direct product expression of §3.3 — turning the dataset's central weakness into the differentiator.

### 5.3 MVP scope

**In scope**
- Daily ingest of the PSC snapshot and monthly ingest of Basic Company Data.
- Company page: profile, PSC list with all 86 nature-of-control codes rendered in CH's own wording, active/ceased state.
- Corporate-PSC resolver with normalisation (zero-padding that respects `SC`/`NI`/`OC`/`SO`/`NC`/`FC`/`OE` prefixes), jurisdiction inference from `place_registered`, name matching, and an explicit confidence score.
- Bounded graph view: **maximum 4 hops**, corporate edges solid-when-confident / dashed-when-inferred.
- Provenance panel per edge (§5.2).
- Company-density map by postcode + registrations-per-address leaderboard.
- Static, cacheable, indexable URL per company.
- A published, working takedown/objection route and a named contact.

**Explicitly out of scope**
- **Cross-company person identity.** Do **not** merge individuals across companies. No "other companies this person controls" feature. This is the single most tempting feature and the one most likely to generate a false, defamatory assertion. Show the person only on the company they were filed against.
- Any personal-data search index — no searching *by* person name, no person landing pages. (This alone removes most of the SEO upside; that trade is deliberate.)
- Residential addresses, full dates of birth, super-secure particulars.
- Shareholder/share-capital data (not in bulk; requires filing parsing).
- Accounts, financials, credit scores, officers/directors.
- Non-UK jurisdictions.
- Alerts, monitoring, watchlists, screening — these imply reliability guarantees you cannot make.
- Any bulk export of personal data.

### 5.4 The defensible fallback — build this instead

If the honest assessment of §3.3 and §10 lands, there is a genuinely buildable version: **strip individuals entirely.**

Render only company→company edges (corporate PSC / RLE), plus the density map and company-factory analytics. Individual PSCs appear as a **count only** — "3 individual PSCs (not shown)" — with a link to the CH page. This version:

- carries **almost no personal data**, collapsing §10 from a project-defining risk to a manageable one (residual: registered offices at residential addresses);
- still delivers the interesting structural product (layered corporate chains, offshore RLE termini, mass-registration addresses);
- when an edge is wrong, defames nobody;
- is **10–15 dev-days**, not 45–70.

It is a smaller product. It is also the only version I would actually build.

---

## 6. Technical plan

### 6.1 Graph storage — do not use a graph database

The instinct is Neo4j. Resist it. The read pattern is: *"give me the ≤4-hop neighbourhood of one company"*, long-tail across ~5.5M companies, from a dataset that is fully rebuilt daily. That is not a graph-traversal workload; it is a **precomputed-document workload**.

| Option | Verdict |
|---|---|
| Managed graph DB (Neo4j AuraDB, Memgraph) | **No.** AuraDB Professional starts ~$65/mo but scales with RAM — a 10GB graph is quoted ~$650/mo, and 64GB reaches ~$4,200/mo. Memgraph Enterprise starts ~$25,000/yr for 16GB. Wildly disproportionate. |
| Self-hosted Neo4j Community | Possible but you now operate a JVM graph DB for a query you can answer with a lateral join. |
| **Postgres, edges table + bounded recursive CTE** | **Yes, for the write side and ad-hoc depth.** ~15M edge rows is small. Recursive CTEs are reported reasonable at 3–4 hops on a few-million-edge dataset and degrade badly at 10+ — which is fine, because we cap at 4 by design and real ownership chains are overwhelmingly 1–2 hops. |
| **Precomputed neighbourhood JSON in object storage + CDN** | **Yes, for the read side.** ~4M companies with edges × ~2KB ≈ **8–10GB** of blobs. Regenerate nightly. Serving cost then approaches zero and scales infinitely without a database in the request path. |

**Recommendation: Postgres as system of record, precomputed JSON blobs on a CDN as the serving layer.** No graph database.

### 6.2 Architecture

```
CH bulk endpoints
  ├── PSC snapshot (daily, ~2GB zip, 31 chunks)
  └── BasicCompanyData (monthly, ~450MB zip)
        │
        ▼
  Ingest worker (single VPS, nightly cron)
    • stream chunks, never materialise the 11GB JSON
    • parse JSONL line-by-line, skip trailer + statements + exemptions
    • COPY into staging tables
        │
        ▼
  Postgres 16
    companies · psc_records · psc_natures · edges(confidence, rule, raw_strings)
        │
        ├── Resolver pass → edges table
        ├── Density aggregation → postcode + address rollups
        └── Nightly blob generation → ≤4-hop neighbourhood JSON per company
        │
        ▼
  Object storage (Cloudflare R2 — zero egress) → CDN
        │
        ▼
  Small web app (server-rendered HTML + Cytoscape.js/D3 client-side)
```

**Ingest discipline.** Fetch the **chunked** files, not the single 11GB one; stream-decompress each ~67MB zip and process line-by-line so peak memory stays flat and a failure retries one chunk rather than the lot. Scrape the landing page for links rather than trusting the date template. Snapshot-diff against yesterday's record hashes to detect changes, and — critically — **detect disappearances**, because a record vanishing from the snapshot is how a CH suppression reaches you (§10.4).

**Deliberately not used at MVP:** the Streaming API. It adds nightly-disconnect handling, resume-from-timepoint state, and its own lifecycle state machine, to gain sub-24-hour freshness that a research tool does not need. Add it later if at all.

### 6.3 Running cost — realistic

| Item | Self-hosted (recommended) | Managed cloud |
|---|---|---|
| Compute (ingest + web) | Hetzner CPX41, 8 vCPU/16GB/240GB — **~£28/mo** | Fargate + RDS db.t4g.large — ~£220/mo |
| Object storage (~50GB blobs + rolling snapshots) | Cloudflare R2, **~£1/mo**, zero egress | S3 + CloudFront — ~£25/mo + egress |
| Bandwidth (~2GB/day inbound) | Included | Ingress free, compute-hours not |
| CDN | Cloudflare free tier | ~£15/mo |
| Domain, TLS, error tracking | ~£4/mo | ~£4/mo |
| **Total infrastructure** | **~£35–60/mo** | **~£280–450/mo** |

Two costs people omit. **Backfill/reprocessing:** every resolver change means re-running against 15M records — budget several hours of compute per iteration. **Human time on data-subject requests:** unquantifiable in advance, potentially the largest real cost, and not reducible to money (§10).

If you ignored §6.1 and put this on managed Neo4j at realistic size, add **£500–700/mo**, which alone kills the economics.

---

## 7. Effort & timeline

One competent full-stack developer, focused.

| Workstream | Days |
|---|---|
| Ingest pipeline (chunked streaming, resumability, monitoring) | 6–8 |
| Postgres schema, loaders, snapshot diffing | 4 |
| **Corporate-PSC resolver** (normalisation, jurisdiction inference, name matching, confidence scoring, eval harness) | **12–18** |
| Blob precomputation + serving | 4 |
| Company pages, all 86 nature codes, provenance panel | 6 |
| Graph UI (Cytoscape.js, confidence styling, degradation) | 6–8 |
| Density map + company-factory analytics | 3–4 |
| Legal: privacy notice, DPIA, LIA, takedown workflow, suppression-sync logic | 5–7 |
| Deploy, monitoring, alerting | 3 |
| **MVP total** | **49–62 dev-days (~10–12 weeks)** |
| **§5.4 corporate-only fallback** | **10–15 dev-days** |

The resolver is the largest line and the estimate is optimistic — it has no natural completion point, only diminishing returns, and it needs a hand-labelled evaluation set that does not exist and must be built.

**Ongoing maintenance: high — the highest in the catalogue.**

- A **daily** 2GB pipeline that must not silently fail (a stale snapshot is a compliance problem, not just stale content).
- CH schema drift: the `kind` enumeration has already grown with the ROE and `*-beneficial-owner` variants, and `identity_verification_details` appeared mid-flight. Assume 2–4 breaking changes a year.
- Data-subject requests, arriving forever, requiring a human (§10).
- Resolver regression risk: any change silently rewires the public graph.

Realistically **2–5 hours/week** at steady state, spiking on CH changes and DSARs — an obligation that does not end when interest wanes.

---

## 8. Distribution

**SEO.** The natural play — rank for `{company name} owner`, `who owns {company}`, `{director name} companies` — is exactly the play §5.3 rules out, because person-name pages are the highest-risk personal-data surface and the thing most likely to attract erasure demands. What remains is thin and contested by Endole/Bringo/OpenCorporates, all older and better-linked. Viable non-personal terms: `companies registered at {postcode}`, `company ownership structure {company}`, `mass registration address UK`, `PSC data explained`, `corporate ownership chain UK`.

**Press hooks** (the strongest distribution channel here):
- Registration-density outliers — "the terraced house that is home to 2,400 companies". Reliably picked up; run it as a periodic data release.
- The **18 November 2026 ID-verification deadline** — "X% of PSCs still unverified with N weeks to go". Genuinely novel, time-boxed, and CH-adjacent enough to get quoted.
- Layered structures terminating in secrecy jurisdictions — but only with airtight provenance, and this is well-trodden Global Witness/TI territory.
- Cross-reference with CCOD/OCOD: "companies owning the most residential property".

**Communities to seed:** Global Investigative Journalism Network, Bureau of Investigative Journalism, Bellingcat's toolkit and Discord, `r/ukpolitics` and `r/HousingUK`, Hacker News (a *technical* write-up of the entity-resolution problem will substantially outperform the product launch), the UK civic-tech/mySociety orbit, and the Companies House developer forum. OCCRP/Aleph's audience is the target audience — but note you would be pitching a free tool to people who already have a free tool.

---

## 9. Sustainability

This is the one idea in the set with genuine B2B willingness to pay. It is also the one where that willingness is hardest for a solo developer to capture.

| Model | Realistic? |
|---|---|
| **Consumer subscription** | **No.** Near-zero willingness to pay; CH is free; Bringo has a free tier. |
| **Journalist/NGO subscription** | **No.** Real need, no budget, strong free-tool norms, and Aleph is free. |
| **B2B KYB/AML seats** | **Real money, effectively unreachable.** Regulated buyers demand vendor due diligence, SLAs, audit trails, sanctions/PEP coverage, data lineage and indemnities. §3.3 means you cannot warrant accuracy — and warranting accuracy is the product. This is a 12–18 month enterprise sales motion against Moody's, Sayari, Creditsafe and LexisNexis. Not a side project. |
| **Developer API** | **Possible, commodity.** DataLedger already sells this from £10/mo, OpenSanctions gives the entity-resolved data away to non-commercial users, and CH's own API is free. Price ceiling ~£10–30/mo, tiny volume. |
| **Ads on company pages** | **Technically viable, strategically worst.** It is the occupied Endole/Company Check model *and* it means monetising pages built on personal data — which materially weakens any legitimate-interests balancing test (§10.2). |
| **Grant funding** | Plausible in principle. But Open Ownership — grant-funded, staffed, lawyered — closed its Register in Nov 2024. Funders have visibly moved upstream. |

**Honest conclusion: expect no revenue.** Budget this as a ~£35–60/month personal cost with an open-ended maintenance and legal obligation attached. If revenue is a requirement, this is not the idea.

---

## 10. Legal & privacy considerations

**This section is the reason for the verdict.** Treat it as the primary finding, not an appendix.

### 10.1 What you would be republishing

For every individual PSC: full name and name elements, **month and year of birth**, nationality, country of residence, a **correspondence (service) address**, the nature and extent of their control, and dates. At ~15M records this is unambiguously **large-scale processing of personal data**, and combining name + partial DOB + address + control makes many records **directly identifying**.

### 10.2 You do not get Companies House's exemption

The single most important asymmetry in this document.

Companies House can refuse erasure and rectification requests because it relies on the **Data Protection Act 2018, Schedule 2, Part 1, paragraph 5** exemption — it is *required by the Companies Act 2006* to make this information public.

**You are not required by the Companies Act to do anything.** You are a voluntary re-publisher with no statutory duty, so:

- Your lawful basis would be **legitimate interests (Art. 6(1)(f))**, requiring a documented **Legitimate Interests Assessment**. It is arguable — transparency and journalism are recognised interests — but the balance shifts against you the moment you monetise, and shifts further when your inferred edges are wrong (§3.3.3).
- **Art. 17 erasure** and **Art. 21 objection** requests apply to you, and you must genuinely assess each one. You will receive them.
- **Art. 14 transparency** (data obtained indirectly) formally requires notifying 15M people. Art. 14(5)(b) disproportionate-effort relief is the realistic route, requiring a prominent public privacy notice — you must actually build and publish this.
- **Art. 5(1)(d) accuracy** bites hard given §3.3. An inferred ownership edge is *your* inference about a person, and you are obliged to keep it accurate.
- A **DPIA is mandatory** — large-scale processing, systematic evaluation, and data-matching all trigger it.
- If you profile people (linking an individual across companies), you have created **new** personal data by inference. This is precisely why §5.3 puts cross-company person identity out of scope.

### 10.3 CH's re-use terms give you IP cover only

CH's s.47 CDPA approvals and the Database Regulations mean the Registrar's database right is not infringed, and CH "imposes no rules or requirements" on use. But CH states explicitly that it "is not responsible for your use of the company data" and that *you* must comply with data-protection law before publishing. **The licence solves copyright and database right. It does nothing for UK GDPR.** Do not let "it's open data, OGL" substitute for an LIA and a DPIA — this is the most common and most consequential error in this space.

### 10.4 ECCTA 2023 — a moving target that cuts against you

- **Identity verification** mandatory from **18 November 2025** for new appointments/registrations; all existing directors and PSCs must verify by **18 November 2026**. Records carry a verification indicator; the **personal code is confidential and not published**.
- **Suppression/protection expanded** — from **27 January 2025** individuals could apply to protect a usual residential address historically used as a registered office; the **Protection and Disclosure of Personal Information (Amendment) Regulations 2025**, in force **21 July 2025**, extended this so that in most cases *any* individual can apply to suppress their URA from historical documents. Protected categories now also cover IDV documents and company email addresses.
- **Unverified records may eventually be hidden** from search.

The operational consequence is sharp. **When CH suppresses an at-risk person's details — someone fleeing domestic abuse, a witness, an activist — that person's data disappears from the CH snapshot but persists in your database, your CDN blobs, your search index and any archive of your pages.** Republishing it after suppression is exactly the harm the protection regime exists to prevent, and it is a safety issue before it is a compliance issue.

**Mandatory mitigations if built:**
1. **Never retain a PSC record absent from the current snapshot.** Diff daily, and treat disappearance as a hard delete across Postgres, blobs and CDN cache — with cache purge, not just invalidation.
2. Set `noarchive`/`noindex` appropriately on any page containing individual data, and do not fight archiving services on removal.
3. Publish a working takedown route with a named contact and a committed response time, and honour it fast.
4. Never expose residential addresses, full DOB, or super-secure particulars — and never infer them.
5. Register with the ICO as a data controller (a modest annual fee) and maintain the DPIA and LIA as live documents.

### 10.5 Defamation

Underweighted everywhere in this space. Automatically publishing "Person X ultimately controls Company Y" is a **factual assertion about a named individual**. Given §3.3.2 — dedup on name + month/year of birth alone — false merges are certain at 15M records. A wrongly-asserted connection between a real person and, say, a company under investigation is a defamation claim that "the algorithm did it" does not answer. §5.3's ban on cross-company person identity is not conservatism; it is the mitigation.

### 10.6 Direction of travel

The CJEU's *WM & Sovim* ruling (Nov 2022) struck down general public access to EU beneficial-ownership registers on privacy grounds. The UK is not bound, and the UK register remains public. But the international trend, ECCTA's widening suppression regime, and Open Ownership's own retreat all point the same way: **the assumption that this data will remain freely republishable at scale for the next decade is an assumption, not a fact.**

---

## 11. Risks & kill criteria

### Risks, ranked

| # | Risk | Likelihood | Impact | Notes |
|---|---|---|---|---|
| 1 | **Entity resolution is not good enough**, so chains break or are wrong | **High** | **Fatal** | §3.3. Verified structural, not incidental. |
| 2 | **Legal/privacy burden exceeds a solo developer's capacity** | **High** | **Fatal** | §10. No CH exemption; perpetual DSAR duty. |
| 3 | **Incumbents already own the wedge** | **High** | High | Bringo is the product, free, hourly. |
| 4 | Wrong edge names a real person → defamation / accuracy breach | Medium | **Fatal** | §10.5 |
| 5 | Stale snapshot re-exposes suppressed at-risk individual | Medium | **Fatal (safety)** | §10.4 |
| 6 | CH restricts or charges for bulk data | Low–Medium | Fatal | ECCTA expanded CH's fee-setting powers; no current signal, but the register is being actively reshaped. |
| 7 | Daily 2GB pipeline rots | Medium | High | Fails silently; stale = compliance problem. |
| 8 | No revenue, perpetual cost + obligation | **High** | Medium | §9. Assume this happens. |
| 9 | Data quality (non-compliance, 25% threshold) makes graph misleading | High | Medium | Mitigable by honest UI. |
| 10 | Infrastructure cost overrun | Low | Medium | Only if §6.1 is ignored. |

### Kill criteria

**Do not start if** you are unwilling to (a) act as a data controller indefinitely, (b) personally handle erasure and objection requests, or (c) run a daily pipeline whose silent failure creates legal exposure. Any one of these is disqualifying.

**Kill during build if:**
- On a hand-labelled sample of 500 corporate PSCs, the resolver cannot exceed **~90% precision at ≥70% recall**. Below that the graph is misinformation with a nice layout. *Measure this in week one, before writing any UI.*
- The resolver eval set reveals that a large share of corporate PSCs carry no usable `registration_number` at all — chains terminate immediately and there is no product. *(Genuinely unknown — see §12.)*
- A trial of Bringo shows it already does this well and free.
- Draft DPIA/LIA cannot produce a defensible legitimate-interests balance.

**Kill after launch if:**
- Data-subject requests exceed ~2 per week (unsustainable for one person).
- Any confirmed instance of republishing a CH-suppressed individual.
- A defamation or accuracy complaint with merit.
- <500 monthly actives after six months with press coverage spent.
- CH changes the bulk products' availability or licence.

---

## 12. Open questions

Must be answered before committing. The first is decisive.

1. **What proportion of corporate PSC records carry a `registration_number` that resolves to a valid CH company number?** *Completely unknown, and it determines whether the product exists.* If it is 85%, chains mostly work; if 40%, they terminate immediately and there is nothing to build. **Answerable in under a day**: download one PSC chunk (~67MB), extract all `corporate-entity-*` records, normalise the numbers, and join against `BasicCompanyDataAsOneFile`. I could not run this — egress policy blocked all access to `download.companieshouse.gov.uk` (403 at CONNECT). **Do this before anything else.**

2. **Current live volumes.** The 2022-02-09 page (verified from an archived fixture) listed 20 chunks. A 2026-02-13 snapshot reportedly listed 31 chunks at 67–68MB — implying ~15M records and ~11GB unzipped — but this is second-hand. Confirm with a HEAD request against the live page.

3. **How is `place_registered` actually distributed?** The Global Witness heuristic tests six hardcoded strings. What does the real free-text distribution look like — how many spelling variants of "Companies House", "England and Wales", "United Kingdom"? Determines whether jurisdiction inference is a lookup table or an NLP problem.

4. **Does any PSC record subtype carry the typed `identification_type` discriminator?** CH's `constants.yml` defines it (`uk-limited-company`, `eea`, `non-eea`, …) but the `corporateEntityIdent` OpenAPI model does not include it. If ROE `corporate-entity-beneficial-owner` records *do* carry it, that subset is reliably linkable and worth treating separately.

5. **How deep are real ownership chains?** If the median is 1 hop and the 95th percentile is 2, the "walk the chain" feature is largely solving a problem that does not occur, and the graph is decoration.

6. **What exactly does Bringo's relationship map do on its free tier, and how good is it?** I could not load the page (WebFetch blocked). If it is good and free, the wedge is closed. **Spend 30 minutes on this before anything else except question 1.**

7. **Does the `etag` field change reliably on every record modification?** If so it is a cheap change-detection key and avoids full-record hashing on 15M rows nightly.

8. **Does CH publish, or has it committed to publish, any signal that a record was suppressed** (rather than merely vanishing from the snapshot)? Silent disappearance is workable but fragile; an explicit signal would materially de-risk §10.4.

9. **Precise current CH re-use wording.** I verified the substance (s.47 CDPA approvals, Database Regs Schedule 1, "no rules or requirements", responsibility disclaimed) from secondary sources. Read `resources.companieshouse.gov.uk/serviceInformation.shtml` verbatim before relying on it.

10. **Is there ICO precedent on third-party republication of PSC data?** I found none. Its absence is itself a risk signal — it means the boundaries are untested and you might be the test case.

---

## Appendix — primary artefacts examined

| Artefact | What it established |
|---|---|
| `companieshouse/specs.developer.ch.gov.uk` → `pscModels.json` | Official PSC schema; `corporateEntityIdent` requires only `legal_authority` + `legal_form`; `registration_number` optional free-text string; `legalPersonIdent` has no registration number at all |
| `companieshouse/api-enumerations` → `psc_descriptions.yml` | 86 natures of control, 86 short descriptions, 28 statement descriptions, 2 super-secure descriptions |
| `companieshouse/api-enumerations` → `constants.yml` | 12 company statuses, 37 company types, `identification_type` enumeration |
| `Global-Witness/the-companies-we-keep-public` | `create_target_company_uid` heuristic; documented leading-zero corruption; "Companies House does not supply a unique identifier for PSCs" |
| `StephenAbbott/bods-mapper` (Jun 2026) | Corporate PSC identifier emitted as scheme `"unknown"`; local ids namespaced by company number |
| `opensanctions/opensanctions` → `datasets/gb/coh/psc_parse.py` | Nine `kind` values incl. ROE beneficial-owner variants; `identity_verification_details` present; registration numbers left unresolved |
| `mrbrianevans/ch-guide` | Bulk URL templates, CSV header, JSONL sample, trailer record, chunking scheme, streams list, accounts products, rate limit |
| `openownership/register-ingester-psc` → `en_pscdata.html` fixture | Real download page, 2022-02-09: 20 chunk files |
| CH official statistics FYE2026 | 5,479,045 companies at 31 March 2026; 815,280 incorporations; 787,261 dissolutions |
