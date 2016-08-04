all: manifest
	buildapp \
		--manifest-file manifest \
		--load-system ilex \
		--output ilex \
		--entry ilex:main \
		#--compress-core \ #

manifest:
	sbcl --eval '(ql:write-asdf-manifest-file "manifest" )' \
	--eval '(quit)'

clean:
	git clean -fd
