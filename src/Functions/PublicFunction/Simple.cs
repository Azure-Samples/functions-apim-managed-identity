using Azure.Core;
using Azure.Identity;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace PublicFunction
{
    public class Simple
    {
        [FunctionName("simple")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req, ILogger log)
        {
            log.LogInformation("Starting function call");

            // The client ID of the user assigned managed identity
            var clientId = Environment.GetEnvironmentVariable("ClientId");
            
            // The subscription key (API Key) for Azure API Management (APIM)
            var apiKey = Environment.GetEnvironmentVariable("ApimKey");
            
            // The specific url and route to call in APIM (e.g. https://myapim.azure-api.net/demo/test)
            var apiUrl = $"{Environment.GetEnvironmentVariable("ApimUrl")}/trusted-simple/test";
      
            log.LogInformation($"API Url: {apiUrl}");

            var jwt = string.Empty;
            try
            {
                // If we are using a user assigned managed identity (as opposed to a system assigned managed identity) then we must provide the client ID
                var options = new DefaultAzureCredentialOptions();
                if(!string.IsNullOrWhiteSpace(clientId))
                {
                    options.ManagedIdentityClientId = clientId;
                }

                // Use the built in DefaultAzureCredential class to retrieve the managed identity, filtering on client ID if user assigned
                var msiCredentials = new DefaultAzureCredential(options);
                
                // Use the GetTokenAsync method to generate a JWT for use in a HTTP request
                var accessToken = await msiCredentials.GetTokenAsync(new TokenRequestContext(new[] { "https://management.azure.com/.default" }));
                jwt = accessToken.Token;
                log.LogInformation("Got the JWT");
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Error getting token");
            }
                        
            var wc = new System.Net.Http.HttpClient();
            
            // Add the JWT to the request headers as a bearer token (this is the default for the `validate-azure-ad-token` policy, but you could override it and use a different header)
            wc.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwt);
            
            // Add the Subscription Key (API Key) to the request headers (this is the default header name in APIM, but it can be overridden if needed)
            wc.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apiKey);
            
            // Call the APIM end point and get the body of the response
            var result = await wc.GetAsync(apiUrl);
            var content = await result.Content.ReadAsStringAsync();
            log.LogInformation("Completed the APIM call");
            
            if (result.IsSuccessStatusCode)
            {
                var response = JsonConvert.DeserializeObject<TestResponse>(content);
                return new OkObjectResult(response);
            }
            else
            {
                log.LogError($"Error making API call: {content}");
                return new BadRequestObjectResult(content);
            }
        }
    }
}


