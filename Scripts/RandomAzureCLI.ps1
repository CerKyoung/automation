#Set DNS CNAME
az network dns record-set cname set-record --resource-group ss101-dns-df-rg --zone-name dayforcehcm.com --record-set-name ustrain60e2 --cname tls-eipacl.wildcard.dayforcehcm.com.edgekey.net

#Start VM
az vm start --name $vmName --resource-group $rgName

#Create NSG Rules
az network nsg rule create -g app121-dfpc-usprod-network-eastus2 --nsg-name app121-dfpc-usprod-network-eastus2-frontend-nsg -n nsgsr-allow-akamai-to-fesubnet-web --priority 291     --source-address-prefixes 23.32.0.0/1123.192.0.0/11 2.16.0.0/13 104.64.0.0/10 184.24.0.0/13 23.0.0.0/12 95.100.0.0/15 92.122.0.0/15 172.232.0.0/13 184.50.0.0/15 88.221.0.0/16 23.64.0.0/14 72.246.0.0/15 96.16.0.0/15 96.6.0.0/15 69.192.0.0/16 23.72.0.0/13 173.222.0.0/15 118.214.0.0/16 184.84.0.0/14 --destination-address-prefixes 10.16.24.0/26 10.16.24.192/26 10.16.24.64/26 10.16.24.128/26 --destination-port-ranges 8080 8443 --direction Inbound     --access Allow --protocol TCP --description "Allow Akamai to Front End Subnet on External Web ports"
az network nsg rule create -g app121-dfpc-usprod-network-eastus2 --nsg-name app121-dfpc-usprod-network-eastus2-frontend-nsg -n nsgsr-allow-internal-to-fesubnet-web --priority 292     --source-address-prefixes 10.0.0.0/8--destination-address-prefixes 10.16.24.0/26 10.16.24.192/26 10.16.24.64/26 10.16.24.128/26 --destination-port-ranges 80 443  --direction Inbound     --access Allow --protocol TCP --description "Allow internal to Front End Subnet on http/https"
az network nsg rule create -g app121-dfpc-usprod-network-eastus2 --nsg-name app121-dfpc-usprod-network-eastus2-frontend-nsg -n nsgsr-deny-internet-to-vnet-any --priority 4001     --source-address-prefixes Internet --destination-address-prefixes '*' --destination-port-ranges '*'  --direction Inbound     --access Deny --protocol '*' --description "Deny ALL Inbound internet traffic not already allowed"
az account set --subscription d06151d6-e218-43c8-a8c8-7080707476aa