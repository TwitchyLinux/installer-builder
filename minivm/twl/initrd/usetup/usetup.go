package main

import (
	"fmt"
	"os"
	"path"
	"strings"

	"github.com/u-root/u-root/pkg/cmdline"
	"github.com/u-root/u-root/pkg/kmodule"
	"github.com/u-root/u-root/pkg/mount"
)

func storeDev() string {
	store, present := cmdline.Flag("uroot.nix-store")
	if !present {
		return "/dev/sda"
	}
	return store
}

func mnt(dev, to, opts string) error {
	if strings.HasPrefix(dev, "virtio-9p-pci:") {
		_, err := mount.Mount(dev[len("virtio-9p-pci:"):], to, "9p", opts, 0)
		return err
	}
	_, err := mount.Mount(dev, to, "squashfs", opts, 0)
	return err
}

func setupAuxMount(name, dev string, ro bool) error {
	opts := ""
	if ro {
		opts = "ro"
	}

	p := path.Join("/mnt", name)
	if err := os.MkdirAll(p, 0755); err != nil {
		return err
	}
	return mnt(dev, p, opts)
}

func setupStore() error {
	// mkdir -p /nix/{store,.ro-store,.rw-store}
	for _, p := range []string{
		"/nix/store",
		"/nix/.ro-store",
		"/nix/.rw-store",
	} {
		if err := os.MkdirAll(p, 0755); err != nil {
			return err
		}
	}

	// mount -t squashfs /dev/sda /nix/.ro-store
	if err := mnt(storeDev(), "/nix/.ro-store", "ro"); err != nil {
		return err
	}
	// mount -t tmpfs -o mode=0755 /nix/.rw-store /nix/.rw-store
	if _, err := mount.Mount("/nix/.rw-store", "/nix/.rw-store", "tmpfs", "mode=0755", 0); err != nil {
		return err
	}

	for _, p := range []string{
		"/nix/.rw-store/work",
		"/nix/.rw-store/upper",
	} {
		if err := os.MkdirAll(p, 0755); err != nil {
			return err
		}
	}

	//   mount -t overlay \
	//    -o lowerdir=/nix/.ro-store,upperdir=/nix/.rw-store/upper,workdir=/nix/.rw-store/work \
	//       overlay /nix/store
	if _, err := mount.Mount("overlay", "/nix/store", "overlay", "lowerdir=/nix/.ro-store,upperdir=/nix/.rw-store/upper,workdir=/nix/.rw-store/work", 0); err != nil {
		return err
	}

	return nil
}

func needVirtio9p() bool {
	for _, val := range cmdline.NewCmdLine().AsMap {
		val := strings.TrimPrefix(val, "ro:")
		if strings.HasPrefix(val, "virtio-9p-pci:") {
			return true
		}
	}
	return false
}

func main() {
	if needVirtio9p() {
		fmt.Println("loading module \"9p\"")
		if err := kmodule.Probe("9p", ""); err != nil {
			fmt.Printf("Failed to load module: %v\n", err)
			os.Exit(1)
		}
	}

	for key, val := range cmdline.NewCmdLine().AsMap {
		if strings.HasPrefix(key, "uroot.mount.") {
			name, ro := strings.TrimPrefix(key, "uroot.mount."), false
			if strings.HasPrefix(val, "ro:") {
				val = strings.TrimPrefix(val, "ro:")
				ro = true
			}

			if err := setupAuxMount(name, val, ro); err != nil {
				fmt.Printf("Failed to setup auxillary mount %s: %v\n", name, err)
				os.Exit(1)
			}
		}
	}

	if err := setupStore(); err != nil {
		fmt.Printf("Failed to setup nix store: %v\n", err)
		os.Exit(1)
	}
}
