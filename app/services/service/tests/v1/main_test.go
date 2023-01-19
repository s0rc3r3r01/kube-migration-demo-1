package tests

import (
	"fmt"
	"testing"

	"github.com/s0rc3r3r01/kube-migration-demo-1/business/data/dbtest"
	"github.com/s0rc3r3r01/kube-migration-demo-1/foundation/docker"
)

var c *docker.Container

func TestMain(m *testing.M) {
	var err error
	c, err = dbtest.StartDB()
	if err != nil {
		fmt.Println(err)
		return
	}
	defer dbtest.StopDB(c)

	m.Run()
}
