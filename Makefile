all: build/index.html build/casperlang.html build/style.css

build/index.html: index.md index_template.html
	pandoc --standalone --template index_template.html index.md --output $@

build/casperlang.html: casperlang.md template.html
	pandoc --standalone --template template.html --from markdown+backtick_code_blocks casperlang.md --output $@

build/style.css: style.css
	cp $^ $@

deploy:
	aws s3 sync ./build/ s3://openengineer.dev
