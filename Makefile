dev:
	hugo server -D -p 59999

build:
	hugo

commit:
	git add docs
	git commit -m "Update docs"

push:
	git push origin master

deploy: build commit push
