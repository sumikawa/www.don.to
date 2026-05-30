SHELL := /bin/zsh
THEME=github
USER_HOME := $(HOME)
BUNDLE_USER_HOME=$(USER_HOME)/tmp
BUNDLE_PATH=$(USER_HOME)/tmp/bundle
RUBY_BUNDLE_ENV=mkdir -p "$(BUNDLE_USER_HOME)" "$(BUNDLE_PATH)" && BUNDLE_USER_HOME="$(BUNDLE_USER_HOME)" BUNDLE_PATH="$(BUNDLE_PATH)"
RUBY_BUNDLE=$(RUBY_BUNDLE_ENV) bundle exec
CODEX_BUNDLE_USER_HOME=/private/tmp/bundle
CODEX_RUBY_BUNDLE=source ~/.zshrc && mkdir -p "$(CODEX_BUNDLE_USER_HOME)" "$(BUNDLE_PATH)" && BUNDLE_USER_HOME="$(CODEX_BUNDLE_USER_HOME)" BUNDLE_PATH="$(BUNDLE_PATH)" bundle exec

run:
	parallel --line-buffer ::: \
	"$(RUBY_BUNDLE) rackup api.ru --host 0.0.0.0" \
	"$(RUBY_BUNDLE) middleman server --instrument --bind-address=0.0.0.0"

tag::
	./check_tags.rb source/diary/*/*
	kiro-cli-chat chat --no-interactive  -a "`./check_tags.rb source/diary/*/*`"

year::
	(cd data ; make year)

build::
	$(RUBY_BUNDLE) middleman build --verbose

pagefind: build
	npx pagefind --source build --glob 'diary/[0-9]*/*/*.html' --serve

tags::
	$(RUBY_BUNDLE) ruby scripts/modify_tags.rb
	$(RUBY_BUNDLE) ruby scripts/gen_tags.rb

push: tags
	git commit -m update -a
	git push

test::
	$(RUBY_BUNDLE) rake

test-codex::
	$(CODEX_RUBY_BUNDLE) rake

rubocop::
	$(RUBY_BUNDLE) rubocop

autogen::
	$(RUBY_BUNDLE) rubocop --auto-gen-config

fix::
	$(RUBY_BUNDLE) rubocop --autocorrect-all

gencss::
	$(RUBY_BUNDLE) rougify style $(THEME) | sed '/\.highlight {/,/}/d' > source/stylesheets/code.css

fetch::
	curl -s https://tabelog.com/kanagawa/A1401/A140101/14079506/ > spec/lib/tabelog_test.html
