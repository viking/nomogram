public/nomogram.html: lib/nomogram.rb test/fixtures/data.yml views/*
	ruby -Ilib -rnomogram -e "nom = Nomogram.new('test/fixtures/data.yml'); nom.title = 'Adult Asthma Risk Calculator'; puts nom.build" > $@

clean:
	rm public/nomogram.html
