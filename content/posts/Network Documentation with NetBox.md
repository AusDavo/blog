---
title: "Network Documentation for CIS 18: A Practical Guide (With Detours)"
date: 2026-01-29T20:56:31+10:00
draft: false
tags: []
---
*How a straightforward documentation task turned into an afternoon of OIDC workarounds and learning more about NetBox's CSV parser than I ever wanted to.*

---

We have about 40 machines. A Proxmox cluster, a mix of LXCs and VMs, some VPSes across different providers, and two Tailscale networks—one legacy, one we're migrating to. It's not a huge environment, but it's complex enough that "it's all in my head" stopped being acceptable when compliance requirements entered the picture.

CIS Control 18 is about penetration testing, but you can't scope a pentest if you don't know what you have. So step one: document the network properly.

## Choosing NetBox

I considered a few options:

- **Markdown in a git repo** — Simple, version-controlled, but no structure. You end up with a folder of files and no easy way to answer "which machines are on VLAN 21?"
- **A wiki** — Good for prose, bad for structured data.
- **NetBox** — Purpose-built for this. IPAM, device inventory, an API. Felt like overkill for 40 machines, but it's actually the sweet spot.

NetBox won. It's FOSS, self-hosted, and designed to be the source of truth for network infrastructure.

## The Setup (In Theory)

The netbox-docker project makes deployment straightforward. Clone the repo, run `docker compose up`, done. I use Portainer, so it's even simpler—paste a compose file, add environment variables, deploy.

I wanted OIDC authentication (we use a self-hosted identity provider) and SMTP for notifications. The environment variables seemed clear enough:

```
REMOTE_AUTH_ENABLED=true
REMOTE_AUTH_BACKEND=social_core.backends.open_id_connect.OpenIdConnectAuth
SOCIAL_AUTH_OIDC_OIDC_ENDPOINT=https://auth.example.com
SOCIAL_AUTH_OIDC_KEY=my-client-id
SOCIAL_AUTH_OIDC_SECRET=my-client-secret
```

Deploy. Click "Login with OIDC." Error:

```
TypeError: unsupported operand type(s) for +: 'NoneType' and 'str'
```

## Detour #1: NetBox Doesn't Read Your Environment Variables

After some digging, I discovered that the NetBox Docker image only maps *specific* environment variables to Django settings. The `SOCIAL_AUTH_*` variables? They're passed to the container, but Django never sees them.

The fix is to mount a Python config file:

```python
# /opt/netbox-config/oidc.py
SOCIAL_AUTH_OIDC_OIDC_ENDPOINT = "https://auth.example.com"
SOCIAL_AUTH_OIDC_KEY = "my-client-id"
SOCIAL_AUTH_OIDC_SECRET = "my-client-secret"
```

Mount it to `/etc/netbox/config/oidc.py` and NetBox loads it automatically. Not documented prominently, and frankly annoying—every other self-hosted app I've deployed recently just reads env vars. But it works.

## Actually Setting Up NetBox

With OIDC working, I could finally use NetBox. The data model is:

1. **Sites** — Physical or logical locations
2. **Device Roles** — Hypervisor, Application Server, Router, etc.
3. **Clusters** — For virtualization (my Proxmox cluster)
4. **Virtual Machines** — The actual VMs and containers
5. **IP Addresses** — Assigned to interfaces on devices/VMs
6. **Prefixes** — Network ranges (VLANs, subnets)
7. **Tags** — Flexible labeling

NetBox supports CSV import, which seemed like the fastest way to bulk-load 40 machines. I exported my Tailscale device lists and Proxmox VM inventories, massaged them into CSVs, and started importing.

## Detour #2: The CSV Gauntlet

NetBox's CSV import is picky. I hit errors on almost every file:

**Clusters:**
```
Record 1 status: This field is required.
```
Fine, add a `status` column.

**Virtual Machines:**
```
Record 2 role: Object not found: Router
```
Roles need to be referenced by slug, not name. No wait, by name. Actually, it depends on the field—check the import page for the "Accessor" column.

**Virtual Machines (again):**
```
Record 1 role: Object not found: Automation
```
The role exists, but "VM Role" isn't checked on it. Device Roles have a checkbox that determines whether they can be assigned to VMs. If it's unchecked, the role is invisible to VM imports.

**Tags:**
```
Record 1 weight: This field is required.
```
Tags need a weight field now, apparently.

Each fix required re-downloading, editing, and re-uploading the CSV. By the fifth round-trip, I was wishing I'd just used the API from the start.

## The Network Discovery Problem

With VMs imported, I needed to assign IP addresses. NetBox had my Tailscale IPs from the export, but not the LAN IPs—those are assigned by DHCP on our internal network.

I briefly considered SSHing into each VM to run `ip a`. Then I remembered: Proxmox knows the network config for every VM and container.

For LXCs with static IPs, Proxmox stores it directly:

```bash
pvesh get /nodes/mynode/lxc/111/config | grep -E 'net[0-9]'
```

Output:
```
net0 | name=eth0,bridge=vmbr3,gw=10.x.x.1,ip=10.x.x.126/24,type=veth
```

For DHCP clients, I pulled the lease table from our OPNsense router. Between Proxmox configs and DHCP leases, I had complete LAN IP data without touching a single guest.

## Automating the Rest

Forty machines, each needing:
- An interface created
- LAN IP assigned
- Tailscale IP assigned
- Tags applied (which tailnet it's on)

Clicking through the UI would take hours. The NetBox API exists for exactly this reason.

```python
def create_interface(vm_id, name):
    return api_post("/virtualization/interfaces/", {
        "virtual_machine": vm_id,
        "name": name,
        "enabled": True,
    })

def assign_ip_to_interface(ip_id, interface_id):
    return api_patch(f"/ipam/ip-addresses/{ip_id}/", {
        "assigned_object_type": "virtualization.vminterface",
        "assigned_object_id": interface_id,
    })
```

A ~200 line Python script later, I could assign all IPs and tags in under a minute.

## What I Learned

**NetBox is worth it, even for small environments.** The setup friction is real, but having a proper source of truth for "what do we have and where is it" is invaluable—for compliance, for onboarding, for 3am debugging.

**The Docker image's env var handling is frustrating.** If you need anything beyond the basics, plan to mount config files. The documentation could be clearer about this.

**CSV import is fine for bootstrapping, but use the API for ongoing maintenance.** The import format quirks (slug vs name, required fields that aren't obviously required) make iteration painful.

**Proxmox and your DHCP server know more than you think.** Before SSHing into every machine, check what metadata you already have centrally.

## Current State

NetBox now has:
- All 40-ish machines documented
- LAN and Tailscale IPs assigned
- Tags tracking which tailnet each machine is on
- Device roles distinguishing hypervisors, app servers, security tools, etc.

Next up: generating a network topology diagram and setting up automated sync so NetBox stays current as infrastructure changes.

The whole exercise took an afternoon—longer than expected, but most of that was detours. The core NetBox setup is maybe an hour if you know the gotchas in advance. Hopefully this post saves you some of that time.

---

*My views are my own and do not necessarily reflect the views of my employer.*

*Have questions or want to share your own NetBox war stories? Find me on [Nostr](https://njump.me/npub1jz0rlhp9ngs3at2kfhzcnc62sxh0y9rxt40x3z003wmdguljky9quaaju6).*
