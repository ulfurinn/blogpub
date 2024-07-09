.PHONY: image-debian image-alpine image build push kube restart deploy logs sh iex psql default

image-debian:
	docker build -t blogpub .

image-alpine:
	docker build -t blogpub -f Dockerfile.alpine .

image: image-alpine

build: image

push: image
	docker tag blogpub:latest sage:32000/blogpub:latest
	docker push sage:32000/blogpub:latest

kube:
	kubectl apply -f blogpub.yml

restart:
	kubectl rollout restart deployment blogpub

deploy: push kube restart

logs:
	kubectl logs -f deployment/blogpub

sh:
	kubectl exec -it deployments/blogpub -- sh

iex:
	kubectl exec -it deployments/blogpub -- sh -c "/app/bin/blogpub remote"

psql:
	psql -h sage blogpub

default: build