all::
	(cd data ; make year)
	env LANG=ja_JP.utf-8 bundle exec middleman server --instrument --bind-address=0.0.0.0

build::
	bundle exec middleman build --verbose

push::
	git commit -m update -a
	git push

test::
	bundle exec rake
