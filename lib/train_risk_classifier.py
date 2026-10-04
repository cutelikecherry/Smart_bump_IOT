
import numpy as np
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

RANDOM_SEED = 42
N_SAMPLES = 4000


def generate_synthetic_data(n=N_SAMPLES, seed=RANDOM_SEED):
    rng = np.random.default_rng(seed)
    speed = rng.uniform(0, 50, n)               # km/h
    weather_hazard = rng.integers(0, 2, n)       # 0 or 1
    is_night = rng.integers(0, 2, n)             # 0 or 1
    noise = rng.normal(0, 5, n)

    risk_score = speed + weather_hazard * 15 + is_night * 10 + noise

    labels = np.where(risk_score < 20, 0, np.where(risk_score < 40, 1, 2))
    # 0 = Low, 1 = Medium, 2 = High

    X = np.column_stack([speed / 50.0, weather_hazard, is_night])  # normalize speed to 0-1 range
    return X, labels


def main():
    X, y = generate_synthetic_data()
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=RANDOM_SEED, stratify=y
    )

    model = LogisticRegression(max_iter=1000)  # multinomial is the default for lbfgs in modern sklearn
    model.fit(X_train, y_train)

    print("=== Test set performance ===")
    print(classification_report(y_test, model.predict(X_test),
                                 target_names=["Low", "Medium", "High"]))

    print("=== Coefficients (paste into risk_classifier.dart) ===")
    print("Classes order:", model.classes_, "-> [Low, Medium, High]")
    print("\ncoef_ (weights per class, per feature [speed_norm, weather_hazard, is_night]):")
    print(model.coef_)
    print("\nintercept_ (bias per class):")
    print(model.intercept_)

    print("\n--- Dart-ready format ---")
    print("static const List<List<double>> weights = [")
    for row in model.coef_:
        print("  [" + ", ".join(f"{v:.6f}" for v in row) + "],")
    print("];")
    print("static const List<double> biases = [" +
          ", ".join(f"{v:.6f}" for v in model.intercept_) + "];")


if __name__ == "__main__":
    main()
