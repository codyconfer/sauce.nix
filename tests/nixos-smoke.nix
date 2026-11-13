{ pkgs, sauceModule }:
pkgs.testers.runNixOSTest {
  name = "sauce-ssh-devbox-and-backup";
  node.pkgsReadOnly = false;
  nodes.machine = { lib, ... }: {
    imports = [
      sauceModule
      ../profiles/headless
      ../profiles/headless/devbox.nix
      ../profiles/headless/ssh.nix
    ];
    system.stateVersion = "25.11";
    sauce.system = {
      user = "tester";
      tailscale = false;
      devbox.lmstudio.enable = true;
      fwupd = false;
      clamav.enable = false;
      backup = {
        enable = true;
        repository = "/var/lib/sauce-test-restic";
        paths = [ "/home/tester/backup-fixture" ];
      };
    };
    services.restic.backups.sauce.timerConfig = lib.mkForce null;
    environment.systemPackages = [
      pkgs.curl
      pkgs.iproute2
      pkgs.netcat-openbsd
    ];
    virtualisation.memorySize = 2048;
    # Simulate an enrolled tailnet interface using a network namespace. The real
    # address-resolution script, Caddy, firewall, SSH and code-server still run.
    systemd.services.sauce-caddy-tailscale-address = {
      requires = lib.mkForce [ ];
      after = lib.mkForce [ ];
      wantedBy = lib.mkForce [ ];
      path = lib.mkForce [
        pkgs.coreutils
        (pkgs.writeShellScriptBin "tailscale" ''
          printf '%s\n' '100.64.0.1'
        '')
      ];
    };
    # Stand in for the user-started LM Studio server, bound only to loopback.
    systemd.services.lmstudio-fixture = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig.ExecStart = "${pkgs.python3}/bin/python -m http.server 1234 --bind 127.0.0.1 --directory ${pkgs.writeTextDir "v1/models" ''{"object":"list","data":[]}''}";
    };
    systemd.services.caddy.wantedBy = lib.mkForce [ ];
    systemd.services.code-server.wantedBy = lib.mkForce [ ];
  };
  testScript = ''
    start_all()
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("firewalld.service")
    machine.wait_for_unit("sshd.service")

    with subtest("Runtime credentials are mandatory"):
        machine.fail("systemctl start code-server.service")
        machine.succeed("install -d -m 0700 /run/secrets; install -d -m 0755 /etc/ssh/sauce-authorized-keys")
        machine.succeed("touch /run/secrets/sauce-code-server.env; chmod 0600 /run/secrets/sauce-code-server.env")
        machine.succeed("systemctl reset-failed code-server.service")
        machine.fail("systemctl start code-server.service")
        machine.succeed("printf 'PASSWORD=test-password\\n' > /run/secrets/sauce-code-server.env")
        machine.succeed("systemctl reset-failed code-server.service; systemctl start code-server.service")
        machine.wait_for_open_port(8080)

    with subtest("Only the simulated tailnet can reach SSH and devbox services"):
        for namespace, interface, host, peer in [
            ("tailnet", "tailscale0", "100.64.0.1", "100.64.0.2"),
            ("untrusted", "lan0", "192.0.2.1", "192.0.2.2"),
        ]:
            machine.succeed(f"ip netns add {namespace}")
            machine.succeed(f"ip link add {interface} type veth peer name peer netns {namespace}")
            machine.succeed(f"ip addr add {host}/24 dev {interface}; ip link set {interface} up")
            machine.succeed(f"ip -n {namespace} addr add {peer}/24 dev peer; ip -n {namespace} link set peer up; ip -n {namespace} link set lo up")
        machine.succeed("firewall-cmd --reload; systemctl start caddy.service")
        machine.wait_for_open_port(80, addr="100.64.0.1")
        machine.wait_for_open_port(1234, addr="100.64.0.1")
        for port in [22, 80, 1234]:
            machine.succeed(f"ip netns exec tailnet nc -z -w 3 100.64.0.1 {port}")
            machine.fail(f"ip netns exec untrusted nc -z -w 3 192.0.2.1 {port}")
        machine.fail("ip netns exec tailnet nc -z -w 3 100.64.0.1 8080")

    with subtest("LM Studio API is proxied only through the tailnet"):
        machine.succeed("ip netns exec tailnet curl -fsS http://100.64.0.1:1234/v1/models | grep -q '\"object\":\"list\"'")
        machine.fail("ip netns exec untrusted nc -z -w 3 100.64.0.1 1234")

    with subtest("Browser access requires authentication"):
        machine.succeed("ip netns exec tailnet curl -s -o /dev/null -w '%{http_code}' http://100.64.0.1/ | grep -qx 302")
        machine.succeed("ip netns exec tailnet curl -fsS -c /tmp/code-cookies -d password=test-password http://100.64.0.1/login > /dev/null")
        machine.succeed("ip netns exec tailnet curl -s -b /tmp/code-cookies -o /dev/null -w '%{http_code}' http://100.64.0.1/ | grep -qx 200")

    with subtest("SSH uses runtime authorized keys"):
        machine.succeed("ssh-keygen -q -t ed25519 -N \"\" -f /tmp/test-key; cp /tmp/test-key.pub /etc/ssh/sauce-authorized-keys/tester; chmod 0644 /etc/ssh/sauce-authorized-keys/tester")
        machine.succeed("ip netns exec tailnet ssh -n -F /dev/null -i /tmp/test-key -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o BatchMode=yes -o StrictHostKeyChecking=no tester@100.64.0.1 true")
        effective_sshd = machine.succeed("sshd -T -f /etc/ssh/sshd_config").lower().splitlines()
        assert "passwordauthentication no" in effective_sshd, effective_sshd
        assert "kbdinteractiveauthentication no" in effective_sshd, effective_sshd

    with subtest("Encrypted backup, repository check, and restore"):
        machine.succeed("printf 'test-only-restic-password\\n' > /run/secrets/sauce-restic-password; chmod 0600 /run/secrets/sauce-restic-password")
        machine.succeed("install -d /home/tester/backup-fixture; printf 'restore-me\\n' > /home/tester/backup-fixture/important.txt")
        machine.succeed("systemctl start restic-backups-sauce.service", timeout=120)
        machine.succeed("restic-sauce check --read-data", timeout=120)
        machine.succeed("rm /home/tester/backup-fixture/important.txt; restic-sauce restore latest --target /tmp/sauce-restore", timeout=120)
        machine.succeed("grep -qx restore-me /tmp/sauce-restore/home/tester/backup-fixture/important.txt")
  '';
}
