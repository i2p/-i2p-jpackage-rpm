# COPR SCM build integration
# Usage: make srpm outdir=/path/to/output VERSION=2.7.0

VERSION ?= 2.7.0

srpm:
	./scripts/fetch-source.sh $(VERSION) SOURCES/
	mkdir -p rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
	cp SOURCES/* rpmbuild/SOURCES/
	cp SPEC/i2p.spec rpmbuild/SPECS/
	sed -i 's/^Version:.*/Version:        $(VERSION)/' rpmbuild/SPECS/i2p.spec
	rpmbuild -bs \
		--define "_topdir $(shell pwd)/rpmbuild" \
		rpmbuild/SPECS/i2p.spec
	cp rpmbuild/SRPMS/*.src.rpm $(outdir)
