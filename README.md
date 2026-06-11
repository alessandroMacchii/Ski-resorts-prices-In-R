# Ski Resorts Price Analysis (in R)

An exploratory statistical study of **what drives the price of a ski lift pass
worldwide**, carried out in R inside `ski_analysis.ipynb`.

> **Companion docs:**
> [`statistical_methods.md`](statistical_methods.md) — the theory behind each
> choice and what every test actually does;
> [`ski_analysis_explained.md`](ski_analysis_explained.md) — a cell-by-cell
> walkthrough of the notebook.

---

## What this project does

It takes a dataset of ~499 ski resorts, cleans and enriches it, and then runs a
series of **bivariate hypothesis tests** to see which factors are associated
with a higher lift-pass price. The investigation is framed as four "suspects":

| # | Suspect | Question |
|---|---------|----------|
| 1 | **The mountain itself** | Do bigger/higher resorts charge more? |
| 2 | **Geography & wealth** | Do location and country economics drive price? |
| 3 | **Services & positioning** | Do extras (snowpark, night skiing…) justify a premium? |
| 4 | **The actual snow** | Does more reliable snow cover support higher prices? |

Each suspect is tested separately, and the results are consolidated into a
ranked summary table at the end.

---

## Type of analysis

This is primarily a **descriptive + inferential statistics** project. The core
of it uses course-level **bivariate** methods (one predictor vs. price at a
time), and it then closes with a **multiple regression** that brings every
factor into a single model. The methods used are:

- **Descriptive statistics** — `summary()`, group means/medians/SD, histograms,
  frequency tables.
- **Correlation tests** (`cor.test`) — for continuous predictors: altitude,
  total slopes, lifts, vertical drop, GDP per capita, PPP, snow cover.
- **ANOVA** (`aov` + `TukeyHSD`) — for categorical predictors with several
  levels: altitude band, continent, season.
- **Welch t-tests** (`t.test`) — for yes/no service flags: snowpark, night
  skiing, summer skiing, child-friendly.
- **Chi-square tests** (`chisq.test`) + **Cramér's V** (`cramerV`) — for
  associations between two categorical variables (e.g. continent vs. price
  tier, summer skiing vs. continent).
- **Multiple linear regression** (`lm`) — final step: a main model with the
  well-populated suspects (mountain, geography/wealth incl. GDP & PPP, services)
  plus a secondary model adding snow cover on the ~125 snow-matched resorts. Each
  estimates a factor's effect on price *holding the others constant*. Only the raw
  `summary()` coefficient table is reported, to stay within the course toolkit.
- **Visualization** (`ggplot2`) — each test is paired with an inline chart
  (histogram, scatter, boxplot) so the notebook reads as a written report.

Each bivariate test is stated with explicit H0/H1 hypotheses and read off
statistical significance **and** effect strength; the regression then quantifies
how much each variable moves price once the others are controlled for.

---

## Data

| File | Role |
|------|------|
| `data/resorts.csv` | Main dataset — 499 resorts × 25 variables (Kaggle *Ski Resorts*), read as Latin-1. |
| `data/snow.csv` | Monthly snow-cover values on a Lat/Lon grid, aggregated and joined to resorts. |
| `data/gdp_per_capita_raw.csv` → `_clean.csv` | World Bank GDP per capita (2022) — proxy for national wealth. |
| `data/ppp_raw.csv` → `_clean.csv` | World Bank PPP (2022) — proxy for local price level. |

The `_raw` → `_clean` convention keeps the original World Bank files next to the
tidied versions for reproducibility/auditing.

### Data preparation highlights
- **Missing values** — explicit `NA`s counted; "impossible" zeros (e.g.
  `Price == 0`, `Total lifts == 0`) recoded to `NA`, plausible zeros kept.
- **Season** — many messy month-range strings collapsed into 4 macro-categories
  (`Winter_Only`, `Summer_Only`, `Multi_Season`, `Year_Round`).
- **Derived variables** — `Vertical_Drop` (highest − lowest) and `Altitude_Band`
  (binned altitude).
- **External merges** — GDP/PPP joined by country (with a name-alignment map);
  snow joined by rounded coordinates.

---

## Workflow

```
Import → Clean (NAs, Season, derived vars) → Merge external (GDP, PPP, snow)
      → Test each suspect bivariately (Suspects 1–4)
      → Consolidate + rank all results (Synthesis)
      → Multiple regression: all factors together, effects held constant
      → Conclude
```

---

## Headline findings

- **Strongest drivers:** continent (North America much pricier), maximum
  altitude, and resort size (total slopes).
- **Weak/negligible:** number of lifts, vertical drop, seasonality, night
  skiing, child-friendly.
- **Surprises:** services aren't a uniform premium; "summer skiing" looks like a
  premium but is really *geography in disguise* (very strong continent link).
- **Untangling confounders:** because bivariate tests can't tell whether
  continent matters on its own or only because those resorts are also
  bigger/higher, the closing multiple regression estimates each effect with the
  others held constant — confirming continent and altitude as the dominant
  drivers and shrinking some apparent effects (e.g. summer skiing) once
  geography is accounted for.

---

## Tools

R, run via Jupyter (`ski_analysis.ipynb`). Packages: **`rio`** (import/export),
**`dplyr`** (data wrangling), **`rcompanion`** (Cramér's V), **`ggplot2`**
(plots).

## Data sources
- Kaggle — *Ski Resorts* dataset
- World Bank — GDP per capita (2022)
- World Bank — PPP conversion factor (2022)
