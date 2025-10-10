all::
ifndef SSH_CLIENT
	(cd data ; make year)
endif
	bundle exec middleman server --instrument --bind-address=0.0.0.0

year::
	(cd data ; make year)

build::
	bundle exec middleman build --verbose

pagefind: build
	npx pagefind --source build --glob 'diary/[0-9]*/*/*.html' --serve

push::
	git commit -m update -a
	git push

test::
	bundle exec rake

rubocop::
	bundle exec rubocop

autogen::
	bundle exec rubocop --auto-gen-config

fix::
	bundle exec rubocop --autocorrect-all

gencss::
	bundle exec rougify style thankful_eyes > source/stylesheets/code.css
