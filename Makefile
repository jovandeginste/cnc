keys: serverkeys clientkeys

keysdir:
	mkdir -p keys

serverkeys: keysdir
	$(MAKE) keysfor DIR=keys/server

clientkeys: keysdir
	$(MAKE) keysfor DIR=keys/client

keysfor:
	mkdir -p $(DIR)
	# Generate private key + certificate:
	openssl req -nodes -x509 -newkey rsa:2048 -keyout $(DIR)/key.pem -out $(DIR)/cert.pem -subj '/C=/ST=/L=/CN=localhost'
	# Generate public key from private key:
	openssl rsa -pubout -in $(DIR)/key.pem -out $(DIR)/public.pem

