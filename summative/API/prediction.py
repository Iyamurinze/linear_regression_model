import os
import numpy as np
import pandas as pd
import joblib
from typing import Literal
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.preprocessing import LabelEncoder, StandardScaler
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
import io

# --- Paths to model artifacts ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "..", "linear_regression")

model = joblib.load(os.path.join(MODEL_DIR, "best_model.pkl"))
scaler = joblib.load(os.path.join(MODEL_DIR, "scaler.pkl"))
label_encoders = joblib.load(os.path.join(MODEL_DIR, "label_encoders.pkl"))
feature_columns = joblib.load(os.path.join(MODEL_DIR, "feature_columns.pkl"))

# --- Valid values extracted from label encoders ---
VALID_COUNTRIES = Literal[
    'Angola', 'Benin', 'Burkina Faso', 'Burundi', 'Cameroon',
    'Central African Republic', 'Chad', 'DRC', 'Ethiopia', 'Ghana',
    'Kenya', 'Lesotho', 'Liberia', 'Madagascar', 'Malawi', 'Mali',
    'Mauritania', 'Mozambique', 'Niger', 'Nigeria', 'Rwanda', 'Senegal',
    'Sierra Leone', 'Somalia', 'South Africa', 'South Sudan', 'Sudan',
    'Tanzania, United Republic of', 'Togo', 'Uganda', 'Zambia', 'Zimbabwe'
]

VALID_PRODUCTS = Literal[
    'Avocado', 'Bambara groundnut', 'Banana', 'Barley', 'Bean (Hyacinth)',
    'Beans (Rosecoco)', 'Beans (White)', 'Beans (mixed)', 'Beet', 'Bush Bean',
    'Cabbage', 'Canola Seed', 'Capsicum Chinense', 'Carrots',
    'Cashew (unshelled)', 'Cassava', 'Celery', 'Cereal Crops', 'Chick Peas',
    'Chili Pepper', 'Coffee', 'Coriander', 'Cotton', 'Cotton (Acala)',
    'Cotton (American)', 'Cottonseed', 'Cowpea', 'Cucumber', 'Eggplant',
    'Ethiopian Cabbage', 'Fava Bean', 'Fenugreek', 'Field Peas', 'Fonio',
    'Garlic', 'Geocarpa groundnut', 'Ginger', 'Goussi', 'Green Bean',
    'Green Peppers', 'Groundnuts (In Shell)', 'Hops', 'Jute', 'Kale',
    'Lemon', 'Lentils', 'Lettuce', 'Linseed', 'Macadamia', 'Maize',
    'Maize (Yellow)', 'Mango', 'Melon', 'Millet', 'Molokhia', 'Mung bean',
    'Neug', 'Oats', 'Okras', 'Onions', 'Orange', 'Pam Nut', 'Papaya',
    'Paprika', 'Pea', 'Pepper', 'Pigeon Pea', 'Pineapple', 'Pole Bean',
    'Potato', 'Pyrethrum', 'Rape', 'Rice', 'Sesame Seed', 'Sorghum',
    'Sorghum (Red)', 'Sorrel', 'Soybean', 'Squash',
    'Squash and Melon Seeds', 'Sugarcane', 'Sunflower Seed', 'Sweet Potatoes',
    'Taro', 'Tea', 'Teff', 'Tobacco', 'Tomato', 'Velvet Bean',
    'Virginia Peanut', 'Watermelon', 'Wheat', 'Yams'
]

VALID_SEASONS = Literal[
    '1st Season', '2nd Season', 'Annual', 'Bas-fond', 'Cold off-season',
    'Cold-off', 'Cotton season', 'Dam retention', 'Decrue controlee', 'Deyr',
    'Deyr-off', 'Dry', 'First', 'Gu', 'Gu-off', 'Hot off-season', 'Long',
    'Long/Dry', 'Main', 'Main-off', 'Meher', 'North 1st Season',
    'North 2nd Season', 'Rice season', 'Season A', 'Season B', 'Season C',
    'Second', 'Short', 'Summer', 'Walo', 'Wet', 'Winter'
]

VALID_PRODUCTION_SYSTEMS = Literal[
    'A1 (PS)', 'A2 (PS)', 'All (PS)', 'Bas-fonds rainfed (PS)', 'CA (PS)',
    'Commercial (PS)', 'Communal (PS)', 'LSCF (PS)', 'Mechanized (PS)',
    'OR (PS)', 'Plaine/Bas-fond irrigated (PS)', 'Rainfed (PS)',
    'SSCF (PS)', 'Semi-Mechanized (PS)', 'Small_and_medium_scale',
    'agro_pastoral', 'dam irrigation', 'dieri', 'irrigated', 'large_scale',
    'mechanized_rainfed', 'none', 'parastatal recessional',
    'recessional (PS)', 'riverine', 'surface water', 'traditional_rainfed'
]


# --- Pydantic Input Model ---
class YieldInput(BaseModel):
    country: VALID_COUNTRIES
    admin_1: str = Field(..., description="Administrative region (e.g., Mombasa, Nairobi)")
    product: VALID_PRODUCTS
    season_name: VALID_SEASONS
    crop_production_system: VALID_PRODUCTION_SYSTEMS
    planting_year: int = Field(..., ge=1960, le=2030)
    planting_month: int = Field(..., ge=1, le=12)
    harvest_year: int = Field(..., ge=1960, le=2030)
    harvest_month: int = Field(..., ge=1, le=12)
    area: float = Field(..., gt=0, description="Area in hectares")

    class Config:
        json_schema_extra = {
            "example": {
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
        }


# --- FastAPI App ---
app = FastAPI(
    title="Crop Yield Prediction API",
    description=(
        "Predicts crop yield (tons/hectare) for Sub-Saharan Africa using a "
        "Random Forest model trained on historical agricultural data from 32 countries."
    ),
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:5173",
        "https://linear-regression-model-rk6z.onrender.com",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)


@app.get("/")
def root():
    return {
        "message": "Welcome to the Crop Yield Prediction API",
        "description": "Predict crop yield in tons/hectare for Sub-Saharan Africa",
        "endpoints": {
            "/predict": "POST - Predict crop yield",
            "/retrain": "POST - Retrain the model with new CSV data",
            "/docs": "GET - Interactive API documentation (Swagger UI)",
        },
    }


@app.post("/predict")
def predict(data: YieldInput):
    global model, scaler, label_encoders, feature_columns

    # Validate admin_1 against known values
    if data.admin_1 not in label_encoders["admin_1"].classes_:
        raise HTTPException(
            status_code=400,
            detail=f"Unknown admin_1 region: '{data.admin_1}'. "
            f"Valid regions include: {list(label_encoders['admin_1'].classes_[:20])}... "
            f"({len(label_encoders['admin_1'].classes_)} total)",
        )

    # Compute engineered features
    grow_duration = data.harvest_month - data.planting_month
    if grow_duration < 0:
        grow_duration += 12
    log_area = np.log1p(data.area)

    # Encode categorical features
    input_dict = {
        "country": label_encoders["country"].transform([data.country])[0],
        "admin_1": label_encoders["admin_1"].transform([data.admin_1])[0],
        "product": label_encoders["product"].transform([data.product])[0],
        "season_name": label_encoders["season_name"].transform([data.season_name])[0],
        "crop_production_system": label_encoders["crop_production_system"].transform(
            [data.crop_production_system]
        )[0],
        "planting_year": data.planting_year,
        "planting_month": data.planting_month,
        "harvest_year": data.harvest_year,
        "harvest_month": data.harvest_month,
        "area": data.area,
        "grow_duration": grow_duration,
        "log_area": log_area,
    }

    # Build input DataFrame in correct column order
    input_df = pd.DataFrame([[input_dict[col] for col in feature_columns]], columns=feature_columns)
    input_scaled = scaler.transform(input_df)
    prediction = model.predict(input_scaled)[0]

    return {
        "prediction": round(float(prediction), 4),
        "unit": "tons/hectare",
        "input_summary": {
            "country": data.country,
            "product": data.product,
            "area_hectares": data.area,
            "season": data.season_name,
        },
    }


@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    global model, scaler, label_encoders, feature_columns

    if not file.filename.endswith(".csv"):
        raise HTTPException(status_code=400, detail="Only CSV files are accepted.")

    try:
        contents = await file.read()
        df = pd.read_csv(io.BytesIO(contents))
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to read CSV: {str(e)}")

    # Validate required columns
    required_cols = [
        "country", "admin_1", "product", "season_name",
        "planting_year", "planting_month", "harvest_year", "harvest_month",
        "crop_production_system", "area", "yield",
    ]
    missing = [c for c in required_cols if c not in df.columns]
    if missing:
        raise HTTPException(
            status_code=400,
            detail=f"Missing required columns: {missing}. Required: {required_cols}",
        )

    # Clean data (same preprocessing as original notebook)
    df = df.dropna(subset=["yield", "area"])
    df = df[df["area"] > 0]

    # Remove outliers - critical for model quality
    yield_95 = df["yield"].quantile(0.95)
    area_99 = df["area"].quantile(0.99)
    df = df[df["yield"] <= yield_95]
    df = df[df["area"] <= area_99]

    if len(df) < 10:
        raise HTTPException(
            status_code=400,
            detail="Not enough valid data rows (need at least 10 after cleaning).",
        )

    # Encode categorical columns
    categorical_cols = ["country", "admin_1", "product", "season_name", "crop_production_system"]
    new_label_encoders = {}
    for col in categorical_cols:
        le = LabelEncoder()
        df[col] = le.fit_transform(df[col])
        new_label_encoders[col] = le

    # Engineer features
    df["grow_duration"] = (df["harvest_month"] - df["planting_month"]).apply(
        lambda x: x + 12 if x < 0 else x
    )
    df["log_area"] = np.log1p(df["area"])

    # Drop non-feature columns (keep only model inputs)
    cols_to_keep = [
        "country", "admin_1", "product", "season_name",
        "planting_year", "planting_month", "harvest_year", "harvest_month",
        "crop_production_system", "area", "grow_duration", "log_area",
    ]
    X = df[cols_to_keep]
    y = df["yield"]

    new_feature_columns = X.columns.tolist()

    # Scale
    new_scaler = StandardScaler()
    X_scaled = new_scaler.fit_transform(X)

    # Train-test split
    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=0.2, random_state=42
    )

    # Retrain
    new_model = RandomForestRegressor(
        n_estimators=50, min_samples_split=5, min_samples_leaf=1,
        random_state=42, n_jobs=-1,
    )
    new_model.fit(X_train, y_train)

    train_mse = mean_squared_error(y_train, new_model.predict(X_train))
    test_mse = mean_squared_error(y_test, new_model.predict(X_test))
    test_r2 = r2_score(y_test, new_model.predict(X_test))

    # Save new artifacts
    joblib.dump(new_model, os.path.join(MODEL_DIR, "best_model.pkl"), compress=3)
    joblib.dump(new_scaler, os.path.join(MODEL_DIR, "scaler.pkl"))
    joblib.dump(new_label_encoders, os.path.join(MODEL_DIR, "label_encoders.pkl"))
    joblib.dump(new_feature_columns, os.path.join(MODEL_DIR, "feature_columns.pkl"))

    # Update global references
    model = new_model
    scaler = new_scaler
    label_encoders = new_label_encoders
    feature_columns = new_feature_columns

    return {
        "message": "Model retrained successfully",
        "metrics": {
            "train_mse": round(train_mse, 4),
            "test_mse": round(test_mse, 4),
            "test_r2": round(test_r2, 4),
        },
        "data_info": {
            "rows_used": len(df),
            "features": new_feature_columns,
        },
    }
