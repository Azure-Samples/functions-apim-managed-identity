      $result = func azure functionapp list-functions fn-apim-mi-demo-private --show-keys -ErrorAction SilentlyContinue
      while ($result -eq $null -or $result.StartsWith("Can't find app with name"))
      {
        Write-Host "Waiting for function app to be created"
        $result = func azure functionapp list-functions fn-apim-mi-demo-private --show-keys -ErrorAction SilentlyContinue
      }
      func azure functionapp publish ${azurerm_windows_function_app.private.name} --csharp -ErrorAction SilentlyContinue