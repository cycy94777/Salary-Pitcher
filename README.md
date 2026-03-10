# ⚾ Salary Pitcher — MLB Salary Analysis
### A Mentee Program Project | Mentor: Christine

---

## 📌 Project Overview

**Salary Pitcher**  is a data science project that investigates whether MLB player salaries are accurately tied to performance. Using data scraped from **FanGraphs**, the project applies machine learning to predict and evaluate salary fairness for both **batters** and **pitchers**.

**Core Question:** *Can we predict a player's salary from their performance metrics — and identify who is overpaid or underpaid?*

---

## 📁 Project Structure

```
mlb-salary-analysis/
│
├── data/
│   └── Baseball_player.xlsx        # Source data (Batter & Pitcher sheets)
│
├── MLB.R           # Main R analysis script
│
└── README.md                       # You are here
```

---

## 🔄 Pipeline Overview

```
Data Collection (FanGraphs Webscraping)
        ↓
Data Cleaning & Type Conversion
        ↓
Service-Time + IFA Clustering (4 Groups × 2 Player Types = 8 Total)
        ↓
PCA (Dimensionality Reduction on Performance Metrics)
        ↓
Linear Regression (Log-Salary Prediction per Cluster)
        ↓
Logistic Regression (Classify Overpaid / Underpaid)
        ↓
Neural Network — neuralnet MLP (Salary Prediction)
        ↓
Evaluation: RMSE, MAPE, Residual Analysis
```

---

## 📊 Data Source

- **Platform:** [FanGraphs](https://www.fangraphs.com) — collected via webscraping
- **Format:** Excel workbook (`Baseball_player.xlsx`)
  - Sheet 1: `Batter(2)` — batter-level stats and salary
  - Sheet 2: `Pitcher(2)` — pitcher-level stats and salary

---

## 🧩 Part 1 — Service-Time Segmentation (Clustering Groups)

Before any ML model runs, players are segmented by **contract type** using MLB's service-time rules. This is a critical preprocessing step because salary is *structurally* determined by how long a player has been in the league — not just performance.

| Cluster Group | Service Time | Contract / Market Interpretation |
|---|---|---|
| **Pre-Arbitration (Pre-Arb)** | 0–3 years | Players have almost no negotiation power; salaries are league-minimum or slightly above. |
| **Arbitration Eligible (Arb)** | 3–6 years | Players gain partial bargaining power; salaries begin to reflect performance. |
| **Free Agent Eligible (FA)** | 6+ years | Players receive full market value driven by open bidding and team competition. |

> **Why this matters:** Comparing a Pre-Arb player's salary to a Free Agent's without segmenting first would produce meaningless model results. Service time must be included in clustering.

International free agents (e.g., Shohei Ohtani, Yoshinobu Yamamoto) are manually assigned to the `FA` group regardless of MLB service time.

---

## 🔵 Part 2 — K-Means Clustering (Performance Groups)

Within each contract segment, **K-Means clustering** (`k = 4`) is applied on `WAR` and `service_time` (scaled) to group players by performance profile.

- **Batters:** 4 clusters
- **Pitchers:** 4 clusters
- **Total:** 8 groups across both player types

This produces **comparable peer groups** for salary modeling.

---

## 📐 Part 3 — PCA + Linear Regression (Salary Valuation)

For each contract group (FA and Arb), a **Principal Component Analysis (PCA)** reduces the performance metric space, and a **log-linear regression** predicts salary:

**Batter predictors:** `wRC+`, `HR`, `ISO`, `BB%`, `K%`, `Off`, `BsR`  
**Pitcher predictors:** `K/9`, `BB/9`, `HR/9`, `ERA`, `FIP`, `xFIP`, `GB%`  
**All models also include:** `WAR`, `age`, `service time`

Players are then flagged based on their **actual vs. predicted salary ratio**:

| Ratio | Flag |
|---|---|
| > 1.20 | 🔴 Overpaid |
| 0.80 – 1.20 | 🟢 Fairly Paid |
| < 0.80 | 🔵 Underpaid |

---

## 📊 Part 4 — Logistic Regression (Classification)

A **logistic regression** (`glm` with `family = binomial`) classifies players as **Overpaid (1)** or **not (0)** — and separately **Underpaid (1)** or **not (0)** — using the same performance predictors.

Odds ratios and effect sizes are reported for the top 10 most influential variables per group (All Batters, FA Batters, All Pitchers, FA Pitchers).

---

## 🧠 Part 5 — Neural Network Model

**Library:** `neuralnet` (R package)  
**Architecture:** Feedforward Multilayer Perceptron (MLP)  
**Hidden Layers:** `c(5, 4, 3)` — three hidden layers with 5, 4, and 3 neurons respectively  
**Output:** Linear (`linear.output = TRUE`)  
**Training:** Up to 1,000,000 steps, 20 repetitions (`rep = 20`)

**Preprocessing:**
- Min-Max normalization applied to all predictor variables
- `LogSalary` (target) is also Min-Max scaled and reverse-transformed after prediction

**Separate NN models are trained per cluster** (one model per K-Means group) for both batters and pitchers.

**Evaluation Metrics:**
- **RMSE** — Root Mean Squared Error (in dollars)
- **MAPE** — Mean Absolute Percentage Error
- **Anomaly threshold:** Players with >40% prediction error are flagged for review

---

## 📦 R Libraries Used

| Library | Purpose |
|---|---|
| `readxl` | Read Excel data |
| `dplyr` / `tidyverse` | Data wrangling |
| `caret` | Train/test split, preprocessing |
| `randomForest` | (Imported, available for extension) |
| `neuralnet` | Neural network modeling |
| `stats` | PCA (`prcomp`), GLM |
| `ggplot2` | Visualization |
| `scales` | Dollar-format axis labels |
| `stringr` | String cleaning |

---

## ▶️ How to Run

1. Place `Baseball_player.xlsx` in your working directory.
2. Open `BI_003_15_final_MLB.R` in RStudio.
3. Run the full script top-to-bottom. Each section is clearly commented.
4. Outputs include console tables, cluster plots, and ggplot visualizations.

---

## 💡 Key Concepts for Mentees

- **Why log-salary?** Salary distributions are right-skewed; log-transforming makes them more normally distributed and improves regression stability.
- **Why PCA?** Performance metrics are highly correlated. PCA condenses them into uncorrelated components to avoid multicollinearity.
- **Why cluster before modeling?** Players in different contract stages live in fundamentally different salary markets. One model for all players would be misleading.
- **Why neural networks on top of regression?** Neural nets can capture non-linear salary patterns that linear models miss — but they require normalized inputs and more data to train reliably.

---

## 🗓️ 5-Week Mentee Curriculum

> **Program Philosophy:** Mentees are given the *destination*, not the directions. The models to use are defined (clustering, linear regression, logistic regression, neural network), but every design decision — feature selection, thresholds, architecture, evaluation — is for the mentee to figure out and defend. The goal is independent thinking, not code-following.

Each week = ~1 mentor session (60–90 min) + independent work on the deliverable.

---

### Week 1 — First Pitch: Onboarding & Setup
`Guided` — *This is the only week with direct guidance. Everyone starts from the same baseline.*

**Goal:** Get oriented with the domain, the data source, and the tools. Understand what the project is trying to answer — and why it's hard.

Guiding questions:
- What is MLB's salary structure? Why does service time matter so much?
- What is FanGraphs? How do you navigate it, download data, and understand what each stat means?
- What is the difference between a batter and a pitcher stat sheet?
- Set up your environment: R or Python — your choice. Get the data loaded.
- What does "salary fairness" even mean? How would *you* define overpaid vs. underpaid?

**✏️ Deliverable:** Come next session with: (1) the data loaded, (2) a written definition of what "overpaid" means to you, and (3) one question about the data you don't know how to answer yet.

---

### Week 2 — Find the Groups: Clustering
`Open Design` — *Mentees decide how to cluster. The mentor only sets the destination.*

**Goal:** Segment players into meaningful groups before modeling. The goal is fair comparison — not mixing league-minimum rookies with $30M free agents.

Guiding questions:
- What makes two players truly "comparable" when it comes to salary?
- You know about MLB's service-time system from Week 1 — how should that shape your groups?
- What about international players who never went through the normal service-time path?
- What clustering method will you use? How many groups makes sense, and why?
- How will you know if your clusters are actually meaningful?

**✏️ Deliverable:** Present your clustering design — how many groups, what defines each one, and why. Be ready to defend your choices, not just show the output.

---

### Week 3 — Predict the Price: Linear Regression
`Open Design` — *Mentees choose their features, transformations, and evaluation approach.*

**Goal:** Build a model that predicts player salary from performance metrics. Use this to identify who is being paid fairly — and who isn't.

Guiding questions:
- Which stats do you think actually drive salary? Start with intuition, then test it.
- Salary distributions are skewed. Does that affect how you model? What can you do about it?
- Should you build one model for all players, or separate models per cluster? Why?
- How will you measure whether your predictions are actually good enough?
- How do you decide who is "overpaid" vs. "underpaid"? Where's your line — and how did you choose it?

**✏️ Deliverable:** Show your model, your accuracy metrics, and a list of the top 5 most overpaid and underpaid players. Explain the threshold you chose and why.

---

### Week 4 — Call the Play: Logistic Regression
`Open Design` — *Mentees decide what to classify, which features to include, and how to interpret.*

**Goal:** Flip the question — instead of predicting salary, classify whether a player IS overpaid or underpaid. Find out which performance stats are the biggest drivers.

Guiding questions:
- How is classification different from regression? What changes in your setup?
- Use the valuation flags from Week 3 as your target — but should you trust them as-is?
- Which stats end up mattering most? Does this match your Week 3 intuition?
- Do the same stats matter for batters and pitchers? For different contract groups?
- What does this model tell you that Week 3 didn't?

**✏️ Deliverable:** Present which 3 stats best predict overpayment, and which best predict being underpaid. Are they the same stats? Why or why not?

---

### Week 5 — Walk-Off: Neural Network + Final Presentation
`Open + Capstone` — *Mentees choose their own NN architecture and compare all three models themselves.*

**Goal:** Add a neural network to your analysis. Compare all three models. Present your full story — not just the results, but what you learned and what you'd do differently.

Guiding questions:
- What can a neural network do that linear regression can't? When would you choose one over the other?
- How do you prepare your data for a neural network? What's different from regression?
- How many layers? How many neurons? How do you decide — and how do you know if it's working?
- Compare your three models side by side: which performed best? Which was most interpretable?
- If you had 3 more weeks, what would you build next?

**✏️ Deliverable:** 10-minute final presentation covering your design decisions, model comparison, most interesting finding, and one thing you'd change. No slides required — just talk through it.

---

*Project developed as part of the mentee program. Data from FanGraphs.*
