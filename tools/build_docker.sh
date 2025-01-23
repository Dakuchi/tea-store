#!/bin/bash
DOCKER_PLATFORMS='linux/amd64,linux/arm64'
registry=''     # e.g. 'Dakuchi/'

print_usage() {
  printf "Usage: docker_build.sh [-p] [-r REGISTRY_NAME]\n"
}

while getopts 'pr:' flag; do
  case "${flag}" in
    p) push_flag='true' ;;
    r) registry="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ $DEPLOY == 1 ]
then
	docker run -it --rm --privileged tonistiigi/binfmt --install all
	docker  create --use --name mybuilder
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-db" ../utilities/tools.descartes.teastore.database/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-kieker-rabbitmq" ../utilities/tools.descartes.teastore.kieker.rabbitmq/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-base" ../utilities/tools.descartes.teastore.dockerbase/ --push
	perl -i -pe's|.*FROM Dakuchi/|FROM '"${registry}"'|g' ../services/tools.descartes.teastore.*/Dockerfile
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-registry" ../services/tools.descartes.teastore.registry/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-persistence" ../services/tools.descartes.teastore.persistence/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-image" ../services/tools.descartes.teastore.image/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-webui" ../services/tools.descartes.teastore.webui/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-auth" ../services/tools.descartes.teastore.auth/ --push
	docker  build --platform ${DOCKER_PLATFORMS} -t "${registry}teastore-recommender" ../services/tools.descartes.teastore.recommender/ --push
	perl -i -pe's|.*FROM '"${registry}"'|FROM Dakuchi/|g' ../services/tools.descartes.teastore.*/Dockerfile
	docker  rm mybuilder
else
	registry='Dakuchi/'
	docker  build -t "${registry}teastore-db" ../utilities/tools.descartes.teastore.database/ --load
	docker  build -t "${registry}teastore-kieker-rabbitmq" ../utilities/tools.descartes.teastore.kieker.rabbitmq/ --load
	docker  build -t "${registry}teastore-base" ../utilities/tools.descartes.teastore.dockerbase/ --load
	docker  build -t "${registry}teastore-registry" ../services/tools.descartes.teastore.registry/ --load
	docker  build -t "${registry}teastore-persistence" ../services/tools.descartes.teastore.persistence/ --load
	docker  build -t "${registry}teastore-image" ../services/tools.descartes.teastore.image/ --load
	docker  build -t "${registry}teastore-webui" ../services/tools.descartes.teastore.webui/ --load
	docker  build -t "${registry}teastore-auth" ../services/tools.descartes.teastore.auth/ --load
	docker  build -t "${registry}teastore-recommender" ../services/tools.descartes.teastore.recommender/ --load
fi

