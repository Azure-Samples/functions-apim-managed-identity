output "private_function_name" {
  value = azurerm_windows_function_app.private.name
}

output "public_untrusted_function_name" {
  value = azurerm_windows_function_app.public_untrusted.name
}

output "public_trusted_function_name" {
  value = azurerm_windows_function_app.public_trusted.name
}

output "public_untrusted_simple_demo_url" {
  value = "https://${azurerm_windows_function_app.public_untrusted.default_hostname}/api/simple"
}

output "public_untrusted_group_demo_url" {
  value = "https://${azurerm_windows_function_app.public_untrusted.default_hostname}/api/group"
}

output "public_trusted_simple_demo_url" {
  value = "https://${azurerm_windows_function_app.public_trusted.default_hostname}/api/simple"
}

output "public_trusted_group_demo_url" {
  value = "https://${azurerm_windows_function_app.public_trusted.default_hostname}/api/group"
}