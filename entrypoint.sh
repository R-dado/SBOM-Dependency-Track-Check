DT_URL=$1
DT_KEY=$2


INSECURE="--insecure"
VERBOSE="--verbose"
cd $GITHUB_WORKSPACE


echo "[*]  Processing Java BoM"
if [ ! $? = 0 ]; then
    echo "[-] Error executing Java build. Stopping the action!"
    exit 1
fi

path="bom.json"
echo "[*] ----------------BoMResult?---------------------------------"
BoMResult=$(gradle build)
echo "[*] ----------------BoMResult?---------------------------------"

# echo "[*] -------------------------------------------------"
# cd /github/workspace/app/build/reports
# pwd
# ls

# echo "[*] ----------------------bom.xml---------------------------"
# cat /github/workspace/app/build/reports/bom.xml
# echo "[*] ----------------------bom.xml---------------------------"
echo "[*] ----------------------bom.json---------------------------"
cat /github/workspace/app/build/reports/bom.json
echo "[*] ----------------------bom.json---------------------------"
# gradle --version
# echo "[*] -------------------------------------------------"

echo "[*] BoM file succesfully generated"

# echo "[*] Cyclonedx CLI conversion"
# cyclonedx-cli convert --input-file $path --output-file sbom.xml --output-format json
# echo "[*] --------------------after CLI-----------------------------"
# cd /github/workspace/app/build/reports
# pwd
# ls
# echo "[*] --------------------after CLI-----------------------------"
# echo "[*] ----------------------sbom.json---------------------------"
# cat /github/workspace/app/build/reports/sbom.xml
# echo "[*] ----------------------sbom.json---------------------------"
# echo "[*] --------------------after CLI-----------------------------"

echo "[*] --------------------ver-----------------------------"
curl -X "GET" $DT_URL/api/version
echo "[*] --------------------ver-----------------------------"
echo "[*] ---------------------catalog----------------------------"
pwd
ls
echo "[*] ---------------------catalog----------------------------"
echo "[*] Uploading BoM file to Dependency Track server"
upload_bom=$(curl $INSECURE $VERBOSE -s --location --request "POST" "$DT_URL/api/v1/bom" \
--header "X-Api-Key: $DT_KEY" \
--header "Content-Type: multipart/form-data" \
--form "autoCreate=true" \
--form "projectName=$GITHUB_REPOSITORY" \
--form "projectVersion=$GITHUB_REF" \
--form "bom=@/github/workspace/app/build/reports/bom.json")
echo "[*] -------------------------------------------------"
echo $upload_bom
echo "[*] -------------------------------------------------"

token=$(echo $upload_bom | jq ".token" | tr -d "\"")
echo "[*] BoM file succesfully uploaded with token $token"

if [ -z $token ]; then
    echo "[-]  The BoM file has not been successfully processed by OWASP Dependency Track"
    exit 1
fi

echo "[*] Checking BoM processing status"
processing=$(curl $INSECURE $VERBOSE -s --location --request "GET" $DT_URL/api/v1/bom/token/$token \
--header "X-Api-Key: $DT_KEY" | jq '.processing')

while [ $processing = true ]; do
    sleep 5
    processing=$(curl  $INSECURE $VERBOSE -s --location --request "GET" $DT_URL/api/v1/bom/token/$token \
--header "X-Api-Key: $DT_KEY" | jq '.processing')
    if [ $((++c)) -eq 10 ]; then
        echo "[-]  Timeout while waiting for processing result. Please check the OWASP Dependency Track status."
        exit 1
    fi
done

echo "[*] OWASP Dependency Track processing completed"

sleep 5

echo "[*] Retrieving project information"
project=$(curl  $INSECURE $VERBOSE -s --location --request "GET" "$DT_URL/api/v1/project/lookup?name=$GITHUB_REPOSITORY&version=$GITHUB_REF" \
--header "X-Api-Key: $DT_KEY")

echo "$project"

project_uuid=$(echo $project | jq ".uuid" | tr -d "\"")
risk_score=$(echo $project | jq ".lastInheritedRiskScore")
echo "Project risk score: $risk_score"

echo "::set-output name=riskscore::$risk_score"
