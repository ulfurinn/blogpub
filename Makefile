.PHONY: image build push kube deploy restart

image:
	docker build -t blogpub .

build: image

push: image
	docker tag blogpub:latest sage:32000/blogpub:latest
	docker push sage:32000/blogpub:latest

kube:
	kubectl apply -f secret.yml
	kubectl apply -f blogpub.yml

restart:
	kubectl rollout restart deployment blogpub

rollout: push kube restart

logs:
	kubectl logs -f deployment/blogpub

sh:
	kubectl exec -it deployments/blogpub -- sh

default: build