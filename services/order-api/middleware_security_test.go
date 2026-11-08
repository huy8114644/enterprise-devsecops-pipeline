package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestSecurityHeadersMiddleware(t *testing.T) {
	req := httptest.NewRequest("GET", "/healthz", nil)
	rr := httptest.NewRecorder()

	holder := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	httpHandler := SecurityHeadersMiddleware(holder)
	httpHandler.ServeHTTP(rr, req)

	headers := map[string]string{
		"X-Frame-Options": "DENY",
		"X-Content-Type-Options": "nosniff",
		"Strict-Transport-Security": "max-age=63072000; includeSubDomains; preload",
	}

	for k, v := range headers {
		if val := rr.Header().Get(k); val != v {
			t.Errorf("expected header %s: %s, got %s", k, v, val)
		}
	}
}
