---
title: "Renaming Proxmox Cluster Nodes: The SSH Gotcha That Breaks Migrations"
date: 2026-02-03
draft: false
---
I renamed all three nodes in a Proxmox cluster recently. The hostname changes went fine. Corosync updated without drama. HA picked up the new names. Then I put a node in maintenance mode and watched every migration fail.

```
Host key verification failed.
ERROR: migration aborted: Can't connect to destination address using public key
```

The fix took longer to find than the actual rename.

## Why Rename Nodes?

The nodes had legacy names from initial setup — the kind of thing that made sense at the time but doesn't scale. A proper naming convention helps with inventory management, scripting, and not having to explain cryptic hostnames to every new team member.

## The Standard Rename Process

The [Proxmox wiki](https://pve.proxmox.com/wiki/Renaming_a_PVE_node) covers the basics:

1. Put the node in maintenance mode so HA migrates workloads off
2. Change the hostname (`hostnamectl set-hostname`)
3. Update `/etc/hosts`
4. Reboot
5. Copy config from old node directory to new one in `/etc/pve/nodes/`
6. Update `corosync.conf` with the new name and increment the config version
7. Restart corosync
8. Disable maintenance mode

This all worked. The cluster reformed with the new node name. HA saw it. Everything looked healthy.

Then HA tried to migrate VMs back, and every single one failed.

## The Symptom

```
task started by HA resource agent
# /usr/bin/ssh -e none -o 'BatchMode=yes' -o 'HostKeyAlias=node-02' \
  -o 'UserKnownHostsFile=/etc/pve/nodes/node-02/ssh_known_hosts' \
  -o 'GlobalKnownHostsFile=none' root@192.168.1.12 /bin/true
Host key verification failed.
ERROR: migration aborted: Can't connect to destination address using public key
```

The key detail is in that SSH command. Proxmox migrations don't use the system-wide `~/.ssh/known_hosts`. They use a per-node file at `/etc/pve/nodes/<node>/ssh_known_hosts`.

## The Non-Obvious Part

The known_hosts file used is based on the **target node**, not the source. If you're migrating a VM from node-01 to node-02, Proxmox checks `/etc/pve/nodes/node-02/ssh_known_hosts`.

When you rename a node, a new directory gets created under `/etc/pve/nodes/` with fresh, empty files. The SSH keys for your other nodes aren't there. Migrations fail.

## The Fix

Get the SSH host keys for each node and add them to **all** the node known_hosts files:

```bash
# Get keys (run from a node that can reach the target)
ssh root@192.168.1.12 "ssh-keyscan -t ed25519 192.168.1.13" 2>/dev/null
# 192.168.1.13 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...
```

Add them with both hostname and IP:

```bash
echo "node-03,192.168.1.13 ssh-ed25519 AAAAC3..." >> /etc/pve/nodes/node-01/ssh_known_hosts
echo "node-03,192.168.1.13 ssh-ed25519 AAAAC3..." >> /etc/pve/nodes/node-02/ssh_known_hosts
echo "node-03,192.168.1.13 ssh-ed25519 AAAAC3..." >> /etc/pve/nodes/node-03/ssh_known_hosts
```

Repeat for all nodes. Yes, it's tedious. Yes, you need to add each node's key to every node's known_hosts file, including its own.

## Additional Gotcha: ssh-keyscan Failures

While debugging, I kept getting this:

```
192.168.1.12: Connection closed by remote host
```

Running `ssh-keyscan` rapidly, or from a node that's in the middle of HA state changes, can hit connection limits or timing issues. The workaround is to run it from a different node, or just manually copy the key from a successful `ssh -v` connection.

## Bonus: Stale HA Manager Entries

After renaming, `ha-manager status` kept showing the old node names with "unable to read lrm status". The HA manager persists node state in `/etc/pve/ha/manager_status`. You can clean it up, but only from whichever node is currently the CRM master:

```bash
# Check which node is master
ha-manager status | grep master

# On the master node, clean stale entries
cat /etc/pve/ha/manager_status | python3 -c "
import sys, json
data = json.load(sys.stdin)
data['node_request'].pop('old-node-name', None)
data['node_status'].pop('old-node-name', None)
print(json.dumps(data))
" > /tmp/manager_status_new && cp /tmp/manager_status_new /etc/pve/ha/manager_status
```

The master changes when you restart CRM services, so you might need to re-run this a few times on different nodes until it sticks.

## Don't Forget Your HA Rules

If you have HA affinity rules referencing node names, those need updating too:

```bash
sed -i 's/old-node-name/new-node-name/g' /etc/pve/ha/rules.cfg
```

Otherwise your workloads won't migrate back to their preferred nodes.

## Summary

Renaming Proxmox nodes is straightforward until HA tries to migrate VMs. The wiki doesn't emphasize that you need to populate the new SSH known_hosts files manually. The error message points you at SSH, but not at which known_hosts file matters.

Now you know.
