VER:=0.0.1
PACKAGE:=gravitational.io/pithos-app:$(VER)
CONTAINERS:=pithos-bootstrap:$(VER) pithos-uninstall:$(VER) cassandra:$(VER)
LOCAL_WORK_DIR:=/var/lib/gravity/opscenter

.PHONY: all
all: images

.PHONY: images
images:
	cd images && $(MAKE) -f Makefile VERSION=$(VER)

.PHONY: clean
clean:
	cd images && $(MAKE) -f Makefile clean

.PHONY: dev-push
dev-push: images
	for container in $(CONTAINERS); do \
		docker tag $$container apiserver:5000/$$container ;\
		docker push apiserver:5000/$$container ;\
	done

.PHONY: dev-redeploy
dev-redeploy: dev-clean dev-deploy

.PHONY: dev-deploy
dev-deploy: dev-push
	-kubectl label nodes -l role=node pithos-role=node
	kubectl create configmap cassandra-cfg --from-file=resources/cassandra-cfg
	kubectl create configmap pithos-cfg --from-file=resources/pithos-cfg
	kubectl create -f dev/cassandra.yaml

.PHONY: dev-clean
dev-clean:
	-kubectl delete -f dev/cassandra.yaml
	-kubectl delete configmap cassandra-cfg
	-kubectl label nodes -l pithos-role=node pithos-role-

.PHONY: vendor-import
vendor-import:
	-gravity app --state-dir=$(LOCAL_WORK_DIR) delete $(PACKAGE) --force
	gravity app import --debug --vendor --glob=**/*.yaml --registry-url=apiserver:5000 --state-dir=$(LOCAL_WORK_DIR) .

