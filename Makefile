all::
	bundle exec middleman server --instrument

build::
	bundle exec middleman build

backup::
	git push -u bitbucket master
