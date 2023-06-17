# Download the cf-v4-ddns.sh file
cd /root

wget -q https://raw.githubusercontent.com/jamespan2012/myshellscripts/main/cf-v4-ddns.sh -O cf-v4-ddns.sh

# Prompt the user to enter the CFKEY value
read -p "Enter Cloudflare API key: " CFKEY

# Prompt the user to enter the CFZONE_NAME value
read -p "Enter Cloudflare Zone name: " CFZONE_NAME

# Prompt the user to enter the CFRECORD_NAME value
read -p "Enter Cloudflare Record name: " CFRECORD_NAME

# Change the values in the cf-v4-ddns.sh file
sed -i "s/aCFKEY=.*/CFKEY=\"$CFKEY\"/" cf-v4-ddns.sh
sed -i "s/aCFZONE_NAME=.*/CFZONE_NAME=\"$CFZONE_NAME\"/" cf-v4-ddns.sh
sed -i "s/aCFRECORD_NAME=.*/CFRECORD_NAME=\"$CFRECORD_NAME\"/" cf-v4-ddns.sh

echo "Updated values in cf-v4-ddns.sh successfully!"

echo "*/1 * * * * /root/cf-v4-ddns.sh >/dev/null 2>&1" >> mycron
crontab mycron
rm mycron

echo "Cron successfully!"
