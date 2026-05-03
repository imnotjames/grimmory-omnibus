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

