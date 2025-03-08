# acme-user

These are scripts and configuration files to run
[acme-tiny](https://github.com/diafygi/acme-tiny) unpriviledged as much as
possible under systemd systems.

## Initial set-up

This is based upon [upstream README](https://github.com/diafygi/acme-tiny?tab=readme-ov-file#acme-tiny), refer to it for details.

### [Account private key](https://github.com/diafygi/acme-tiny?tab=readme-ov-file#step-1-create-a-lets-encrypt-account-private-key-if-you-havent-already)

After generating or converting your account private key, store it as
```sh
/etc/acme/accountkey.pem
```
and set permission/ownership to `440 acme:acme`.

### [Certificate signing request](https://github.com/diafygi/acme-tiny?tab=readme-ov-file#step-2-create-a-certificate-signing-request-csr-for-your-domains)

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

### [Hosting challenge files](https://github.com/diafygi/acme-tiny?tab=readme-ov-file#step-3-make-your-website-host-challenge-files)

One important modification here: the files are expected to reside under
`/var/lib/acme/`. The folder is created by the `systemd-tmpfiles` config,
but you need to setup your HTTP server correctly for this path.

### [First certificate](https://github.com/diafygi/acme-tiny?tab=readme-ov-file#step-4-get-a-signed-certificate)

Here we deviate a bit from upstream because we use a dedicated system user
(that is the point of this project) and need to adapt ownership and
permissions.

1. Get the certificate:
```sh
sudo -u acme sh -c "/usr/bin/acme-tiny --account-key /etc/acme/accountkey.pem --csr /etc/acme/${domain}/csr.pem --acme-dir /var/lib/acme/ > /etc/acme/${domain}/fullchain.pem"
```
2. Fix permissions:
```sh
sudo chown root:root /etc/acme/${domain}/fullchain.pem
sudo chmod 444 /etc/acme/${domain}/fullchain.pem
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
