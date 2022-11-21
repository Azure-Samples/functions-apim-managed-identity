locals {
  powershell_deploy = <<EOT
    $functionAppName = "%s"
    while ($result -eq $null -or $result.StartsWith("Can't find app with name"))
    {
      Write-Host "Waiting for function app to be created"
      try
      {
        $result = func azure functionapp list-functions $functionAppName --show-keys 
      }
      catch
      {
        $result = $null
      }
    }
    Write-Host "Found the function app, deploying the code now..."
    try
    {
        $result = func azure functionapp publish $functionAppName --csharp
    }
    catch
    {
        Write-Host "At least one error occurred when publishing function app"
    }
    exit 0
  EOT
}