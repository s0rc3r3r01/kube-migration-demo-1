// Package v1 contains the full set of handler functions and routes
// supported by the v1 web api.
package v1

import (
	"net/http"

	"github.com/jmoiron/sqlx"
	"github.com/s0rc3r3r01/kube-migration-demo-1/app/services/service/handlers/v1/productgrp"
	"github.com/s0rc3r3r01/kube-migration-demo-1/business/core/product"
	"github.com/s0rc3r3r01/kube-migration-demo-1/business/core/product/stores/productdb"
	"github.com/s0rc3r3r01/kube-migration-demo-1/foundation/web"
	"go.uber.org/zap"
)

// Config contains all the mandatory systems required by handlers.
type Config struct {
	Log *zap.SugaredLogger
	DB  *sqlx.DB
}

// Routes binds all the version 1 routes.
func Routes(app *web.App, cfg Config) {
	const version = "v1"

	pgh := productgrp.Handlers{
		Product: product.NewCore(productdb.NewStore(cfg.Log, cfg.DB)),
	}
	app.Handle(http.MethodGet, version, "/products/:page/:rows", pgh.Query)
	app.Handle(http.MethodGet, version, "/products/:id", pgh.QueryByID)
	app.Handle(http.MethodPost, version, "/products", pgh.Create)
	app.Handle(http.MethodPut, version, "/products/:id", pgh.Update)
	app.Handle(http.MethodDelete, version, "/products/:id", pgh.Delete)
}
