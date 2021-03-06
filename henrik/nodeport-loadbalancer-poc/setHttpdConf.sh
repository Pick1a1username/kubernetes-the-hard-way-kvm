source ../apiReader/apiReader.f

Services=$(getServices default | tr " " "\n")
Nodes=$(getNodeNames | tr " " "\n")

echo "<VirtualHost *:80>
        ProxyRequests off

        ServerName example.org
        ProxyPreserveHost On"

printf '%s\n' "$Services" | while IFS= read -r line
do
ServicePort=$(getServiceNodePorts $line "default")
Endpoints=$(getServiceEndpoints $line "default")

if [ ! "$ServicePort" == "null" ] && [ ! "$Endpoints" == "" ]; then
  echo "
        <Proxy balancer://$line>"


  printf '%s\n' "$Nodes" | while IFS= read -r line
  do
    nodeIP=$(getNodeIPs $line)
    echo "                BalancerMember http://$nodeIP:$ServicePort"
  done
  echo "
                # Security technically we arent blocking
                # anyone but this is the place to make
                # those changes.
                #Order Allow
                #Require all granted
                # In this example all requests are allowed.

                # Load Balancer Settings
                # We will be configuring a simple Round
                # Robin style load balancer.  This means
                # that all webheads take an equal share of
                # of the load.
                ProxySet lbmethod=byrequests
        </Proxy>"
fi
  done
echo "        # balancer-manager
        # This tool is built into the mod_proxy_balancer
        # module and will allow you to do some simple
        # modifications to the balanced group via a gui
        # web interface.
        <Location /balancer-manager>
                SetHandler balancer-manager

                # I recommend locking this one down to your
                # your office
                # Require host example.org

        </Location>"


echo "
        # Point of Balance
        # This setting will allow to explicitly name the
        # the location in the site that we want to be
        # balanced, in this example we will balance "/"
        # or everything in the site.
        ProxyPass /balancer-manager !
"


printf '%s\n' "$Services" | while IFS= read -r line
do
  ServicePort=$(getServiceNodePorts $line "default")
  Endpoints=$(getServiceEndpoints $line "default")

  if [ ! "$ServicePort" == "null" ] && [ ! "$Endpoints" == "" ]; then
    echo "        ProxyPass /$line balancer://$line
        ProxyPassReverse /$line balancer://$line"
  fi
done

echo "
</VirtualHost>"
