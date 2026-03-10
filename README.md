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
Service-Time Segmentation (Contract Type Assignment)
        ↓
K-Means Clustering (WAR × Service Time)
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

*Project developed as part of the mentee program. Data from FanGraphs.*
