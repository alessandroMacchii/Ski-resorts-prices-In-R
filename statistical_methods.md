# Theory & Methods: Why These Choices, and What Each Test Actually Does

A companion to `ski_analysis.ipynb`. The notebook itself shows *what* was run and
*what came out*; this file explains the *why* — the reasoning behind the design,
and the statistical idea behind every test, in plain language.

---

## 1. The overall design

### 1.1 The research question

> **What drives the price of a ski-lift pass?**

Price is the **outcome** (the "dependent" variable, the thing we want to explain).
Everything else — altitude, country, services, snow — is a candidate **explanatory
variable** (a possible cause / predictor).

### 1.2 Why the "four suspects" framing

The dataset has ~25 variables. Throwing them all at the problem at once is hard to
reason about, so they are grouped into four hypotheses ("suspects"), each a
coherent story about why price might be high:

1. **The mountain itself** — bigger/higher resorts cost more (altitude, slopes, lifts).
2. **Geography & wealth** — richer / more expensive countries charge more (continent, GDP, PPP).
3. **Services & positioning** — extras justify a premium (snowpark, night skiing, …).
4. **The actual snow** — more reliable snow supports higher prices.

This is a standard way to structure exploratory work: turn a vague question into a
small set of **testable hypotheses**, then test each one.

### 1.3 Why bivariate tests first, then one regression

The bulk of the notebook tests **one predictor against price at a time**
("bivariate" = two variables). This is the natural first pass: it is simple,
transparent, and each test answers a clean yes/no question.

Its weakness is **confounding** (see §4.4): a bivariate test cannot tell whether
continent matters *on its own* or only because North-American resorts also happen
to be bigger and higher. So the analysis ends with **one multiple regression**,
which looks at all suspects *together* and isolates each effect. Bivariate for
clarity, regression for the final verdict.

---

## 2. The data-preparation choices

Statistics are only as trustworthy as the data fed in. Each cleaning decision is a
judgement call with a reason:

- **Reading the file as Latin-1.** Resort names contain accented characters (é, ü,
  ñ). Latin-1 encoding decodes those correctly; the default UTF-8 would garble them.

- **Turning "impossible" zeros into `NA`.** A `Price` of 0 or `Total lifts` of 0 is
  not a real free resort with no lifts — it is a **missing value recorded as zero**.
  Left as 0, it would drag down averages and distort every test. Zeros that *are*
  plausible (0 snow cannons, 0 gondolas) are kept. The distinction is domain
  knowledge, not a rule a computer can infer.

- **Recoding `Season`.** The raw field had dozens of messy month-range strings plus
  "Unknown". Collapsing them into 4 macro-categories (`Winter_Only`, `Summer_Only`,
  `Multi_Season`, `Year_Round`) makes the variable usable in a test — you cannot run
  an ANOVA across 40 one-off labels, but you can across 4 meaningful groups. This is
  a trade-off: simpler and testable, at the cost of detail.

- **Derived variables.** `Vertical_Drop = Highest − Lowest` and `Altitude_Band`
  (binned altitude) are *constructed* because they capture an idea ("how much
  mountain is there") more directly than the raw columns.

- **External data (GDP, PPP).** To test Suspect 2 we need country-level economics
  the resorts file doesn't contain, so World Bank indicators are merged in:
  **GDP per capita** = national wealth; **PPP** = local price level / cost of living.
  They are joined by country name (with a small rename map to reconcile spellings
  like "Czechia" → "Czech Republic").

- **Snow joined by coordinates.** The snow data is on a latitude/longitude grid, not
  by resort. Rounding both to a common 0.25° grid and aggregating lets us attach a
  snow value to each resort. It only matched ~25% of resorts — which is *why* snow is
  handled separately in the regression (see §5.3).

---

## 3. The building blocks: hypotheses, p-values, effect size

Every test in the notebook shares the same logic.

### 3.1 Null vs alternative hypothesis

- **Null hypothesis (H0):** "there is no effect / no relationship." E.g. *price is
  unrelated to altitude*; *all continents have the same mean price*.
- **Alternative (H1):** "there is an effect." E.g. *price does change with altitude*.

A test asks: **if H0 were true, how surprising is the data we actually saw?**

### 3.2 The p-value

The **p-value** is the probability of seeing a pattern at least this strong *if H0
were true* (i.e. by pure chance). 

- Small p (conventionally **< 0.05**) → the data would be unlikely under "no
  effect", so we **reject H0** and call the result *statistically significant*.
- Large p → not enough evidence to reject H0; the pattern could be noise.

p < 0.05 is a convention, not a law of nature. `***`, `**`, `*` in R output mark
p < 0.001, 0.01, 0.05.

### 3.3 Significance ≠ importance (effect size)

A p-value tells you whether an effect is **real**, not whether it is **big**. With
enough data, a tiny, useless effect can be "significant". So every test is read
twice:

- **Is it real?** → the p-value.
- **Is it big?** → the **effect size** (the correlation `r`, the gap between group
  means, Cramér's V, the regression coefficient).

This is why the notebook reports both and ranks suspects by effect *strength*, not
just by significance.

---

## 4. The tests, one by one

Which test you use is dictated by the **types of the two variables** (continuous
number vs. category). That mapping is the single most important idea here:

| Predictor → Outcome | Test used | Used in the notebook for |
|---|---|---|
| number → number | **Correlation** (`cor.test`) | price vs altitude, slopes, lifts, GDP, PPP, snow |
| category (2 groups) → number | **t-test** (`t.test`) | price with vs without a service |
| category (3+ groups) → number | **ANOVA** (`aov` + Tukey) | price by continent / altitude band / season |
| category → category | **Chi-square** (`chisq.test`) + Cramér's V | continent vs price tier; summer-skiing vs continent |
| many predictors → number | **Linear regression** (`lm`) | the final all-suspects model |

### 4.1 Correlation — `cor.test`

**What it is.** Pearson's correlation coefficient **`r`** measures how tightly two
*numeric* variables move together in a straight line.

- `r` ranges from **−1 to +1**. `+1` = perfect upward line, `−1` = perfect downward,
  `0` = no linear relationship.
- Rough reading: |r| ≈ 0.1 weak, ≈ 0.3 moderate, ≈ 0.5+ strong.
- The test's p-value asks whether `r` is significantly different from 0.

**Why `use = "pairwise.complete.obs"`.** It tells R to ignore rows where either
value is missing, rather than failing. Without it, a single `NA` breaks the
calculation.

**Example in the notebook.** Price vs maximum altitude gave r ≈ 0.41 (moderate,
highly significant): higher resorts do charge more. Price vs PPP gave r ≈ −0.04
(essentially zero): no linear link.

**Caution.** `r` only captures *straight-line* relationships, and correlation is
not causation (§4.4).

### 4.2 t-test — `t.test`

**What it is.** Compares the **mean** of a numeric variable between **two groups**
and asks whether the difference is real or chance.

- H0: the two group means are equal. H1: they differ.
- Used here in the **Welch** form (the default), which does **not** assume the two
  groups have equal variance — the safe, more robust choice.

**Example.** Price for resorts *with* a snowpark vs *without*. Snowpark resorts
averaged ~€9 more, and the t-test said that gap is significant — a real premium.
Night skiing, by contrast, showed no significant price difference.

### 4.3 ANOVA — `aov` + `TukeyHSD`

**What it is.** ANOVA (Analysis of Variance) is the t-test's big brother: it
compares the **means of a numeric variable across 3 or more groups** at once.

- H0: *all* group means are equal. H1: *at least one* group differs.
- The test statistic is **F** (roughly: between-group differences ÷ within-group
  noise). A large F with a small p means the groups really do differ.

**Why Tukey HSD afterwards.** ANOVA only says "*some* group is different" — not
*which*. **Tukey's Honest Significant Difference** does all the pairwise comparisons
(e.g. North America vs Europe, Europe vs Asia…) while correcting for the fact that
testing many pairs inflates the chance of a false positive.

**Example.** Price by continent: F ≈ 117, p < 0.001 — the biggest effect in the
study. Tukey then showed North America sits ~€36 above Europe specifically.

### 4.4 A word on confounding & causation

Two variables can move together for three reasons: A causes B, B causes A, or a
**third variable C drives both** (confounding). Bivariate tests cannot distinguish
these. "Summer skiing" *looks* like a price premium, but it is concentrated in
specific regions — so the apparent effect is really geography. This is the core
limitation that motivates the regression in §5.

### 4.5 Chi-square test of independence — `chisq.test`

**What it is.** Tests whether **two categorical variables are associated**, by
comparing the counts you actually observe in a cross-table against the counts you'd
expect if the two variables were completely unrelated.

- H0: the variables are **independent** (knowing one tells you nothing about the
  other). H1: they are associated.
- A large χ² statistic with small p → the variables are linked.

**Example.** Continent vs price-tier (cheap/medium/expensive, built with terciles
via `quantile` + `cut`): are expensive resorts unevenly spread across continents?

**Cramér's V — the effect size (`cramerV` from `rcompanion`).** Chi-square tells you
*whether* there's an association but not *how strong*. **Cramér's V** rescales it to
**0–1** (0 = none, 1 = perfect). It is the categorical analogue of `r`.

**Example.** Summer-skiing vs continent gave V ≈ 0.76 — a very strong link,
confirming that summer skiing is essentially a geographic feature, not a free
pricing lever.

---

## 5. Multiple linear regression — `lm`

### 5.1 What it is

A regression models the outcome as a weighted sum of all predictors at once:

```
Price ≈ b0 + b1·(altitude) + b2·(slopes) + … + (continent effects) + …
```

Fitting the model finds the coefficients `b` that best predict price. The crucial
property: **each coefficient is the effect of that predictor while holding all the
others constant.** That is exactly what bivariate tests cannot do — and exactly what
answers "how much does each factor *really* move price."

### 5.2 How to read the output

- **`Estimate` (the coefficient).** For a numeric predictor: the euro change in
  price per one-unit increase, others held fixed. For a category: the gap versus the
  baseline level (e.g. "North America" vs the reference continent).
- **`Pr(>|t|)`.** The p-value for each coefficient — is this effect distinguishable
  from zero, given the others are in the model?
- **Adjusted R².** The share of all price variation the model explains (0–1).
  Higher = the predictors account for more of why prices differ. The notebook's main
  model reaches ≈ 0.70, i.e. it explains about 70% of price variation.

**The headline finding.** Once everything is in one model, **continent** and
**maximum altitude** remain the dominant, significant drivers, **GDP** matters,
**snowpark** adds a small premium, and PPP / night skiing / summer skiing / season
fade — their apparent bivariate effects were largely confounded.

### 5.3 Why snow gets a *second* regression

Snow cover only matched ~25% of resorts. Because regression drops any row missing
*any* predictor, putting snow in the main model would shrink it from ~460 resorts to
~110. So snow is tested in a **separate model on just the snow-matched resorts**,
using the same controls. Result: snow has **no significant independent effect** once
altitude and continent are accounted for — it is largely a stand-in for altitude.
This confirms Suspect 4's hypothesis was, in the end, mostly about altitude.

### 5.4 An honest scope note

Multiple regression is the standard, correct tool for this question, and it is the
only step that genuinely synthesises the four suspects. It is included for that
reason even though the explicit `lm()` syntax sat slightly beyond the course's
core toolkit. To stay close to the program, the notebook reports **only the raw
coefficient table** from `summary()` — it deliberately omits standardized
coefficients (which need `scale()`) and the variance-decomposition table (which
needs `anova()` on an `lm`), as both rely on functions outside the taught set.

---

## 6. Why the plots are the analyses, drawn

Each chart is not new analysis — it is a **picture of a test already run**, because
every test measures a *relationship*, and relationships can be drawn:

| Plot | Visualises |
|---|---|
| Price histogram | the shape (skew) of the outcome variable |
| Price vs altitude scatter | the **correlation** (§4.1) |
| Price-by-continent boxplot | the **ANOVA** group differences (§4.3) |
| Snow vs price scatter | the (near-zero) snow **correlation** |

The p-values in the output are simply numeric summaries of what these pictures show:
a clear pattern = small p; a shapeless cloud = large p.

---

## 7. Limitations (worth stating honestly)

- **Correlation ≠ causation.** This is observational data; the tests reveal
  association, not proof of cause.
- **Geographic skew.** The sample is Europe-heavy; results for tiny groups (Oceania,
  South America) rest on few resorts and are less reliable.
- **Single snapshot.** Prices and external indicators are one year; no trends.
- **Reconstructed data.** Masked zeros, heavy `Season` recoding, and a coarse
  coordinate-based snow join all introduce some approximation.
- **Country-level economics.** GDP and PPP are national averages applied to every
  resort in that country — they cannot capture within-country variation.

---

### One-line summary

The notebook turns a single question ("what sets ski-pass prices?") into four
hypotheses, tests each with the statistical tool matched to its variable types
(correlation, t-test, ANOVA, chi-square), then uses one regression to separate the
real drivers from the confounded ones — concluding that **geography and altitude,
not snow or services, are what actually move the price.**
