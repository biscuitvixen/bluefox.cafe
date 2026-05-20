# Wrappers over the container toolchain and deploy script.
# No host installs; see docker-compose.yml and deploy.sh.

.PHONY: build serve deploy

build:   ## build site into public/
	docker compose run --rm build

serve:   ## preview on :1313
	docker compose up serve

deploy:  ## build and publish to the VPS over tailnet
	sh deploy.sh
