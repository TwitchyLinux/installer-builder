# WIP:
#  To create installer image: UNSAFE_TESTING=backdoor ./make-installer.sh
#  To run tests: $(nix-build --argstr installer /tmp/twl-installer.img ./)/bin/test
#
# Todo: Once nixos has a stable release with the new test-driver path, use the system nixpkgs.

{
	installer,
	nixos_src ? (fetchTarball https://github.com/NixOS/nixpkgs/archive/refs/heads/master.tar.gz),
	nixos ? import (fetchTarball https://github.com/NixOS/nixpkgs/archive/refs/heads/master.tar.gz) { }
}:
let
    pkgs = nixos.pkgs;
    config = nixos.config;
    lib = pkgs.lib;

	test-driver = pkgs.callPackage "${nixos_src}/nixos/lib/test-driver/default.nix" { };

	test-script-src = 
''
start_all()
machine.wait_for_unit('multi-user.target')

machine.execute("echo '{' > /install.config")
machine.execute("echo '  \"username\": \"xxx\",' >> /install.config")
machine.execute("echo '  \"hostname\": \"xxx\",' >> /install.config")
machine.execute("echo '  \"password\": \"xxx\",' >> /install.config")
machine.execute("echo '  \"timezone\": \"America/Los_Angeles\",' >> /install.config")
machine.execute("echo '  \"autologin\": true,' >> /install.config")
machine.execute("echo '  \"install_disk\": \"/dev/sda\"' >> /install.config")
machine.execute("echo '}' >> /install.config")

machine.succeed("systemd-cat -t installer twlinst --config /install.config < /dev/null >&2")

'';

	test-script = pkgs.writeText "test-script" test-script-src;
		

	start-script = pkgs.writeScript "run-test-vm" ''
		#! ${pkgs.runtimeShell}
		exec ${pkgs.qemu}/bin/qemu-system-x86_64 \
			-bios ${pkgs.OVMF.fd}/FV/OVMF.fd -enable-kvm -cpu host -smp 4 -m 4G \
			-nographic -usb -device qemu-xhci,id=xhci \
			-drive id=installer,format=raw,file=/tmp/twl-installer.img,if=none -device usb-storage,drive=installer,bus=xhci.0 \
			-drive id=disk,file=/tmp/qemu_hdd.img,if=none -device ahci,id=ahci -device ide-hd,drive=disk,bus=ahci.0 \
          	"$@"
    '';
in
	pkgs.writeShellScriptBin "test" ''
        exec ${test-driver}/bin/nixos-test-driver \
	        ${test-script} \
             --vlans "" \
             --start-scripts '${start-script}' \
             # --interactive
      ''