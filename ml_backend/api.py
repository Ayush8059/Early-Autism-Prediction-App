import io
import os
from functools import lru_cache

import numpy as np
import tensorflow as tf
from fastapi import FastAPI, File, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from tensorflow.keras.layers import Dense, Dropout, GlobalAveragePooling2D
from tensorflow.keras.models import Model
from tensorflow.keras.preprocessing import image


MODEL_KIND = os.getenv("MODEL_KIND", "finetuned_weights")
MODEL_PATH = os.getenv("MODEL_PATH", "autism_detection_efficientnetb0_finetuned.weights.h5")
ML_API_KEY = os.getenv("ML_API_KEY", "") or os.getenv("MLAPIKEY", "")
TARGET_SIZE = (224, 224)

app = FastAPI(title="AutiSense ML API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)


@lru_cache(maxsize=1)
def load_model():
    if not os.path.exists(MODEL_PATH):
        raise FileNotFoundError(f"Model file not found: {MODEL_PATH}")

    if MODEL_KIND == "finetuned_weights" or MODEL_PATH.endswith(".weights.h5"):
        base_model = tf.keras.applications.EfficientNetB0(
            weights=None,
            include_top=False,
            input_shape=(224, 224, 3),
        )
        x = GlobalAveragePooling2D()(base_model.output)
        x = Dense(128, activation="relu")(x)
        x = Dropout(0.5)(x)
        output = Dense(1, activation="sigmoid")(x)
        model = Model(inputs=base_model.input, outputs=output)
        model.load_weights(MODEL_PATH)
        return model

    return tf.keras.models.load_model(MODEL_PATH)


def preprocess_image(image_bytes: bytes) -> np.ndarray:
    buffer = io.BytesIO(image_bytes)
    img = image.load_img(buffer, target_size=TARGET_SIZE)
    img_array = image.img_to_array(img)
    # The saved EfficientNetB0 model already contains its own Rescaling layer.
    # Passing 0-255 pixel values matches training/export behavior; dividing here
    # makes predictions collapse toward one class.
    return np.expand_dims(img_array, axis=0)


def risk_level_for_autistic_percent(autistic_percent: float) -> str:
    if autistic_percent >= 70:
        return "High"
    if autistic_percent >= 40:
        return "Medium"
    return "Low"


def verify_api_key(x_ml_api_key: str | None) -> None:
    if not ML_API_KEY:
        raise HTTPException(status_code=503, detail="ML API key is not configured.")
    if x_ml_api_key != ML_API_KEY:
        raise HTTPException(status_code=401, detail="Invalid ML API key.")


@app.get("/health")
def health(x_ml_api_key: str | None = Header(default=None)):
    verify_api_key(x_ml_api_key)
    load_model()
    return {"ok": True, "model": MODEL_PATH}


@app.get("/")
def root():
    return {
        "ok": True,
        "message": "AutiSense ML API is running. Use /health to test and /predict for image analysis.",
    }


@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    x_ml_api_key: str | None = Header(default=None),
):
    verify_api_key(x_ml_api_key)
    allowed_content_types = {
        "image/jpeg",
        "image/png",
        "image/jpg",
        "application/octet-stream",
    }
    if file.content_type not in allowed_content_types:
        raise HTTPException(status_code=400, detail="Upload a JPG or PNG image.")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image file is empty.")

    try:
        model = load_model()
        input_tensor = preprocess_image(image_bytes)
        raw_score = float(model.predict(input_tensor, verbose=0)[0][0])
    except Exception as exc:
        raise HTTPException(status_code=500, detail=f"Prediction failed: {exc}") from exc

    raw_score = max(0.0, min(1.0, raw_score))
    label = "Non_Autistic" if raw_score > 0.5 else "Autistic"
    non_autistic_percent = raw_score * 100
    autistic_percent = (1.0 - raw_score) * 100
    confidence_score = non_autistic_percent if label == "Non_Autistic" else autistic_percent
    risk_level = risk_level_for_autistic_percent(autistic_percent)

    if label == "Autistic":
        message = (
            f"The EfficientNetB0 model found a higher autistic-pattern signal "
            f"({autistic_percent:.1f}%). Use this only as screening support and "
            "consult a qualified doctor for an accurate diagnosis."
        )
    else:
        message = (
            f"The EfficientNetB0 model found a higher non-autistic-pattern signal "
            f"({non_autistic_percent:.1f}%). Continue monitoring and consult a "
            "qualified doctor if you have developmental concerns."
        )

    return {
        "label": label,
        "rawScore": raw_score,
        "confidenceScore": round(confidence_score, 2),
        "autisticPercent": round(autistic_percent, 2),
        "nonAutisticPercent": round(non_autistic_percent, 2),
        "riskLevel": risk_level,
        "message": message,
    }
