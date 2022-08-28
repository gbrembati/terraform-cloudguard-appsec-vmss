# Accept the agreement for the mgmt-byol for R80.40
resource "azurerm_marketplace_agreement" "appsec-vmss-agreement" {
  count = var.appsec-vmss-agreement ? 0 : 1
  publisher = "checkpoint"
  offer = "infinity-gw"
  plan = "infinity-img"
}

# Create appsec resource group
resource "azurerm_resource_group" "rg-appsec-vmss" {
  name = "rg-${var.appsec-name}"
  location = var.location
}
resource "azurerm_resource_group_template_deployment" "template-deployment-appsec" {
  name                = "${var.appsec-name}-deploy"
  resource_group_name = azurerm_resource_group.rg-appsec-vmss.name
  deployment_mode     = "Complete"

  template_content    = file("files/appsec-vmss-template-aug-22.json")
  parameters_content  = <<PARAMETERS
  {
    "location": {
        "value": "${azurerm_resource_group.rg-appsec-vmss.location}"
    },
    "authenticationType": {
        "value": "password"
        },
    "adminPassword": {
        "value": "${var.admin-pwd}"
    },
    "vmName": {
        "value": "${var.appsec-name}"
    },
    "instanceCount": {
        "value": "${var.appsec-vmss-min}"
    },
    "maxInstanceCount": {
        "value": "${var.appsec-vmss-max}"
    },
    "deploymentMode": {
        "value": "ELBOnly"
    },
    "instanceLevelPublicIP": {
        "value": "yes"
    },
    "appLoadDistribution": {
        "value": "SourceIP"
    },
    "availabilityZonesNum": {
        "value": 2
    },
    "vmSize": {
        "value": "${var.appsec-size}"
    },
    "bootstrapScript": {
        "value": ""
    },
    "sourceImageVhdUri": {
        "value": "noCustomUri"
    },
    "virtualNetworkName": {
        "value": "${azurerm_virtual_network.vnet-north.name}"
    },
    "virtualNetworkAddressPrefixes": {
        "value": [
            "${azurerm_virtual_network.vnet-north.address_space[0]}"
        ]
    },
    "vnetNewOrExisting": {
        "value": "existing"
    },
    "virtualNetworkExistingRGName": {
        "value": "${azurerm_virtual_network.vnet-north.resource_group_name}"
    },
    "subnet1Name": {
        "value": "${azurerm_subnet.net-north-frontend.name}"
    },
    "subnet1Prefix": {
        "value": "${azurerm_subnet.net-north-frontend.address_prefixes[0]}"
    },
    "subnet2Name": {
        "value": "${azurerm_subnet.net-north-backend.name}"
    },
    "subnet2Prefix": {
        "value": "${azurerm_subnet.net-north-backend.address_prefixes[0]}"
    },
    "inboundSources": {
        "value": "0.0.0.0/0"
    },
    "waapAgentToken": {
        "value": "${var.infinity-token}"
    },
    "waapAgentFog": {
        "value": ""
    },
    "adminEmail": {
        "value": ""
    },
    "chooseVault": {
        "value": "none"
    },
    "existingKeyVaultRGName": {
        "value": "${azurerm_resource_group.rg-appsec-vmss.name}"
    },
    "keyVaultName": {
        "value": "vault-${var.appsec-name}"
    },
    "numberOfCerts": {
        "value": 0
    }
  }
  PARAMETERS 
  depends_on = [azurerm_resource_group.rg-appsec-vmss,azurerm_subnet.net-north-frontend,azurerm_subnet.net-north-backend]
}

resource "azurerm_dns_a_record" "juiceshop-prod-record" {
  name                = "juiceshop-prod"
  zone_name           = azurerm_dns_zone.mydns-public-zone.name
  resource_group_name = azurerm_resource_group.rg-dns-myzone.name
  ttl                 = 300
  records             = [jsondecode(azurerm_resource_group_template_deployment.template-deployment-appsec.output_content).applicationAddress.value]
  depends_on = [azurerm_resource_group_template_deployment.template-deployment-appsec]
}
resource "azurerm_dns_a_record" "juiceshop-staging-record" {
  name                = "juiceshop-staging"
  zone_name           = azurerm_dns_zone.mydns-public-zone.name
  resource_group_name = azurerm_resource_group.rg-dns-myzone.name
  ttl                 = 300
  records             = [jsondecode(azurerm_resource_group_template_deployment.template-deployment-appsec.output_content).applicationAddress.value]
  depends_on          = [azurerm_resource_group_template_deployment.template-deployment-appsec]
}

output "webapp-production-fqdn" {
    value = azurerm_dns_a_record.juiceshop-prod-record.fqdn
} 
output "webapp-staging-fqdn" {
    value = azurerm_dns_a_record.juiceshop-staging-record.fqdn
}