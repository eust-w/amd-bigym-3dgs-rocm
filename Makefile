SHELL := /usr/bin/env bash

.PHONY: preflight install-bigym build-gsplat smoke-gsplat stage-shell collect validate clean verify

preflight:
	./scripts/preflight_rocm.sh

install-bigym:
	./scripts/install_bigym_overlay.sh

build-gsplat:
	./scripts/build_gsplat_rocm.sh

smoke-gsplat:
	"$${VENV:?set VENV}/bin/python" scripts/smoke_test_gsplat.py

stage-shell:
	./scripts/stage_visual_shell.sh

collect:
	./scripts/run_cutlery32.sh

validate:
	"$${VENV:?set VENV}/bin/python" scripts/validate_lerobot_v3_collection.py \
		"$${DATASET_ROOT:?set DATASET_ROOT}" --workers "$${VALIDATION_WORKERS:-4}"

clean:
	@echo "Run scripts/clean_gaussian_ply.py once per PLY; see docs/04-validation-and-cleaning.md"

verify:
	./scripts/verify_public_repo.sh
