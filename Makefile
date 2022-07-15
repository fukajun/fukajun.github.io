dev:
	bash -c "sleep 2 && open -a '/Applications/Google Chrome.app' http://localhost:59999" &
	hugo server -D -p 59999

build:
	hugo

commit:
	git add docs
	git commit -m "Update docs"

push:
	git push origin master -f

deploy: build commit push

build-thema:
	cd themes/hugo-bootstrap-5 && npm run build

dev-thema:
	cd themes/hugo-bootstrap-5 && npm run watch
