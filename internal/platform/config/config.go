// Package config loads process configuration without exposing secret values.
package config

import (
	"fmt"
	"net"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"
)

var namespacePattern = regexp.MustCompile(`^[a-z0-9]([-a-z0-9]*[a-z0-9])?$`)

// Config contains non-secret process settings shared by the API and worker.
type Config struct {
	Server  ServerConfig
	Runtime RuntimeConfig
}

// ServerConfig controls the HTTP server process.
type ServerConfig struct {
	Address         string
	ShutdownTimeout time.Duration
}

// RuntimeConfig controls safe runtime orchestration behavior.
type RuntimeConfig struct {
	Namespace           string
	OperationSyncBudget time.Duration
	WorkerPollInterval  time.Duration
}

// Load reads and validates the process environment.
func Load() (Config, error) {
	return loadFromLookup(os.LookupEnv)
}

func loadFromLookup(lookup func(string) (string, bool)) (Config, error) {
	address, err := required(lookup, "GPC_SERVER_ADDR")
	if err != nil {
		return Config{}, err
	}
	if err := validateAddress(address); err != nil {
		return Config{}, err
	}

	shutdownTimeout, err := requiredDuration(lookup, "GPC_SERVER_SHUTDOWN_TIMEOUT")
	if err != nil {
		return Config{}, err
	}

	namespace, err := required(lookup, "GPC_RUNTIME_NAMESPACE")
	if err != nil {
		return Config{}, err
	}
	if err := validateNamespace(namespace); err != nil {
		return Config{}, err
	}

	operationSyncBudget, err := requiredDuration(lookup, "GPC_OPERATION_SYNC_BUDGET")
	if err != nil {
		return Config{}, err
	}
	workerPollInterval, err := requiredDuration(lookup, "GPC_WORKER_POLL_INTERVAL")
	if err != nil {
		return Config{}, err
	}

	return Config{
		Server: ServerConfig{
			Address:         address,
			ShutdownTimeout: shutdownTimeout,
		},
		Runtime: RuntimeConfig{
			Namespace:           namespace,
			OperationSyncBudget: operationSyncBudget,
			WorkerPollInterval:  workerPollInterval,
		},
	}, nil
}

func required(lookup func(string) (string, bool), key string) (string, error) {
	value, ok := lookup(key)
	if !ok || strings.TrimSpace(value) == "" {
		return "", fmt.Errorf("configuration %s is required", key)
	}
	return value, nil
}

func requiredDuration(lookup func(string) (string, bool), key string) (time.Duration, error) {
	value, err := required(lookup, key)
	if err != nil {
		return 0, err
	}

	duration, err := time.ParseDuration(value)
	if err != nil || duration <= 0 {
		return 0, fmt.Errorf("configuration %s must be a positive duration", key)
	}
	return duration, nil
}

func validateAddress(address string) error {
	_, port, err := net.SplitHostPort(address)
	if err != nil {
		return fmt.Errorf("configuration GPC_SERVER_ADDR must be a host:port address")
	}

	portNumber, err := strconv.Atoi(port)
	if err != nil || portNumber < 1 || portNumber > 65535 {
		return fmt.Errorf("configuration GPC_SERVER_ADDR must contain a port between 1 and 65535")
	}
	return nil
}

func validateNamespace(namespace string) error {
	if len(namespace) > 63 || !namespacePattern.MatchString(namespace) {
		return fmt.Errorf("configuration GPC_RUNTIME_NAMESPACE must be a DNS label")
	}
	return nil
}
