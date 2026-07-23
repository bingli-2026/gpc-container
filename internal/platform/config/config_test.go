package config

import (
	"strings"
	"testing"
	"time"
)

func TestLoadFromLookupLoadsValidatedServerAndRuntimeSettings(t *testing.T) {
	t.Parallel()

	environment := map[string]string{
		"GPC_SERVER_ADDR":             "127.0.0.1:8080",
		"GPC_SERVER_SHUTDOWN_TIMEOUT": "10s",
		"GPC_RUNTIME_NAMESPACE":       "gpc-workspaces",
		"GPC_OPERATION_SYNC_BUDGET":   "2s",
		"GPC_WORKER_POLL_INTERVAL":    "1s",
	}

	config, err := loadFromLookup(func(key string) (string, bool) {
		value, ok := environment[key]
		return value, ok
	})
	if err != nil {
		t.Fatalf("loadFromLookup() error = %v", err)
	}

	if config.Server.Address != "127.0.0.1:8080" {
		t.Errorf("Server.Address = %q, want %q", config.Server.Address, "127.0.0.1:8080")
	}
	if config.Server.ShutdownTimeout != 10*time.Second {
		t.Errorf("Server.ShutdownTimeout = %s, want %s", config.Server.ShutdownTimeout, 10*time.Second)
	}
	if config.Runtime.Namespace != "gpc-workspaces" {
		t.Errorf("Runtime.Namespace = %q, want %q", config.Runtime.Namespace, "gpc-workspaces")
	}
	if config.Runtime.OperationSyncBudget != 2*time.Second {
		t.Errorf("Runtime.OperationSyncBudget = %s, want %s", config.Runtime.OperationSyncBudget, 2*time.Second)
	}
	if config.Runtime.WorkerPollInterval != time.Second {
		t.Errorf("Runtime.WorkerPollInterval = %s, want %s", config.Runtime.WorkerPollInterval, time.Second)
	}
}

func TestLoadFromLookupRejectsMissingRequiredSetting(t *testing.T) {
	t.Parallel()

	_, err := loadFromLookup(func(key string) (string, bool) {
		return "", false
	})
	if err == nil {
		t.Fatal("loadFromLookup() error = nil, want missing required setting error")
	}
	if !strings.Contains(err.Error(), "GPC_SERVER_ADDR") {
		t.Errorf("loadFromLookup() error = %q, want GPC_SERVER_ADDR", err)
	}
}

func TestLoadFromLookupRejectsUnsafeServerAddress(t *testing.T) {
	t.Parallel()

	environment := validEnvironment()
	environment["GPC_SERVER_ADDR"] = "localhost:not-a-port"

	_, err := loadFromLookup(lookup(environment))
	if err == nil {
		t.Fatal("loadFromLookup() error = nil, want invalid server address error")
	}
	if !strings.Contains(err.Error(), "GPC_SERVER_ADDR") {
		t.Errorf("loadFromLookup() error = %q, want GPC_SERVER_ADDR", err)
	}
}

func TestLoadFromLookupRejectsInvalidRuntimeSettings(t *testing.T) {
	t.Parallel()

	environment := validEnvironment()
	environment["GPC_RUNTIME_NAMESPACE"] = "GPC_Workspaces"

	_, err := loadFromLookup(lookup(environment))
	if err == nil {
		t.Fatal("loadFromLookup() error = nil, want invalid runtime namespace error")
	}
	if !strings.Contains(err.Error(), "GPC_RUNTIME_NAMESPACE") {
		t.Errorf("loadFromLookup() error = %q, want GPC_RUNTIME_NAMESPACE", err)
	}
}

func validEnvironment() map[string]string {
	return map[string]string{
		"GPC_SERVER_ADDR":             ":8080",
		"GPC_SERVER_SHUTDOWN_TIMEOUT": "10s",
		"GPC_RUNTIME_NAMESPACE":       "gpc-workspaces",
		"GPC_OPERATION_SYNC_BUDGET":   "2s",
		"GPC_WORKER_POLL_INTERVAL":    "1s",
	}
}

func lookup(environment map[string]string) func(string) (string, bool) {
	return func(key string) (string, bool) {
		value, ok := environment[key]
		return value, ok
	}
}
