NAME = mrchub/nginx-lua
TAG = 0.12.2
ALIAS = latest
SHELL = /bin/bash

# docker build --pull -t mrchub/nginx-lua:0.12.3 .
# docker push mrchub/nginx-lua:0.12.2

.PHONY: pre-build docker-build post-build clean build tag release push do-push post-push

build: pre-build docker-build post-build

pre-build:

post-build: clean

docker-build:
	docker build --pull -t $(NAME):$(TAG) .

release: build tag push

push: do-push post-push

push-stable: tag-stable do-push-stable

tag:
	docker tag $(NAME):$(TAG) $(NAME):$(ALIAS)

tag-stable:
	docker tag $(NAME):$(TAG) $(NAME):stable

do-push-stable: do-push
	docker push $(NAME):stable

do-push:
	docker push $(NAME):$(TAG)
	docker push $(NAME):$(ALIAS)

post-push:

clean:

