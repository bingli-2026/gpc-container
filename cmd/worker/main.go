// Command worker starts the asynchronous control-plane worker process.
package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
)

func main() {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	log.Print("worker started")
	<-ctx.Done()
	log.Print("worker stopped")
}
