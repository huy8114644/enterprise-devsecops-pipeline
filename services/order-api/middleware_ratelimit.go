package main

import (
	"net/http"
	"sync"
	"time"
)

type clientTracker struct {
	tokens     float64
	lastRefill time.Time
}

var (
	trackers = make(map[string]*clientTracker)
	mu       sync.Mutex
)

func RateLimitMiddleware(limitPerSec float64, burst float64) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ip := r.RemoteAddr
			mu.Lock()
			tracker, exists := trackers[ip]
			now := time.Now()

			if !exists {
				trackers[ip] = &clientTracker{tokens: burst, lastRefill: now}
				mu.Unlock()
				next.ServeHTTP(w, r)
				return
			}

			elapsed := now.Sub(tracker.lastRefill).Seconds()
			tracker.tokens += elapsed * limitPerSec
			if tracker.tokens > burst {
				tracker.tokens = burst
			}
			tracker.lastRefill = now

			if tracker.tokens < 1.0 {
				mu.Unlock()
				w.Header().Set("Retry-After", "1")
				http.Error(w, `{"error":"Too Many Requests"}`, http.StatusTooManyRequests)
				return
			}

			tracker.tokens -= 1.0
			mu.Unlock()
			next.ServeHTTP(w, r)
		})
	}
}
