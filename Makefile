all::
	bundle exec middleman server --instrument

build::
	bundle exec middleman build

push::
	git commit -m update -a
	git push
