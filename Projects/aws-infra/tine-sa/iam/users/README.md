## How to create a new organization-admin user

* Run the ./createUser.sh script , and answer "y" when asked if used should be added to organization-admin group. Make sure to use your adminuser that assumes the correct admin role.


`./createUser.sh -p admin@master`

The script will create the user and generate an access key.

Use those credentials for update you .aws/config and .aws/credentials to setup the profile for your new user.


* Create the MFA virtual device and enable it.

```
aws iam create-virtual-mfa-device --virtual-mfa-device-name ${username} --outfile ./QRCode.png --bootstrap-method QRCodePNG  --profile ${profile}
```
This command will create a PNG file in this folder.


* Enable the virtual mfa device for your new user.

```
aws iam enable-mfa-device --user-name ${username} --serial-number arn:aws:iam::641159406575:mfa/{username} --authentication-code-1 <code 1> --authentication-code-2 <code 2> --profile ${profile}
```
