#
# Makefile for kbase-ui-proxy
#

TOPDIR		   = $(PWD)
DOCKER_CONTEXT = $(TOPDIR)

# The deploy environment; used by dev-time image runners
# dev, ci, next, appdev, prod
# Defaults to dev, since it is only useful for local dev; dev is really ci.
# Causes run-image.sh to use the file in deployment/conf/$(env).env for
# "filling out" the nginx and ui config templates.
# TODO: hook into the real configs out of KBase's gitlab
env = dev

net = kbase-dev


# functions
# thanks https://stackoverflow.com/questions/10858261/abort-makefile-if-variable-not-set
check_defined = \
    $(strip $(foreach 1,$1, \
        $(call __check_defined,$1,$(strip $(value 2)))))
__check_defined = \
    $(if $(value $1),, \
        $(error Undefined $1$(if $2, ($2))$(if $(value @), \
                required by target `$@')))


DOCKER_VERSION=$(shell docker version --format '{{.Server.Version}}' 2> /dev/null)
DOCKER_VERSION_REQUIRED="18"

majorver=$(word 1, $(subst ., ,$1))

good_docker_version = $(if \
	  $(findstring \
	    $(call majorver, \
		  $(DOCKER_VERSION)), \
		  $(DOCKER_VERSION_REQUIRED)), \
		  "Good docker version ($(DOCKER_VERSION))", \
		  $(error "! Docker major version must be $(DOCKER_VERSION_REQUIRED), it is $(DOCKER_VERSION).") )

.PHONY: all default test build preconditions image run clean

default: docker-image
all: docker-image run 

preconditions:
	@echo "> Testing for preconditions."
	@echo $(call good_docker_version)
	
# Initialization here pulls in all dependencies from Bower and NPM.
# This is **REQUIRED** before any build process can proceed.
# bower install is not part of the build process, since the bower
# config is not known until the parts are assembled...

build: preconditions
	bash tools/build_docker_image.sh

run: preconditions
	@:$(call check_defined, env, the deployment environment: dev ci next appdev prod)
	@:$(call check_defined, net, the docker custom network)
	$(eval cmd = $(TOPDIR)/tools/run-image.sh $(env) $(net))
	@echo "> Running proxy image"
	@echo "> with env $(env)"
	@echo "> with net $(net)"
	@echo "> Issuing: $(cmd)"
	bash $(cmd)	
