.PHONY: images build-% publish-%

CWD=$(shell basename $(CURDIR))
COMMIT=$(shell git rev-parse --short HEAD)
IMAGES=$(shell ls $(CURDIR)/images)

images:
	@echo "Below images are able to build/publish with \`make [build | publish]-<image name>\`"
	@echo $(IMAGES) | sed -E 's/(\S+)\s?/ - \1\n/g'

build-%:
	docker build -t innobead/$(CWD):$*-$(COMMIT) -f images/$*/Dockerfile .
	docker tag innobead/$(CWD):$*-$(COMMIT) innobead/$(CWD):$*-latest

publish-%: build-%
	docker push tag innobead/$(CWD):$*-$(COMMIT)
	docker push innobead/$(CWD):$*-latest
