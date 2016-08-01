all: manifest
	buildapp \
		--manifest-file manifest \
		--load-system ilex \
		--output ilex \
		--entry ilex:main \
		--compress-core \

manifest:
	sbcl --eval '(ql:write-asdf-manifest-file "manifest" )' \
	--eval '(quit)'

clean:
	rm *.fasl out manifest
