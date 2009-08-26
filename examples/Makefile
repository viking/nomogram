public/nomogram.html: ../lib/nomogram.rb ../test/fixtures/data.yml ../views/nomogram.html.erb
	ruby -I../lib -rnomogram -e "puts Nomogram.new('../test/fixtures/data.yml').build" > $@

clean:
	rm public/nomogram.html
