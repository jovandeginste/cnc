## Generate keys:

This needs to be done for client and server.

```bash
mdir keys
for item in server client
do
  (
  mkdir keys/$item
  cd keys/$item
  # Generate private key + certificate:
  openssl req -nodes -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem
  # Generate public key from private key:
  openssl rsa -pubout -in key.pem -out public.pem
  )
done
```

(We don't use the cert for the client yet - I hope to add client certificate authentication at some point)

## Starting
