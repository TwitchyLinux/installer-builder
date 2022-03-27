# Copyright (c) 2003-2022 Eelco Dolstra and the Nixpkgs/NixOS contributors

# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:

# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# This module allows the test driver to connect to the virtual machine
# via a root shell attached to port 514.

{ options, config, lib, pkgs, ... }:

with lib;

let
  qemu-common = import <nixpkgs/nixos/lib/qemu-common.nix> { inherit lib pkgs; };
in

{

  config = {

    systemd.services.backdoor =
      { wantedBy = [ "multi-user.target" ];
        requires = [ "dev-hvc0.device" "dev-${qemu-common.qemuSerialDevice}.device" ];
        after = [ "dev-hvc0.device" "dev-${qemu-common.qemuSerialDevice}.device" ];
        script =
          ''
            export USER=root
            export HOME=/root
            export DISPLAY=:0.0

            source /etc/profile

            # Don't use a pager when executing backdoor
            # actions. Because we use a tty, commands like systemctl
            # or nix-store get confused into thinking they're running
            # interactively.
            export PAGER=

            cd /tmp
            exec < /dev/hvc0 > /dev/hvc0
            while ! exec 2> /dev/${qemu-common.qemuSerialDevice}; do sleep 0.1; done
            echo "connecting to host..." >&2
            stty -F /dev/hvc0 raw -echo # prevent nl -> cr/nl conversion
            echo
            PS1= exec /bin/sh
          '';
        serviceConfig.KillSignal = "SIGHUP";
      };

    # Prevent agetty from being instantiated on the serial device, since it
    # interferes with the backdoor (writes to it will randomly fail
    # with EIO).  Likewise for hvc0.
    systemd.services."serial-getty@${qemu-common.qemuSerialDevice}".enable = false;
    systemd.services."serial-getty@hvc0".enable = false;

    # Only set these settings when the options exist. Some tests (e.g. those
    # that do not specify any nodes, or an empty attr set as nodes) will not
    # have the QEMU module loaded and thuse these options can't and should not
    # be set.
    virtualisation = lib.optionalAttrs (options ? virtualisation.qemu) {
      qemu = {
        # Only use a serial console, no TTY.
        # NOTE: optionalAttrs
        #       test-instrumentation.nix appears to be used without qemu-vm.nix, so
        #       we avoid defining consoles if not possible.
        # TODO: refactor such that test-instrumentation can import qemu-vm
        #       or declare virtualisation.qemu.console option in a module that's always imported
        consoles = [ qemu-common.qemuSerialDevice ];
        package  = lib.mkDefault pkgs.qemu_test;
      };
    };

    boot.initrd.preDeviceCommands =
      ''
        echo 600 > /proc/sys/kernel/hung_task_timeout_secs
      '';

    boot.initrd.postDeviceCommands =
      ''
        # Using acpi_pm as a clock source causes the guest clock to
        # slow down under high host load.  This is usually a bad
        # thing, but for VM tests it should provide a bit more
        # determinism (e.g. if the VM runs at lower speed, then
        # timeouts in the VM should also be delayed).
        echo acpi_pm > /sys/devices/system/clocksource/clocksource0/current_clocksource
      '';

    boot.postBootCommands =
      ''
        # Panic on out-of-memory conditions rather than letting the
        # OOM killer randomly get rid of processes, since this leads
        # to failures that are hard to diagnose.
        echo 2 > /proc/sys/vm/panic_on_oom
      '';

    # Panic if an error occurs in stage 1 (rather than waiting for
    # user intervention).
    boot.kernelParams =
      [ "console=${qemu-common.qemuSerialDevice}" "panic=1" "boot.panic_on_fail" ];

    # `xwininfo' is used by the test driver to query open windows.
    environment.systemPackages = [ pkgs.xorg.xwininfo ];

    # Log everything to the serial console.
    services.journald.extraConfig =
      ''
        ForwardToConsole=yes
        MaxLevelConsole=debug
      '';

    systemd.extraConfig = ''
      # Don't clobber the console with duplicate systemd messages.
      ShowStatus=no
      # Allow very slow start
      DefaultTimeoutStartSec=300
    '';
    systemd.user.extraConfig = ''
      # Allow very slow start
      DefaultTimeoutStartSec=300
    '';

    boot.consoleLogLevel = 7;

    system.requiredKernelConfig = with config.lib.kernelConfig; [
      (isYes "SERIAL_8250_CONSOLE")
      (isYes "SERIAL_8250")
      (isEnabled "VIRTIO_CONSOLE")
    ];

    networking.usePredictableInterfaceNames = false;

    # Make it easy to log in as root when running the test interactively.
    users.users.root.initialHashedPassword = mkOverride 150 "";

    services.xserver.displayManager.job.logToJournal = true;

    # Make sure we use the Guest Agent from the QEMU package for testing
    # to reduce the closure size required for the tests.
    services.qemuGuest.package = pkgs.qemu_test.ga;
  };

}