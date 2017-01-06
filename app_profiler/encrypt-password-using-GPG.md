# Encrypt password using GPG
 
GnuPG is a complete and free implementation of the OpenPGP standard.
GnuPG allows to encrypt and sign your data and communication, features a versatile
key management system as well as access modules for all kinds of public key directories.
 
## Encrypt Password for command line use.
 
Shell scripts are often used to integrogate cloud foundry. These scripts, are commands using the `cf cli`. The bad part about the `cf cli`, it does not allow passing of masked password. The user
password must be passed with `-p <password>` option for batch mode.
 
GPG allows encrypting of the user password and the password can be decrypted on
the `cf cli` command line without exposing it.
 
To use GPG encyrpted password, follow the steps below
  
1. Create a folder that is restricted only for this user
```
  $> cd
  $> mkdir .private
  $> chmod 700 .private
  $> cd ~/.private
```
 
2. Create a plain text file with password (pwd.txt) and passpharase (passphrase.txt). **Make sure that these files have 600 permissions**.
```
  $> chmod 600 pwd.txt passphrase.txt
```
 
3. Encrypt password file
```
  $> gpg2 --output "pwd.gpg" --batch --passphrase-file passphrase.txt --symmetric pwd.txt
```
 
4. Use decrypt and verify the returned password
```
   $> gpg2 --no-tty --batch --quiet --no-mdc-warning --passphrase-file passphrase.txt --decrypt pwd.gpg
```
 
5. Delete the plain text password file. Do not delete the passphrase file.
```
  $> rm pwd.txt
```
 
6. Use the encrypted password on call to `cf cli` as follows
```
   $> cf login -a https://api.local2.pcfdev.io -u user -p $(gpg2 --no-tty --batch --quiet --no-mdc-warning --passphrase-file ~/.private/passphrase.txt --decrypt ~/.private/pwd.gpg)
```
