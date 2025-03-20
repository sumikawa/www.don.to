all::
ifndef SSH_CLIENT
	(cd data ; make year)
endif
	env LANG=ja_JP.utf-8 bundle exec middleman server --instrument --bind-address=0.0.0.0

build::
	bundle exec middleman build --verbose

push::
	git commit -m update -a
	git push

test::
	bundle exec rake

gencss::
	bundle exec rougify style thankful_eyes > source/stylesheets/code.css
