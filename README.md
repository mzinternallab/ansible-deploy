## Eagle-I Cluster 3 Playbooks
This repo contains ansible playbooks for managing the second iteration
of the eagle-i kubernetes cluster

The playbook is currently WIP. It's currently set up to run against the eaglei-dev0* VMs that Mike Johnston created for us. To run them against other machines, be sure to change the hosts in inventtory.yaml.

To run the RGS RKE2 installation playbooks, run the following command:
```ansible-playbook -i ansible-playbook -i inventory.yaml playbook.yaml```

### Inventory Structure
#### Groups
* bootstrap_targets - these servers will be reinstalled when the boostrap playbook is run
* uses_root_pw - ansible will use the GIST initial root password to connect to these servers as root,
instead of `doesadm`
* cluster1/cluster2 - indicates current membership, the playbooks do not use these groups, but they allow
for the operator to include/exclude a cluster with --limit. To be deleted when cluster 1 is no more.
* hwspec_1/hwspec_2 - Indicates minor hardware differences between servers. Each server MUST be in one of these.

#### Hardware Differences
Each server must be a member of either hwspec_1 or hwspec_2, this is to account for slight differences in the build,
and is required for successful templating of the kickstart file.

#### Important Variables
* desired_bios_version - the version of BIOS image that is expected
* desired_cpld_version - the version of CPLD software that is expected
* desired_idrac_version - the version of iDRAC software expected
* rke2_role - either "server" or "agent". Defaults to "server"
* rke2_version - The version of RKE2 to install (format vX.Y.Z+rkeW)

### Requirements
* git LFS
* source `ansible.env` before running any ansible commands
* network access to iDRAC
* network access to `dmzv3login01.ornl.gov`
* automatic login (via agent) to `dmzv3login01.ornl.gov`, including username selection (via ~/.ssh/config)
* network access to `does-vault.ornl.gov`
* logged in to `does-vault.ornl.gov` as a member of the DOES team
(`vault login -method ldap username=USER`, `VAULT_ADDR` must already be set, username optional if same as current user)

### Playbooks
#### Main playbook (`playbook.yaml`)
This playbook manages iDRAC and OS Settings, as well as ORNL-specific
customizations.

It also installes RKE2, but it does not configure it or manage cluster membership

Also installs `wscfengine` if not already installed. Does not manage wscfengine besides initial installation.

##### DCAMS
The DCAMS agent (dcamsd) will be configured, however, dcams does not backfill existing users. It may be necessary to
contact Mark Fletcher to request adjustments.

If a machine is reinstalled, uid0 status will be lost until the DCAMS administrator performs reconsiliation.

#### Patch playbook (`patch.yaml`)
This playbook performs OS patching, as well as management of the BIOS, CPLD and iDRAC versions.

Without any firmware updates, this takes about 30 mins. Each firmware update adds about 5-7 minutes.

##### Firmware Management
This playbook will update the BIOS, CPLD, and iDRAC based on the desired_X_version variables.  
.EXE versions of the updates should be placed in `updates/`,
named COMPONENT_VERSION.exe (e.g. BIOS_1.2.3.EXE; case sensitive)

These files should be stored with LFS.

#### Bootstrap playbook (`bootstrap.yaml`)
**WARNING**: This playbook will reinstall the OS of any server that it is run against, please be careful.

This playbook:
* Builds a boot disk for each server to be operated on
* Configures the iDRAC to present said boot disk
* Reboots the server with priority to the iDRAC virtual disk
* Waits for the installation to complete
* Joins the newly-installed server to satellite.

##### Extra Requirements:
* This playbook uses a temporary webserver, the iDRAC must be able to reach the controller on `28080`,
this port is already open on doestool01.
* The user must be able to start privileged docker containers on the controller. This is used to build the bootdisk 
image in docker

##### Tags:
* os_install - Installs the OS via a DRAC virtual drive and repoman
* post_intall - post-install tasks (satellite registration)

## Procedures
### Monthly Patching
#### Beforehand
1. Navigate to dell.com/support
2. Enter the service tag of any server
3. Navigate to Drivers & Downloads
4. Check the latest version of BIOS available.
5. If the version available is newer than the version in the `updates` folder, 
download it into the `updates` folder, name it BIOS_version.EXE (e.g. BIOS_1.2.3.EXE) this is case sensitive.
6. In `inventory.yaml` change `desired_bios_version` to the version of the bios you just downloaded.
7. Repeat 4-6 for the CPLD and iDRAC bundles.
8. Commit and push the result.
#### Event
1. Add badge to ssh-agent (e.g. `ssh-add -s /usr/lib/ssh-keychain.dylib`)
2. ssh to `doestool` with agent forwarded using jump servers as needed
(e.g. `ssh -A -J opslogin01.ornl.gov doestool01.ornl.gov`)
3. Ensure that you are able to ssh to dmzv3login01 with the forwarded agent and no username specified.
(you may need to edit .ssh/config to specify the correct username)  
Example SSH config
```text
Host dmzv3login??.ornl.gov
    User DMZ_ID_HERE
```
4. Clone or checkout the eaglei-g2 repo. (You may need to add your badge ssh key to gitlab)
5. enter the directory, and source the environment file
```shell
cd eaglei-g2
source ansible.env
```
6. Inform the jr admins that patching is starting on eagle-i
7. Start the patch playbook targeting only cluster2
```shell
ansible-playbook patch.yml --limit cluster2
```
8. Wait for completion
9. Inform the jr admins that patching has completed for eagle-i
