What is this for?
---

This is a collection of configurations and scripts to run `swtpm` for
creating TPM-enabled virtual machines running Keylime. As such, this
repository should be considered more of an extended gist than "code"
per say. There are no provisions for license; feel free to steal and
reuse code.

Prerequisites
---

* [swtpm](https://github.com/stefanberger/swtpm) has to be installed
  on the hypervisor/machine you are attempting to run this on.

Howto
---

Ideally, this should be as simple as running
`run_swtpm_socket.sh`. The desired outcome is that a socket is created
that can be used to connect to a qemu process.

Root certificates
---

When a swtpm is "manufactured" the process generates any required
signing certificates. However, for the purpose of Keylime it is
preferable for the certificate to be predictable, since Keylime uses
it to check the TPM's EK certificate.

If you want a predictable signing certificate to be used, run
`certs/make_root_ca.sh` before you run `run_swtpm_socket.sh`. That
will ensure that every swtpm process you start will use the same cert,
which can be used to have Keylime avoid certificate related errors.

Using qemu directly
---

`libvirt` is fully integrated with `swtpm` and can be made to use
swtpm directly without any need for the present script. However, if
you want to run qemu processes in standalone mode, do it as follows:

```
${QEMU_BINARY} \
    -machine ... \
    -smp 4 \
    -m 1G \
    ... \
    -chardev socket,id=chrtpm,path=${TPMSTATE}/swtpm-sock \
    -device tpm-tis-device,tpmdev=tpm0 \
    -tpmdev type=emulator,chardev=chrtpm,id=tpm0
```

Alternatives
---

TPM processes can be embedded directly into libvirt XML domain files.

```
<domain ...>
  <devices>
    <tpm model='tpm-tis'>
      <backend type='emulator' version='2.0'/>
      <alias name='tpm0'/>
    </tpm>
  </devices>
</domain>
```

Started this way libvirt will actually create a swtpm process on its
own. However, care must be taken with predictable certificates.
