run:
	@set -e; \
	trap 'kill 0' INT; \
	bundle exec rackup api.ru --host 0.0.0.0 &
	bundle exec middleman server --instrument --bind-address=0.0.0.0
	wait

tag::
	./check_tags.rb source/diary/20*/*
	kiro-cli-chat chat --no-interactive  -a "`./check_tags.rb source/diary/20*/*`"

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
	bundle exec rougify style github | sed '/\.highlight {/,/}/d' > source/stylesheets/code.css
