YEAR := $(shell awk '/^thisyear:/ { print $$2 }' year.yml)

all::
	bundle exec ruby ../scripts/gen_image.rb
year::
	bundle exec ruby ../scripts/gen_image.rb $(YEAR)

auth::
	python3 ./auth.py
