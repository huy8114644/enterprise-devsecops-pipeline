package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHealthHandler(t *testing.T) {
	req, err := http.NewRequest("GET", "/healthz", nil)
	if err != nil {
		t.Fatal(err)
	}

	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(healthHandler)
	handler.ServeHTTP(rr, req)

	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v want %v", status, http.StatusOK)
	}

	var resp HealthResponse
	if err := json.Unmarshal(rr.Body.Bytes(), &resp);
	err != nil {
		t.Fatalf("could not unmarshal response: %v", err)
	}

	if resp.Status != "healthy" {
		t.Errorf("expected status 'healthy', got %s", resp.Status)
	}
}

func TestSetupRoutesSecurityHeaders(t *testing.T) {
	handler := setupRoutes()

	paths := []string{"/healthz", "/readyz", "/api/v1/orders"}
	for _, p := range paths {
		req := httptest.NewRequest("GET", p, nil)
		rr := httptest.NewRecorder()
		handler.ServeHTTP(rr, req)

		if rr.Code != http.StatusOK {
			t.Errorf("path %s returned status %d, want 200", p, rr.Code)
		}

		expectedHeaders := map[string]string{
			"Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
			"X-Content-Type-Options":    "nosniff",
			"X-Frame-Options":           "DENY",
			"Referrer-Policy":           "strict-origin-when-cross-origin",
		}
		for k, v := range expectedHeaders {
			if got := rr.Header().Get(k); got != v {
				t.Errorf("path %s expected header %s: %s, got %s", p, k, v, got)
			}
		}
	}
}
