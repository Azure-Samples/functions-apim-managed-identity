using Azure.Core;
using Azure.Identity;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Services.AppAuthentication;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using System;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Security.Principal;
using System.Threading.Tasks;

namespace PublicFunction
{
    public class Group
    {
        [FunctionName("group")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req, ILogger log)
        {
            log.LogInformation("Starting function call");

            // The client ID of the user assigned managed identity
            var clientId = Environment.GetEnvironmentVariable("ClientId");

            // The resource URI of the App Registration
            var targetAppUri = Environment.GetEnvironmentVariable("TargetAppUri");

            // The AzureAD tenant ID (only used in some of the examples)
            var tenantId = Environment.GetEnvironmentVariable("TenantId");
            
            // The subscription key (API Key) for Azure API Management (APIM)
            var apiKey = Environment.GetEnvironmentVariable("ApimKey");
            
            // The specific url and route to call in APIM (e.g. https://myapim.azure-api.net/demo/test)
            var apiUrl = $"{Environment.GetEnvironmentVariable("ApimUrl")}/trusted-group/test";
      
            log.LogInformation($"API Url: {apiUrl}");
            log.LogInformation($"App Uri: {targetAppUri}");

            var jwt = string.Empty;
            try
            {
                /*
                //Example of getting the token directly from the MSI endpoint
                var token = await GetToken(targetAppUri, "2017-09-01", clientId);
                var tokenString = await token.Content.ReadAsStringAsync();
                jwt = JsonConvert.DeserializeObject<dynamic>(tokenString).access_token;
                log.LogInformation($"Token from Direct MSI Call: {jwt}");
                */
                
                /*
                // Example of using the AzureServiceTokenProvider class to retrieve the managed identity
                var azureServiceTokenProvider = new AzureServiceTokenProvider($"RunAs=App;AppId={clientId}");
                jwt = await azureServiceTokenProvider.GetAccessTokenAsync(targetAppUri, tenantId);
                log.LogInformation($"Token from AzureServiceTokenProvider: {jwt}");
                */

                // If we are using a user assigned managed identity (as opposed to a system assigned managed identity) then we must provide the client ID
                var options = new DefaultAzureCredentialOptions();
                if(!string.IsNullOrWhiteSpace(clientId))
                {
                    options.ManagedIdentityClientId = clientId;
                }

                // Use the built in ManagedIdentityCredential class to retrieve the managed identity, filtering on client ID if user assigned. We could also use the DefaultAzureCredential class to make debugging simpler.
                var msiCredentials = new ManagedIdentityCredential(clientId); // DefaultAzureCredential(options);
                
                // Use the GetTokenAsync method to generate a JWT for use in a HTTP request
                var accessToken = await msiCredentials.GetTokenAsync(new TokenRequestContext(new[] { $"{targetAppUri}/.default" }));
                jwt = accessToken.Token;

                log.LogInformation("Got the JWT");
                log.LogInformation($"Token from ManagedIdentityCredential: {jwt}"); //NOTE: Don't log this in production! It is here for demo purposes only.
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

        
        //Example of getting the token directly from the MSI endpoint
        public static async Task<HttpResponseMessage> GetToken(string resource, string apiversion, string clientId)  
        {
            HttpClient client = new HttpClient();   
            client.DefaultRequestHeaders.Add("Secret", Environment.GetEnvironmentVariable("MSI_SECRET"));
            return await client.GetAsync(String.Format("{0}/?resource={1}&api-version={2}&clientid={3}", Environment.GetEnvironmentVariable("MSI_ENDPOINT"), resource, apiversion,clientId));
        }
        
    }
}


