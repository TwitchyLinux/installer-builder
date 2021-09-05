boot.kernelPatches = [ {
  name = "compiled-in fs support";
  patch = null;
  extraConfig = ''
        NET_9P y
        NET_9P_VIRTIO y
        9P_FS y
        9P_FS_POSIX_ACL y
        PCI y
        VIRTIO_PCI y

        PCI y
        VIRTIO_PCI y

        SQUASHFS y
        '';
  } ];
