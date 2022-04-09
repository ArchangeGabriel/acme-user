# acme-user

These are scripts and configuration files to run
[acme-tiny](https://github.com/diafygi/acme-tiny) unpriviledged as much as
possible under systemd systems.

## Initial set-up

This is based upon [upstream README](https://github.com/diafygi/acme-tiny#readme=), refer to it for details.

### [Account private key](https://github.com/diafygi/acme-tiny#step-1-create-a-lets-encrypt-account-private-key-if-you-havent-already=)

After generating or converting your account private key, store it as
```sh
/etc/acme/accountkey.pem
```
and set permission/ownership to `440 acme:acme`.

### [Certificate signing request](https://github.com/diafygi/acme-tiny#step-2-create-a-certificate-signing-request-csr-for-your-domains=)

The `${domain}` private key should be stored as
```sh
/etc/acme/${domain}/privkey.pem
```
and have permission/ownership to `400 root:root`, but actually `acme-tiny` does
not use it once the CSR is generated, so these are just general recommandations.

However the CSR must be stored as
```sh
/etc/acme/${domain}/csr.pem
```
and be `440 acme:acme`.

Note that if you want to enable OCSP Must Staple for you certificates, you can
pass `-addext "tlsfeature = status_request"` to the `openssl req` command, in
which case you might want to setup OCSP priming.

### [Hosting challenge files](https://github.com/diafygi/acme-tiny#step-3-make-your-website-host-challenge-files=)

One important modification here: the files are expected to reside under
`/var/lib/acme/`. The folder is created by the `systemd-tmpfiles` config,
but you need to setup your HTTP server correctly for this path.

### [First certificate](https://github.com/diafygi/acme-tiny#step-4-get-a-signed-certificate)

Here we deviate sensibly from upstream because we also setup OCSP priming for
OCSP stapling (see your web server document for how to configure that).

1. Get the certificate:
```sh
sudo -u acme sh -c "/usr/bin/acme-tiny --account-key /etc/acme/accountkey.pem --csr /etc/acme/${domain}/csr.pem --acme-dir /var/lib/acme/ > /etc/acme/${domain}/fullchain.pem"
```
2. Fix permissions:
```sh
sudo chown root:root /etc/acme/${domain}/fullchain.pem
sudo chmod 444 /etc/acme/${domain}/fullchain.pem
```
3. Split the cert for our needs:
```sh
FULLCHAIN=$(sudo cat /etc/acme/${domain}/fullchain.pem)
echo "${FULLCHAIN%%-----END CERTIFICATE-----*}-----END CERTIFICATE-----" | sudo tee /etc/acme/${domain}/cert.pem
echo -e "${FULLCHAIN#*-----END CERTIFICATE-----}" | sed '/./,$!d' | sudo tee /etc/acme/${domain}/chain.pem
```
4. OCSP priming:
```sh
sudo openssl ocsp -noverify -no_nonce -respout /etc/acme/${domain}/ocsp.der -issuer /etc/acme/${domain}/chain.pem -cert /etc/acme/${domain}/cert.pem -url $(sudo openssl x509 -noout -ocsp_uri -in /etc/acme/${domain}/cert.pem)
```

## Renewal setup

Just enable the `acme.timer` systemd timer.

### Services reloading

Most server services need to be reloaded or restarted in order to take into
account a renewed certificate. You can have the systemd service automatically
do so by adding a drop-in override:
```sh
[Service]
ExecStartPost=/usr/bin/systemctl try-reload-or-restart <space separated list of services>
```
For instance, an usual `<space separated list of services>` on a mail server
might be `nginx smtpd dovecot`.

### OCSP priming

Nothing to do: the files are regenerated on each service run, so twice per day,
while they are actually valid for 7 days and renewed upstream every 3 days.
