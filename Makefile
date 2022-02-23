POST=example

BASEDIR=$(CURDIR)
INPUTDIR=$(BASEDIR)/input
OUTPUTDIR=deploy

S3_BUCKET=vfw$(POST)

DEBUG ?= 0

setup:
	@echo 'Using _config.yml.$(POST)'
	cp _config.yml.$(POST) _config.yml

help:
	@echo 'Makefile for a Jekyll                                                                     '
	@echo '                                                                                          '
	@echo 'Usage:                                                                                    '
	@echo '   make POST=postnumber html                           (re)generate the web site          '
	@echo '   make POST=postnumber clean                          remove the generated files         '
	@echo '   make POST=postnumber pushupdate		      posts deploy folder to CDN         '
	@echo '   make POST=postnumber publish                        generate using production settings '
	@echo '   make POST=postnumber devserver                      start/restart local server         '
	@echo '                                                                                          '
	@echo 'Set the DEBUG variable to 1 to enable debugging, e.g. make DEBUG=1 html                   '
	@echo 'Set the RELATIVE variable to 1 to enable relative urls                                    '
	@echo '                                                                                          '

html: setup
	docker run --rm -v $(BASEDIR):/srv/jekyll -it jekyll/jekyll jekyll build -d $(OUTPUTDIR)

clean:
	[ ! -d $(OUTPUTDIR) ] || rm -rf $(OUTPUTDIR)

devserver: setup
	docker run -p 4000:4000 -v $(BASEDIR):/site bretfisher/jekyll-serve

pushupdate:
	aws s3 rm --recursive s3://$(S3_BUCKET)
	aws s3 sync $(OUTPUTDIR) s3://$(S3_BUCKET) --acl public-read --cache-control max-age=2592000,public

invalidate_cloudfront:
    ifeq ($(POST), 3285)
		echo "Using EARYRCOOE3IYT for Post $(POST)"
		aws cloudfront create-invalidation --distribution-id EARYRCOOE3IYT --path "/*"
    endif

publish: clean html pushupdate invalidate_cloudfront

.PHONY: html help clean serve devserver stopserver pushupdate invalidate_cloudfront publish
