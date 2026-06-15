# Grimmory Omnibus Image

An experimental and unofficial docker image that is everything you need to run Grimmory.

## Configuration

Configuration is done via environment variables.
You can use any Grimmory env vars, along with a few
others for controlling this image.

| Name | Description | Default |
| ---- | --- | --- |
| `LISTEN_PORT` | The port that the web application listens on. | 8080 |
| `MARIADB_DATABASE` | The database to create or use. | `grimmory` |
| `MARIADB_USER` | The user to connect to the database with.  | `grimmory` |
| `MARIADB_PASSWORD` | The password to connect to the database with. | `grimmory` |
| `MARIADB_CLI_OPTS` | Extra MariaDB CLI options to pass to the database. | |

## Installation

### Proxmox

Running the Grimmory omnibus image on Proxmox uses the Proxmox OCI
features to convert the image to a Container Template.

Requires [Proxmox](https://proxmox.com) v9.1+

#### Import the OCI Image

Under the "Storage" UI, find the "CT Templates" section.  Then, click
the "Pull from OCI Registry" button to get the "OCI Registry" modal.

> [!TIP]
> If the "Pull from OCI Registry" button is missing, check your
> Proxmox verison.

For `Reference` you should use `ghcr.io/imnotjames/grimmory-omnibus`.
Once the reference is defined, the "Query Tags" button can be used to
scan the tags available in the OCI Registry.

You should select the version of Grimmory you would like to use, such
as `v3.2.1`.

Once you have selected an image version you should be able to "Download"
and will see the template file listed after the process completes.

#### Create an LXC Container

Click the button "Create CT" to open the "Create LXC Container modal".

Set the password to a secret value and configure anything else on the
general tab as desired.  On the template page, select your Grimmory
omnibus template.

On the disks tab, the root disk may be set between 8 and 16gb.
Four mountpoint paths should be added via the "Add" button:
* `/bookdrop` - where files will be stored temporarily before finalizing.
* `/config` - various Grimmory config and cache files.
* `/books` - where books will be stored long term.
* `/database` - the MariaDB database directory.

These can be resized later.

CPU and memory can be selected, as well.  These should probably match
with the Grimmory suggested values.

Network should be set based on your current environment, but in most
cases you can set IPv4 to DHCP and it should work.

#### Starting and maintaining

The container may be started just like any other container, by selecting
it in the server view and clicking the "Start" action button.

In some cases, you may need to increase the size of your mountpoints.
This can be done by accessing the "Resources" section of the container
view, selecting the mountpoint, clicking "Volume Actions", and then
clicking "Resize".

#### Upgrading

> [!TIP]
> Make sure you back up everything first!

To upgrade, import a new OCI Image of the new Grimmory version.

A new LXC container can be created [as defined above](#create-an-lxc-container),
but the mountpoints should be omitted.  When setting up the network
configuration, if you used DHCP before you should copy the MAC address
from your old LXC container to use there.

> [!WARNING]
> Do not start the new LXC container until you move the mountpoints.

Stop your old LXC container, go to the old LXC container resources
and transfer each mountpoint volume to the new LXC container.

Select a mountpoint, click the button "Volume Action", and then click "Reassign Owner".  In the modal, you should select the newly created
LXC container.

Start the new container and confirm it's operating as expected.

Once everything is working, the old LXC container may be deleted.