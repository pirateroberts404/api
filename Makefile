#
# OpenTHC API Makefile
#

#
# Help, the default target
help:
	@echo
	@echo "You must supply a make command"
	@echo
	@grep --null-data --only-matching --perl-regexp "#\n#.*\n[\w\-]+:.*\n" $(MAKEFILE_LIST) \
		| awk '/[a-zA-Z0-9_-]+:/ { printf "  \033[0;49;32m%-20s\033[0m%s\n", $$1, gensub(/^# /, "", 1, x) }; { x=$$0 }' \
		| sort
	@echo


#
# Install necessary stuff
install:

	apt-get -qy update
	apt-get -qy upgrade
	apt-get -qy install doxygen graphviz libyaml-dev

	# http://pecl.php.net/package/yaml
	pecl install yaml-1.3.1

	echo "extension=yaml.so" > /etc/php5/mods-available/yaml.ini
	php5enmod yaml

	gem install asciidoctor-diagram coderay pygments.rb
	gem install asciidoctor-pdf --pre


#
# All the things
all: code-swagger docs


#
# Build a bunch of docs
docs: docs-asciidoc docs-doxygen docs-swagger


#
# Generate asciidoc formats
docs-asciidoc:

	asciidoctor \
		--verbose \
		--backend=html5 \
		--require=asciidoctor-diagram \
		--section-numbers \
		--out-file=./webroot/doc/index.html \
		./doc/index.ad

	asciidoctor \
		--verbose \
		--backend=pdf \
		--require=asciidoctor-diagram \
		--require=asciidoctor-pdf \
		--section-numbers \
		--out-file=./doc/openthc-api.pdf \
		./doc/index.ad

	mv ./doc/openthc-api.pdf ./webroot/doc/openthc-api.pdf

	# asciidoc \
	# 	--backend=html5 \
	# 	--out-file=./webroot/doc/index-alt.html \
	# 	./doc/index.ad
	#
	# asciidoc \
	# 	--conf-file=./etc/asciidoc.conf \
	# 	--backend=html5 \
	# 	--out-file=./webroot/doc/index-cool.html \
	# 	./doc/index.ad
	#
	# asciidoc \
	# 	--backend=slidy \
	# 	--out-file=./webroot/doc/slides.html \
	# 	./doc/index.ad


#
# Magic with revealjs
docs-asciidoctor-reveal:
	bundle config --local github.https true
	bundle --path=.bundle/gems --binstubs=.bundle/.bin
	bundle exec asciidoctor-revealjs -a revealjsdir=https://cdnjs.cloudflare.com/ajax/libs/reveal.js/3.7.0 ./doc/index.ad


#
# Generate Doxygent stuff
docs-doxygen:

	doxygen etc/Doxyfile


#
# Build the Slate docs (/doc/swagger-ui/dist)
docs-slate:


#
# Build the Swagger docs (/doc/swagger-ui/dist)
docs-swagger:

	# rm -fr ./webroot/doc/swagger
	# rm -fr ./webroot/doc/swagger-ui

	# git clone https://github.com/swagger-api/swagger-ui.git ./webroot/doc/swagger-ui/
	#cd ./webroot/doc/swagger-ui/ && git pull || true

	# mkdir ./webroot/doc/swagger/
	# cp -a ./doc/swagger ./webroot/doc/

	echo "# --- Generated File ---" > ./swagger.yaml
	php ./bin/swagger-build.php >> ./swagger.yaml
	mv ./swagger.yaml ./webroot/doc/swagger.yaml

#	#
#	rm -fr ./webroot/doc/swagger-html
#	java -jar swagger-codegen-cli.jar \
#		generate \
#		--input-spec ./webroot/doc/swagger.yaml \
#		--lang html \
#		--output ./webroot/doc/swagger-html || true
#
#	#
#	rm -fr ./webroot/doc/swagger-html2
#	java -jar swagger-codegen-cli.jar \
#		generate \
#		--input-spec ./webroot/doc/swagger.yaml \
#		--lang html2 \
#		--output ./webroot/doc/swagger-html2 || true


#
# Generate JSON Schema Files
code-json-schema:

	# Building Schemas
	# The files in this repo are constructed from the definitions in the API project.

	python \
		/opt/openapi2jsonschema/openapi2jsonschema/command.py \
		--output ./json-schema/ \
		--stand-alone \
		webroot/doc/swagger.yaml

	#mv ./schemas/* ./json-schema/
	#rm -fr ./schemas/


#
# https://github.com/swagger-api/swagger-codegen
# Generate Swagger Docs
code-swagger: code-swagger-php docs-swagger

	rm -fr ./webroot/sdk/bash
	java -jar swagger-codegen-cli.jar \
		generate \
		--input-spec ./doc/swagger.yaml \
		--lang bash \
		--output ./webroot/sdk/bash || true

	#rm -fr ./webroot/sdk/javascript
	#rm -fr ./webroot/sdk/javascript.zip
    #
	#java -jar swagger-codegen-cli.jar \
	#	generate \
	#	--input-spec ./doc/swagger.yaml \
	#	--lang javascript \
	#	--output ./webroot/sdk/javascript || true

	rm -fr ./webroot/sdk/python
	java -jar swagger-codegen-cli.jar \
		generate \
		--input-spec ./doc/swagger.yaml \
		--lang python \
		--output ./webroot/sdk/python || true
	#zip -r ./webroot/sdk/python.zip ./webroot/sdk/python/

	# https://generator.swagger.io/#!/Admin/get_account
	# https://online.swagger.io/validator/debug?url=https://api.openthc.org/swagger.yaml


#
#
code-swagger-go:
	rm -fr ./webroot/sdk/go
	rm -fr ./webroot/sdk/go.zip
	#java -jar swagger-codegen-cli.jar \
	#	generate \
	#	--input-spec ./doc/swagger.yaml \
	#	--lang go \
	#	--output ./webroot/sdk/go || true
    #
	#cd ./webroot/sdk && zip -r go.zip ./go/


#
# Update the PHP SDK
code-swagger-php: docs-swagger

	rm -fr ./webroot/sdk/php
	rm -fr ./webroot/sdk/php.zip

	java -jar swagger-codegen-cli.jar \
		generate \
		--input-spec ./doc/swagger.yaml \
		--lang php \
		--output ./webroot/sdk/php || true

	zip -r ./webroot/sdk/php.zip ./webroot/sdk/php/

test: phpunit

#
# Execute Unit Tests
phpunit:
	./test/test.sh
	# ./vendor/bin/phpunit --bootstrap vendor/autoload.php --configuration test/phpunit.xml test/


#
# Generate JSON Schema from Swagger
schema:

	python \
		/opt/openapi2jsonschema/openapi2jsonschema/command.py \
		--output ./webroot/json-schema/ \
		--stand-alone \
		file:/opt/api.openthc.org/webroot/doc/swagger.yaml

	#rm ./webroot/json-schema/_definitions.json

	cd ./webroot/json-schema ; ls *json > index.txt
