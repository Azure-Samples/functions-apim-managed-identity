output "private_function_name" {
  value = azurerm_windows_function_app.private.name
}

output "public_untrusted_function_name" {
  value = azurerm_windows_function_app.public_untrusted.name
}

output "public_trusted_function_name" {
  value = azurerm_windows_function_app.public_trusted.name
}

output "public_untrusted_demo_url" {
  value = "https://${azurerm_windows_function_app.public_untrusted.default_hostname}/api/test"
}

output "public_trusted_demo_url" {
  value = "https://${azurerm_windows_function_app.public_trusted.default_hostname}/api/test"
}

output "deploy_script" {
  value = <<EOF
cd src/Functions/PrivateFunction
func azure functionapp publish ${azurerm_windows_function_app.private.name} --csharp
cd ../PublicFunction
func azure functionapp publish ${azurerm_windows_function_app.public_untrusted.name} --csharp
func azure functionapp publish ${azurerm_windows_function_app.public_trusted.name} --csharp
cd ../../..
EOF
}