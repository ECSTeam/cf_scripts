### binaries
# cf cli 
cf="/usr/local/bin/cf"
# GnuPG utility
gpg2="/usr/local/MacGPG2/bin/gpg2"
# netcat utility (for statsd only)
nc="/usr/bin/nc"

# is the password encrypted (gpg2)
pwd_encrypted=false

# skip ssl validation (leave it blank, if not using it)
skip_ssl="--skip-ssl-validation"

# cf target
cf_target="https://api.local2.pcfdev.io";

# defaults to login
cf_org="pcfdev-org";
cf_space="pcfdev-space";
cf_user="user";

# if password is encrypted, `cf_pwd` will be ignored.
cf_pwd="pass";

