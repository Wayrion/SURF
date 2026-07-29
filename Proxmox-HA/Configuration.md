# Sources:

omping: [https://www.ibm.com/docs/en/wip-mg/2.0.0?topic=membership-using-omping-test-multicast-connectivity](https://www.ibm.com/docs/en/wip-mg/2.0.0?topic=membership-using-omping-test-multicast-connectivity)

# Pre-requisites

## Testing for connectivity and latency.

### Standard Ping

We can do an initial sanity check by using ping to ensure that latency is below 5ms (recommended maximum latency as per Proxmox HA documentation):
`ping -c 100 -s 1024 IP_ADDR`

> [!NOTE]
> While ping does measure latency in some capacity, it may not be fully reflective of how much latency a node-to-node connection may have, especially for different types of traffic, and under different levels of load.

### Open Multicast ping (omping)

While the omping tool is 5 years old and deprecated, we can still use it to gauge some level of performance.

To install omping please look [here](https://github.com/troglobit/omping#installation)

If you are not on a RHEL/Oracle/Rocky Distribution, and can't build your own binary, you can use the pre-built omping binary [here](https://github.com/Wayrion/omping). It is built for x86 Debian.

#### Usage

```bash
# Taken from the IBM Documentation linked at the top.
# On Server A.
omping -m <multicast or broadcast address> -p <cluster multicast discovery port> <IP of local cluster control interface> <cluster control IP address of Server B>

# On Server B
omping -m <multicast or broadcast address> -p <cluster multicast discovery port> <IP of local cluster control interface> <cluster control IP address of Server A>

```

```bash
# In my case the commands look like this
# 239.1.1.1 is just an arbitrary IP for the multicast packets
# Server A (pve)
./omping -m 239.1.1.1 -p 9106 192.168.178.201 192.168.178.202
# Server B (pve2)
./omping -m 239.1.1.1 -p 9106 192.168.178.202 192.168.178.201

```

---

# Installation

> [!IMPORTANT]
> **ORDER OF OPERATIONS MATTERS!**
> Do **NOT** install Ceph before creating and joining the Proxmox Cluster. Installing Ceph on independent standalone nodes prior to joining them causes node IDs and IP configurations to mismatch, which leads to orphaned ghost monitors stuck in a stopped state. Always establish your Proxmox cluster first!

## Step 1: Create the Cluster and Join All Nodes First

1. Go to Node 1 (`nfv1`) -> **Datacenter** -> **Cluster** -> **Create Cluster**.
2. Set a name (in our case `eduVPN-lab`) and select the cluster networking interface. Close the modal once it says `TASK OK`.
3. On the same page, click on **Join Information** and copy/save the encoded token so other nodes can join our cluster.
4. Go to Node 2 (`nfv2`) -> **Datacenter** -> **Cluster** -> **Join Cluster** -> paste the join information into the box and enter the root password for Node 1.
5. At this point, the network may reset and you may get a temporary connection error. Close the task window and hard-refresh the page. If all goes well, you should be able to see Node 2 in the sidebar.

6. Repeat the join process on Node 3 (`monster`).


## Step 2: Install Ceph on All Joined Nodes

1. Now that the cluster is fully established, go to Node 1 (`nfv1`) -> **Ceph** -> **Install Ceph**.
2. Start the installation wizard (e.g. Tentacle / Ceph 20 or Reef), choose **No-Subscription** if you don't have an enterprise subscription, and press `y` when prompted in the shell terminal.
3. Configure your network here. Select the Public Network IP/CIDR option from the dropdown and set cluster communication to use the same network.
4. Once Node 1 finishes, repeat the Ceph installation step on Node 2 (`nfv2`) and Node 3 (`monster`). Because Node 1 is already configured inside the cluster, the other nodes will automatically grab the network parameters from Node 1!

## Step 3: Disk Preparation and OSD Creation

Check your available disk drives on each node. Here is our disk layout:

```bash
# Node 1:
root@nfv1:~# lsblk

NAME               MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                  8:0    0 447.1G  0 disk 
├─sda1               8:1    0  1007K  0 part 
├─sda2               8:2    0     1G  0 part /boot/efi
└─sda3               8:3    0 446.1G  0 part 
  ├─pve-swap       252:0    0     8G  0 lvm  [SWAP]
  ├─pve-root       252:2    0    96G  0 lvm  /
  ├─pve-data_tmeta 252:3    0   3.3G  0 lvm  
  │ └─pve-data     252:5    0 319.6G  0 lvm  
  └─pve-data_tdata 252:4    0 319.6G  0 lvm  
    └─pve-data     252:5    0 319.6G  0 lvm  
sdb                  8:16   0 447.1G  0 disk 
├─sdb1               8:17   0   512M  0 part 
└─sdb2               8:18   0 445.6G  0 part 
  └─vgroot-lvroot  252:1    0 445.6G  0 lvm  
sdc                  8:32   0 447.1G  0 disk 
├─sdc1               8:33   0  1007K  0 part 
├─sdc2               8:34   0     1G  0 part 
└─sdc3               8:35   0 446.1G  0 part 
sdd                  8:48   0 447.1G  0 disk 
├─sdd1               8:49   0  1007K  0 part 
├─sdd2               8:50   0     1G  0 part 
└─sdd3               8:51   0 446.1G  0 part 
sde                  8:64   0 447.1G  0 disk 
├─sde1               8:65   0  1007K  0 part 
├─sde2               8:66   0     1G  0 part 
└─sde3               8:67   0 446.1G  0 part 
sdf                  8:80   0 447.1G  0 disk 


# Node 2:
root@nfv2:~# lsblk

NAME               MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
sda                  8:0    0 447.1G  0 disk 
├─sda1               8:1    0  1007K  0 part 
├─sda2               8:2    0     1G  0 part /boot/efi
└─sda3               8:3    0 446.1G  0 part 
  ├─pve-swap       252:0    0     8G  0 lvm  [SWAP]
  ├─pve-root       252:1    0    96G  0 lvm  /
  ├─pve-data_tmeta 252:2    0   3.3G  0 lvm  
  │ └─pve-data     252:4    0 319.6G  0 lvm  
  └─pve-data_tdata 252:3    0 319.6G  0 lvm  
    └─pve-data     252:4    0 319.6G  0 lvm  
sdb                  8:16   0 447.1G  0 disk 
sdc                  8:32   0 447.1G  0 disk 
sdd                  8:48   0 447.1G  0 disk 
sde                  8:64   0 447.1G  0 disk 
sdf                  8:80   0 447.1G  0 disk 


# Node 3:
root@monster:~# lsblk

NAME               MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                  8:0    0  2.2T  0 disk 
├─sda1               8:1    0 1007K  0 part 
├─sda2               8:2    0    1G  0 part /boot/efi
└─sda3               8:3    0  2.2T  0 part 
  ├─pve-swap       252:0    0    8G  0 lvm  [SWAP]
  ├─pve-root       252:1    0   96G  0 lvm  /
  ├─pve-data_tmeta 252:2    0 15.9G  0 lvm  
  │ └─pve-data     252:4    0    2T  0 lvm  
  └─pve-data_tdata 252:3    0    2T  0 lvm  
    └─pve-data     252:4    0    2T  0 lvm  
sdb                  8:16   0  1.7T  0 disk 
└─sdb1               8:17   0  1.7T  0 part 
sdc                  8:32   0  1.7T  0 disk 
└─sdc1               8:33   0  1.7T  0 part 
sdd                  8:48   1 14.3G  0 disk 
└─sdd1               8:49   1 14.3G  0 part 
sde                  8:64   0  512M  1 disk 
└─sde1               8:65   0  251M  1 part  

```

We are going to be using `sdb` through `sdf` on Node 1 (`nfv1`) and Node 2 (`nfv2`), and `sdb` and `sdc` on Node 3 (`monster`). You can mix and match drive models with Ceph as long as they are decent SSDs. Since we use 3 replicas, our total usable storage capacity will be approximately 33%.

Wipe all partition tables and filesystem signatures from the intended disks:

```bash
# Run on Node 1 (nfv1) and Node 2 (nfv2):
wipefs -a -f /dev/sd{b,c,d,e,f}
sgdisk --zap-all /dev/sdb
sgdisk --zap-all /dev/sdc
sgdisk --zap-all /dev/sdd
sgdisk --zap-all /dev/sde
sgdisk --zap-all /dev/sdf

# Run on Node 3 (monster):
wipefs -a -f /dev/sd{b,c}
sgdisk --zap-all /dev/sdb
sgdisk --zap-all /dev/sdc

```

Now create 1 OSD per disk (standard recommended approach unless your drives exceed 30TB):

```bash
# Run on Node 1 (nfv1) and Node 2 (nfv2):
for dev in b c d e f; do pveceph osd create /dev/sd$dev; done

# Run on Node 3 (monster):
for dev in b c; do pveceph osd create /dev/sd$dev; done

```

## Step 4: Setup Monitors and Managers

1. Go to Node 1 -> **Ceph** -> **Monitor** to confirm monitor `mon.nfv1` is active.
2. Go to Node 2 -> **Ceph** -> **Monitor** -> click **Create** to add a monitor on `nfv2`.
3. Go to Node 3 -> **Ceph** -> **Monitor** -> click **Create** to add a monitor on `monster`.
4. Ensure you also create Ceph Managers (`mgr`) on all 3 nodes. All 3 monitors should report in Quorum.

## Step 5: Shared Storage Pool Creation

1. Go to **Node** -> **Ceph** -> **Pools** -> **Create**.
2. Name the pool. For this guide, I'll be using `ceph-pool`.
3. Set **Size** to `3` and **Min. Size** to `2`. Leave defaults for PG count or tweak based on your disk count, then click **Create**.
4. Once created, Proxmox will automatically expose `ceph-pool` as shared storage under **Datacenter** -> **Storage**. Any Virtual Machine (VM) disk stored on `ceph-pool` is now accessible from all cluster nodes simultaneously!

## Step 6: Configure High Availability (HA) Groups and Policies

1. Go to **Datacenter** -> **HA** -> **Groups** -> **Create**.
2. Name the group `prox-group`, select all 3 nodes, and configure node behaviors:
* **Priority**: Higher priority numbers tell Proxmox which node to prefer when running the VM.
* **Restricted**: If checked, limits the VM to ONLY run on nodes in this group. Useful if specific hosts have specialized hardware (e.g., PCIe passthrough GPUs).
* **No Fallback**: If checked, prevents the VM from automatically migrating back to its preferred host when that host recovers from a crash.


3. Add your VM to HA management:
* Go to **Datacenter** -> **HA** -> **Resources** -> **Add**.
* Select your VM ID, assign it to `prox-group`, and set **Max Restart** / **Max Relocate** count.
* Set the requested state to **started**.


4. Configure HA global failure handling under **Datacenter** -> **HA** -> **Options** -> **HA Settings**:
* **Conditional**: Default behavior. Distinguishes between manual reboots/shutdowns and actual host crashes.
* **Failover**: Instantly migrates and boots the VM on another host if the node goes down ungracefully.
* **Freeze**: Does nothing if a node fails (useful during targeted maintenance).
* **Migrate**: Always migrates VMs off a node whenever a shutdown command is issued.



---

# Troubleshooting

## Ghost monitors and status stopped for monitors and managers

If you are a chosen one like me, you might run into ghost monitors that are permanently stuck in the stopped status. Trying to start them doesn't work even though Proxmox pretends like the start task succeeded. But when you try to delete them, you get the dreaded error: `"can't delete last monitor"`.

This usually happens when Ceph was initialized prior to cluster creation. To clean up the stale service and entries manually:

```bash
# Stop, disable, and remove the monitor service on the affected host:
service ceph-mon@myhost stop
systemctl disable ceph-mon@myhost
systemctl daemon-reload

# Delete the datadir of the monitor (fine if this says no such file or directory):
rm -r /var/lib/ceph/mon/ceph-myhost

```

Now edit `/etc/ceph/ceph.conf` (or `/etc/pve/ceph.conf`) manually:

```bash
nano /etc/pve/ceph.conf

```

Remove the dead monitor's IP from `mon_host` and delete its configuration block:

```ini
# Delete IP of stale monitor:
mon_host = xx.0.99.83 xx.0.99.82 xx.0.99.84 
# Change to:
mon_host = xx.0.99.83 xx.0.99.82

# Delete the dead block:
[mon.myhost]
        public_addr = xx.0.99.84

```

If running `pveceph createmon` throws an error like:

`No active IP found for the requested ceph public network '145.220.0.115/24' on node 'monster' (500)`

Inspect your active network interface and subnets:

```bash
ip addr show

```

Open `/etc/pve/ceph.conf` and ensure the IP address and `public_network` subnet configuration under `[global]` match your active interfaces:

```ini
[global]
        auth_client_required = cephx
        auth_cluster_required = cephx
        auth_service_required = cephx
        fsid = 69cfc1ef-4199-42b2-ba21-f90305f86a2b
        mon_allow_pool_delete = true
        mon_host = 145.220.51.11 145.101.50.3
        ms_bind_ipv4 = true
        ms_bind_ipv6 = false
        osd_pool_default_min_size = 2
        osd_pool_default_size = 3
        public_network = 145.220.50.0/23, 145.220.0.0/24, 145.101.50.0/23

```

*(Note: It is safe to omit cluster_network if you are using the same network to sync OSDs).*

Save with `Ctrl + S`, then close with `Ctrl + X`. Now run:

```bash
pveceph mon create

```

If it complains because it tries to pick the wrong IP address automatically, pass the IP address explicitly:

```bash
pveceph mon create --mon-address 145.101.50.3

```

Restart the Ceph monitor and OSD services:

```bash
systemctl restart ceph-mon.target
systemctl restart ceph-osd.target

```

Finally, navigate to **Node** -> **Ceph** -> **Monitor**. You should see all monitors running with valid IP addresses. Delete any non-working managers and recreate them from the GUI.

If everything works, it should look like this:

Pray to the Ceph and Proxmox gods that it works! Check **Node** -> **Ceph** -> **Monitor** to confirm quorum is set to `Yes`.

## Ceph auth and bootstrap keyring permissions

If OSD creation fails due to keyring authorization errors:

```bash
ceph auth get-or-create client.bootstrap-osd mon 'allow profile bootstrap-osd' -o /etc/pve/priv/ceph.client.bootstrap-osd.keyring
mkdir -p /var/lib/ceph/bootstrap-osd
cp /etc/pve/priv/ceph.client.bootstrap-osd.keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
ceph-volume lvm create --data pve/ceph-osd

```

## VM does not boot after migration

If your VM fails to start after live migration with a `volume does not exist` error, verify that the storage target on all nodes uses the exact same storage ID string for the shared Ceph pool (`ceph-pool`). Refer to the Proxmox forum thread for detailed storage mapping fixes:

[https://forum.proxmox.com/threads/volume-does-not-exist-error-after-vm-migration.127034/](https://forum.proxmox.com/threads/volume-does-not-exist-error-after-vm-migration.127034/)


# Sources & Credits:
- **Primary Video Reference:** [Setting Up Proxmox High Availability Cluster & Ceph](https://youtu.be/Eli3uYzgC8A) by NovaSpiritTech (Rest in peace Donald).
- **omping Documentation:** [IBM Knowledge Center - Using omping to test multicast connectivity](https://www.ibm.com/docs/en/wip-mg/2.0.0?topic=membership-using-omping-test-multicast-connectivity)
- **Ghost Monitors Fix:** [Proxmox Forum Thread - Ghost Ceph Monitor Cleanup](https://forum.proxmox.com/threads/i-managed-to-create-a-ghost-ceph-monitor.58435/post-389798)
- **VM Migration Storage Error:** [Proxmox Forum Thread - Volume does not exist error](https://forum.proxmox.com/threads/volume-does-not-exist-error-after-vm-migration.127034/)