# Smart Home IoT AI System (Clean Version)

import os
os.environ["OMP_NUM_THREADS"] = "1"

import serial
import csv
import threading
import time
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import silhouette_score
import gradio as gr

# =========================================================
# Settings
# =========================================================
CSV_FILE = "data.csv"
COM_PORT = 'COM4'      # غير البورت حسب جهازك
BAUD_RATE = 9600

# Lock لحماية الملف أثناء القراءة والكتابة
file_lock = threading.Lock()

# Variables للموديل
scaler = None
kmeans = None

# =========================================================
# 1. Collect Data from ESP32
# =========================================================
def collect_serial_data():
    ser = serial.Serial(COM_PORT, BAUD_RATE, timeout=1)
    time.sleep(2)

    with open(CSV_FILE, "w", newline="") as file:
        writer = csv.writer(file)
        writer.writerow(["Temp", "Humid", "gas", "soil", "rain", "pir", "distance"])

        print("Start streaming data from ESP32...")

        while True:
            line = ser.readline().decode('utf-8').strip()
            if not line:
                continue

            print("Received:", line)
            values = [v.strip() for v in line.split(",")]

            if len(values) == 7:
                with file_lock:
                    writer.writerow(values)
                    file.flush()
                print("Saved:", values)

# =========================================================
# 2. Auto Analysis
# =========================================================
def auto_analyze():
    global scaler, kmeans

    while True:
        time.sleep(5)

        with file_lock:
            df = pd.read_csv(CSV_FILE)

        if len(df) < 5:
            print("Waiting for more data...")
            time.sleep(10)
            continue

        # تنظيف البيانات وتحويل الأعمدة لأرقام
        df = df.fillna(0)
        for col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
        df = df.fillna(0)

        # منع القيم الشاذة
        df["distance"] = df["distance"].clip(0, 400)
        df["gas"] = df["gas"].clip(0, 1000)

        # Scaling
        scaler = StandardScaler()
        df_scaled = scaler.fit_transform(df)
        print("\n--- Data Preprocessing Done ---")

        # Correlation Analysis
        correlation = df.corr()
        print("\n--- Correlation Matrix ---")
        print(correlation)

        plt.figure(figsize=(8, 6))
        sns.heatmap(correlation, annot=True, cmap='coolwarm')
        plt.title('Sensors Correlation')
        plt.tight_layout()
        plt.show()
        plt.close()

        # KMeans Clustering
        kmeans = KMeans(n_clusters=3, random_state=42, n_init=10)
        
        train_start = time.time()
        kmeans.fit(df_scaled)
        train_end = time.time()

        test_start = time.time()
        labels = kmeans.predict(df_scaled)
        test_end = time.time()

        sil_score = silhouette_score(df_scaled, labels)

        print("\n" + "=" * 40)
        print("MODEL EVALUATION")
        print("=" * 40)
        print(f"Training Time: {train_end - train_start:.4f} sec")
        print(f"Testing Time : {test_end - test_start:.4f} sec")
        print(f"Silhouette Score: {sil_score:.4f}")
        print("=" * 40)

        # Cluster Visualization
        plt.figure(figsize=(7, 5))
        plt.scatter(df_scaled[:, 0], df_scaled[:, 1], c=labels, cmap='viridis')
        plt.xlabel('Temp')
        plt.ylabel('Humid')
        plt.title('KMeans Clusters')
        plt.tight_layout()
        plt.show()
        plt.close()

        # يحدث التحليل كل دقيقة
        time.sleep(60)

# =========================================================
# 3. Prediction Function
# =========================================================
def predict_iot_status(Temp, Humid, gas, soil, rain, pir, distance):
    global scaler, kmeans

    if scaler is None or kmeans is None:
        return "Model is not ready yet... Please wait."

    input_data = pd.DataFrame(
        [[Temp, Humid, gas, soil, rain, pir, distance]], 
        columns=["Temp", "Humid", "gas", "soil", "rain", "pir", "distance"]
    )

    # تنظيف القيم
    input_data["distance"] = input_data["distance"].clip(0, 400)
    input_data["gas"] = input_data["gas"].clip(0, 1000)

    # Scaling & Prediction
    input_scaled = scaler.transform(input_data)
    cluster = kmeans.predict(input_scaled)[0]

    # Smart Labels
    if cluster == 0:
        return "Normal Home Status"
    elif cluster == 1:
        return "Gas Leak / Dangerous Environment"
    else:
        return "Soil Needs Irrigation or Rain Detected"

# =========================================================
# 4. Start Background Threads
# =========================================================
threading.Thread(target=collect_serial_data, daemon=True).start()
threading.Thread(target=auto_analyze, daemon=True).start()

# =========================================================
# 5. Gradio Interface
# =========================================================
interface = gr.Interface(
    fn=predict_iot_status,
    inputs=[
        gr.Number(label="Temperature"),
        gr.Number(label="Humidity"),
        gr.Number(label="Gas"),
        gr.Number(label="Soil Moisture"),
        gr.Number(label="Rain"),
        gr.Number(label="PIR Motion"),
        gr.Number(label="Distance")
    ],
    outputs=gr.Textbox(label="AI Result"),
    title="Smart Home IoT AI Monitoring System",
    description="Real-time Smart Home Monitoring using ESP32 + Machine Learning"
)

# =========================================================
# 6. Launch App
# =========================================================
interface.launch()