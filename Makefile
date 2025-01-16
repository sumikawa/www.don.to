all::
	bundle exec middleman server --instrument

build::
	bundle exec middleman build --verbose

push::
	git commit -m update -a
	git push
