# selfca

Tired of adding server exceptions, etc when doing local development with self-signed SSL certs?

This is a script to create a CA authority cert, server cert and server key for development environments.

Add the CA cert to your browser authorities and add the server cert and server key to your local server.

Because the server cert is signed by the CA, the SSL problems should go away in browsers with the CA.

Reuses parts of [https://gist.github.com/polevaultweb/c83ac276f51a523a80d8e7f9a61afad0] but includes the CA creation.

Also uses -subj arguments to avoid the question prompts when creating the CA and the CSR.
