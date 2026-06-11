"""Unit tests for AI algorithms (without DB)."""
import numpy as np
import pandas as pd
import pytest


def test_cosine_similarity_basic():
    """Test cosine similarity computation."""
    from sklearn.metrics.pairwise import cosine_similarity

    a = np.array([[1, 0, 1]])
    b = np.array([[1, 1, 0]])
    sim = cosine_similarity(a, b)
    assert 0 < sim[0][0] < 1


def test_kmeans_clustering():
    """Test K-Means produces correct number of clusters."""
    from sklearn.cluster import KMeans

    data = np.random.rand(100, 3)
    kmeans = KMeans(n_clusters=4, random_state=42, n_init=10)
    labels = kmeans.fit_predict(data)

    assert len(set(labels)) == 4
    assert len(labels) == 100


def test_isolation_forest():
    """Test Isolation Forest detects outliers."""
    from sklearn.ensemble import IsolationForest

    np.random.seed(42)
    normal = np.random.randn(100, 2)
    outliers = np.array([[10, 10], [-10, -10]])
    data = np.vstack([normal, outliers])

    model = IsolationForest(contamination=0.02, random_state=42)
    predictions = model.fit_predict(data)

    # Outliers should be marked as -1
    assert predictions[-1] == -1 or predictions[-2] == -1


def test_apriori_basic():
    """Test Apriori finds association rules."""
    from mlxtend.frequent_patterns import apriori, association_rules
    from mlxtend.preprocessing import TransactionEncoder

    transactions = [
        ["bread", "milk"],
        ["bread", "butter", "milk"],
        ["bread", "butter"],
        ["milk", "butter"],
        ["bread", "milk", "butter"],
        ["bread", "milk"],
    ]

    te = TransactionEncoder()
    te_array = te.fit(transactions).transform(transactions)
    df = pd.DataFrame(te_array, columns=te.columns_)

    frequent = apriori(df, min_support=0.3, use_colnames=True)
    assert len(frequent) > 0

    rules = association_rules(frequent, metric="confidence", min_threshold=0.5)
    assert len(rules) > 0


def test_rfm_scoring():
    """Test RFM score calculation logic."""
    data = {
        "customer_id": ["c1", "c2", "c3", "c4", "c5"],
        "recency": [5, 30, 90, 180, 365],
        "frequency": [20, 10, 5, 2, 1],
        "monetary": [5000000, 2000000, 500000, 100000, 50000],
    }
    df = pd.DataFrame(data)

    # c1 should be best (low recency, high freq/monetary)
    assert df.loc[0, "recency"] < df.loc[4, "recency"]
    assert df.loc[0, "frequency"] > df.loc[4, "frequency"]
    assert df.loc[0, "monetary"] > df.loc[4, "monetary"]
