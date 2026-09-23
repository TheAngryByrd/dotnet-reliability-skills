.PHONY: validate validate-changelog validate-links install-dev test

validate:
	python scripts/validate-skills.py

validate-changelog:
	python .ci-scripts/changelog.py validate

test:
	pwsh -NoProfile -File scripts/verify-examples.ps1

validate-links:
	lychee --config lychee.toml .

install-dev:
	./scripts/install.sh
