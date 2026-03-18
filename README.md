# Crop Yield Prediction in Sub-Saharan Africa

**Mission:** I aim to empower the next generation of African farmers by introducing suitable solution systems using tech to combat harsh weather, improve food security, and foster economic growth for farming communities.

**Problem:** Farmers in Sub-Saharan Africa lack data-driven tools to predict crop yield based on their region, crop type, and farming method (rain-fed vs irrigated). This model predicts yield (tons/hectare) so farmers can choose the best production systems for their conditions.

## Dataset

Source: [Africa Food Production Data v1.0](https://github.com/ALU-BSE/summative-linear-regression/blob/main/dataSet/Africa%20Data%20v1.0.csv) — 203,125 records across 32 African countries covering crop yields, areas, and production systems.

## Part 1: Model Training (Notebook)

Three models were trained and compared:
- **Linear Regression (SGD)** — R² = 0.129, MSE = 9.45
- **Decision Tree** — R² = 0.818, MSE = 1.98
- **Random Forest (best)** — R² = 0.874, MSE = 1.37

See `summative/linear_regression/multivariate.ipynb` for full analysis.

## Part 2: Prediction API (FastAPI)

A REST API built with FastAPI that serves predictions from the trained Random Forest model.

**API URL:** https://linear-regression-model-05uj.onrender.com/docs#/default/predict_predict_post

### Endpoints
| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Welcome message |
| POST | `/predict` | Predict crop yield |
| POST | `/retrain` | Retrain model with new CSV data |
| GET | `/docs` | Interactive Swagger UI |

### Run Locally
```bash
cd summative/API
pip install -r requirements.txt
uvicorn prediction:app --reload
```

### Example Request
```json
POST /predict
{
  "country": "Kenya",
  "admin_1": "Mombasa",
  "product": "Maize",
  "season_name": "Annual",
  "crop_production_system": "All (PS)",
  "planting_year": 2015,
  "planting_month": 3,
  "harvest_year": 2015,
  "harvest_month": 8,
  "area": 5000.0
}
```
