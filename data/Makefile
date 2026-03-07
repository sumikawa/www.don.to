YEAR := $(shell awk '/^thisyear:/ { print $$2 }' year.yml)

all::
	python3 ./gen_image.py
year::
	python3 ./gen_image.py $(YEAR)

auth::
	python3 ./auth.py
