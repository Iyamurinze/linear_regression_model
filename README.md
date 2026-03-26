# Crop Yield Prediction in Sub-Saharan Africa

**Mission:** I aim to empower the next generation of African farmers by introducing suitable solution systems using tech to combat harsh weather, improve food security, and foster economic growth for farming communities.

**Problem:** Farmers in Sub-Saharan Africa lack data-driven tools to predict crop yield based on their region, crop type, and farming method (rain-fed vs irrigated). This model predicts yield (tons/hectare) so farmers can choose the best production systems for their conditions.

## Part 1: Model Training (Notebook)

Three models were trained and compared:
- **Linear Regression (SGD)** — R² = 0.129, MSE = 9.45
- **Decision Tree** — R² = 0.818, MSE = 1.98
- **Random Forest (best)** — R² = 0.874, MSE = 1.37

See `summative/linear_regression/multivariate.ipynb` for full analysis.

## Part 2: Prediction API (FastAPI)

A REST API built with FastAPI that serves predictions from the trained Random Forest model.

**API URL:** https://linear-regression-model-05uj.onrender.com/docs#/default/predict_predict_post

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

## Part 3: Flutter Mobile App

A Flutter app that connects to the prediction API, allowing farmers to input crop details and get yield predictions on mobile.

### Run the App
```bash
cd summative/FlutterApp/my_app
flutter pub get
flutter run
```

> Requires [Flutter SDK](https://docs.flutter.dev/get-started/install) installed. Use `flutter run -d chrome` for web or connect a device/emulator for mobile.

### Demo link
https://youtu.be/9M-RTUzjTxs