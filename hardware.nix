{
	pkgs,
	nixos-hardware,
}:
let
	names = builtins.toJSON (builtins.attrNames ((import "${nixos-hardware}/flake.nix").outputs {self = {};}).nixosModules);
in
pkgs.runCommand "gen-hw-entries" {envVariable = true;} ''
		echo "{" > $out
		echo -n "  \"_comment\": \"nixos-hardware profiles\"" >> $out

		echo '${names}' | ${pkgs.jq}/bin/jq -r '.[]' |
			while IFS=' ' read -r entry; do
				epath=$(${pkgs.gnugrep}/bin/grep -F "$entry" ${nixos-hardware}/flake.nix | head -n1 | cut -d'=' -f2 | cut -d'.' -f2 | cut -d';' -f1 | awk '{print substr($1,2); }')
				echo "," >> $out
				echo -n "  \"$entry\": \"$epath\"" >> $out
			done

		echo -e "\n}" >> $out
		''