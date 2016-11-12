# Mailgun with sSMTP



```bash
apt-get install ssmtp mailutils
```
ssmtp.conf

```bash
# Are users allowed to set their own From: address?
# YES - Allow the user to specify their own From: address
# NO - Use the system generated From: address
#FromLineOverride=YES

# The user that gets all the mails (UID < 1000, usually the admin)
root=postmaster@domain.com

# The mail server (where the mail is sent to), both port 465 or 587 should be acceptable
# See also http://mail.google.com/support/bin/answer.py?answer=78799
mailhub=smtp.mailgun.org:587

# The address where the mail appears to come from for user authentication.
rewriteDomain=domain.com

# The full hostname
hostname=ks4001046.ip-198-245-49.net

# Use SSL/TLS before starting negotiation
UseTLS=Yes
UseSTARTTLS=Yes

# Username/Password
AuthUser=postmaster@domain.com
AuthPass=a6e7fb5c89d354442db807d8919cf061

# Email 'From header's can 
```

revaliases
```
# sSMTP aliases
# 
# Format:	local_account:outgoing_address:mailhub
#
# Example: root:your_login@your.domain:mailhub.your.domain[:port]
# where [:port] is an optional port number that defaults to 25.

root:postmaster@domain.com:smtp.mailgun.org:587
```