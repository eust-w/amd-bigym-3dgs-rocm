SHELL := /usr/bin/env bash
PYTHON ?= python3

.PHONY: preflight install-bigym build-gsplat smoke-gsplat download-reference-data reconstruct smoke-reconstruction stage-shell collect validate clean verify

preflight:
	./scripts/preflight_rocm.sh

install-bigym:
	./scripts/install_bigym_overlay.sh

build-gsplat:
	./scripts/build_gsplat_rocm.sh

smoke-gsplat:
	"$${VENV:?set VENV}/bin/python" scripts/smoke_test_gsplat.py

download-reference-data:
	./reconstruction/bin/download_reference_data.sh

reconstruct:
	./reconstruction/bin/reconstruct.sh

smoke-reconstruction:
	@set -e; \
	tmp_dir="$$(mktemp -d)"; \
	trap 'rm -rf "$$tmp_dir"' EXIT; \
	"$(PYTHON)" reconstruction/src/make_synthetic_fixture.py --output "$$tmp_dir/input"; \
	"$(PYTHON)" reconstruction/src/export_scene_shell.py \
		--input "$$tmp_dir/input/gaussians.ply" \
		--camera-path "$$tmp_dir/input/camera-path.json" \
		--alignment "$$tmp_dir/input/alignment.json" \
		--source-report "$$tmp_dir/input/source.json" \
		--output "$$tmp_dir/shell" >/dev/null; \
	"$(PYTHON)" reconstruction/src/verify_shell_export.py "$$tmp_dir/shell"
	"$(PYTHON)" scripts/test_reconstruction_contracts.py

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
