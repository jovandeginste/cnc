## Generate keys:

You need keys for the server and the client(s). For dev setup, just `make` them:

```bash
make keys
```

(We don't use the cert for the client yet - I hope to add client certificate authentication at some point)

## Starting

First start the server:

```bash
./server
```

This should launch the Sinatra app listening on `localhost:9443`. You can test it manually. Simply running `curl` should throw an SSL exception because the certificate is self-signed:

```bash
$ curl -v https://localhost:9443/
* About to connect() to localhost port 9443 (#0)
*   Trying 127.0.0.1... connected
* Connected to localhost (127.0.0.1) port 9443 (#0)
* Initializing NSS with certpath: sql:/etc/pki/nssdb
*   CAfile: /etc/pki/tls/certs/ca-bundle.crt
  CApath: none
* Certificate is signed by an untrusted issuer: 'CN=localhost'
* NSS error -8172
* Closing connection #0
* Peer certificate cannot be authenticated with known CA certificates
curl: (60) Peer certificate cannot be authenticated with known CA certificates
More details here: http://curl.haxx.se/docs/sslcerts.html
```

You can provide the self-signed cert as a hint to `curl`, which will then happily work:

```bash
$ curl --cacert keys/server/cert.pem https://localhost:9443/
Hello, world!
```

Some extra `curls`:

```bash
$ curl --cacert keys/server/cert.pem https://localhost:9443/generate_token
Verification needed
$ curl --cacert keys/server/cert.pem -H 'X-User: jo' https://localhost:9443/generate_token
zsOH1ZRxla1T6KoUi2kY0Q==
$ curl --cacert keys/server/cert.pem -H 'X-User: jo' https://localhost:9443/tokens
Verification needed
```

To test the `/tokens' endpoint requires some encryption, so I will not do this using `curl` now.

Run the client:

```bash
$ ./client
Sending simple query '/ping'
[200] /generate_token (size=24)
[200] /ping (size=39)
Sending simple post '/execute', payload: {:command=>"hostname; uptime; date; whoami"}
[200] /generate_token (size=24)
[200] /execute (size=195)
Result: {"command"=>"hostname; uptime; date; whoami", "output"=>"icts-p-nx-4\n 14:17:58 up 220 days, 23:41, 168 users,  load average: 1.13, 1.10, 1.02\nTue Aug 23 14:17:58 CEST 2016\nu0044579\n", "error"=>""}
Sending simple post '/execute', payload: {:command=>"whoami"}
[200] /generate_token (size=24)
[200] /execute (size=53)
Result: {"command"=>"whoami", "output"=>"u0044579\n", "error"=>""}
```
