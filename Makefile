.PHONY: validate validate-changelog validate-links install-dev test test-evals

validate:
	python scripts/validate-skills.py

validate-changelog:
	python .ci-scripts/changelog.py validate

test:
	pwsh -NoProfile -File scripts/verify-examples.ps1

test-evals:
	pwsh -NoProfile -File evals/tests/Metrics.Tests.ps1
	pwsh -NoProfile -File evals/tests/Rubric.Tests.ps1
	pwsh -NoProfile -File evals/tests/Grading.Tests.ps1

validate-links:
	lychee --config lychee.toml .

install-dev:
	./scripts/install.sh
