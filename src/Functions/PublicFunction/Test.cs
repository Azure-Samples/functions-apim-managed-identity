using Azure.Core;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Azure.Identity;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Net.Http.Headers;
using System.Threading.Tasks;

namespace PublicFunction
{
    public class Test
    {
        [FunctionName("test")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req, ILogger log)
        {
            log.LogInformation("C# HTTP trigger function processed a request.");

            var clientId = Environment.GetEnvironmentVariable("ClientId");
            var apiKey = Environment.GetEnvironmentVariable("ApimKey");
            var apiUrl = Environment.GetEnvironmentVariable("ApimUrl");
            log.LogInformation($"API Key: {apiKey}");
            log.LogInformation($"API Url: {apiUrl}");

            var jwt = string.Empty;
            try
            {
                var options = new DefaultAzureCredentialOptions();
                if(!string.IsNullOrWhiteSpace(clientId))
                {
                    options.ManagedIdentityClientId = clientId;
                }

                var msiCredentials = new DefaultAzureCredential(options);
                var accessToken = await msiCredentials.GetTokenAsync(new TokenRequestContext(new[] { "https://management.azure.com/.default" }));
                log.LogInformation($"Token: {accessToken.Token}");
                jwt = accessToken.Token;
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Error getting token");
            }
            
            var wc = new System.Net.Http.HttpClient();
            wc.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", jwt);
            wc.DefaultRequestHeaders.Add("Ocp-Apim-Subscription-Key", apiKey);
            var result = await wc.GetAsync(apiUrl);
            var content = await result.Content.ReadAsStringAsync();
            
            if (result.IsSuccessStatusCode)
            {
                var response = Newtonsoft.Json.JsonConvert.DeserializeObject<TestResponse>(content);
                return new OkObjectResult(response);
            }
            else
            {
                return new BadRequestObjectResult(content);
            }
        }
    }

    public class TestResponse
    {
        public string Message { get; set; }
        public DateTime DateOfMessage { get; set; }
    }

}


