# I2P RPM Packaging

RPM packaging for [I2P](https://geti2p.net/), the Invisible Internet Project anonymous network router.

Produces installable `.rpm` packages for Fedora and RHEL/CentOS/Rocky/Alma Linux.

## Quick Start

### Using the build container (recommended)

```bash
podman build -t i2p-rpm-builder -f docker/Dockerfile.build .
podman run --rm -v ./output:/output i2p-rpm-builder /build/scripts/build-rpm.sh 2.7.0
```

### Building locally on Fedora

```bash
# Install build dependencies
sudo dnf install rpm-build rpmdevtools java-17-openjdk-devel ant gettext systemd-rpm-macros

# Build
./scripts/build-rpm.sh 2.7.0
```

The built RPMs will be in `./output/`.

## Installing

```bash
sudo dnf install ./output/i2p-2.7.0-1.fc41.x86_64.rpm
```

## Post-Install

```bash
# Start I2P
sudo systemctl start i2p

# Enable at boot
sudo systemctl enable i2p

# Check status
sudo systemctl status i2p

# Router console (available after startup)
# http://127.0.0.1:7657
```

## Configuration

- `/etc/sysconfig/i2p` — Java options (heap size, JAVA_HOME override)
- `/var/lib/i2p/` — Router state, keys, and runtime configuration
- `/var/log/i2p/` — Log files

## Project Structure

```
SPEC/i2p.spec            # RPM spec file
SOURCES/                  # Systemd units, configs, wrapper script
scripts/                  # Build and test scripts
docker/                   # Build container Dockerfile
.github/workflows/       # CI pipelines
.copr/                   # COPR build integration (Phase 2)
```

## Target Distributions

- Fedora 41+
- RHEL/CentOS/Rocky/Alma 9+ (with EPEL)

## License

I2P is a multi-licensed project. See the spec file for the full SPDX license expression.
The packaging files in this repository are licensed under Apache-2.0.
