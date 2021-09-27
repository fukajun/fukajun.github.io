dev:
	hugo server -D -p 59999

build:
	hugo

commit:
	git add content docs
	git commit -m "Update about `git status | grep content | head -1`"

push:
	git push origin master

deploy: build commit push
