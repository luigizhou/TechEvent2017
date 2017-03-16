#!/bin/bash

echo -n "Enter your AWS ACCESS KEY and press [ENTER]: "
read awsaccesskey
echo -n "Enter your AWS SECRET ACCESS KEY and press [ENTER]: "
read secretaccesskey

echo "#!/bin/bash" >> setenv.sh
echo "export AWS_ACCESS_KEY_ID=\"${awsaccesskey}\"" >> setenv.sh
echo "export AWS_SECRET_ACCESS_KEY=\"${secretaccesskey}\"" >> setenv.sh

source ./setenv.sh