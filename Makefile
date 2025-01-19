all::
	bundle exec middleman server --instrument --bind-address=127.0.0.1

build::
	bundle exec middleman build --verbose

push::
	git commit -m update -a
	git push
