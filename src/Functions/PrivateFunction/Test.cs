using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Linq;
using System.Security.Claims;
using System.Threading.Tasks;

namespace PublicFunction
{
    public class Test
    {
        [FunctionName("test")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req, ILogger log)
        {
            log.LogInformation("Starting function call");

            var claims = req.HttpContext.User.Claims.ToList();
            claims.ForEach(c => log.LogInformation($"{c.Type} - {c.Value} - {c.ValueType}"));

            var roleClaim = claims.Single(c => c.Type == "roles");
            log.LogInformation($"Role Claim: {roleClaim.Type} - {roleClaim.Value} - {roleClaim.ValueType}");
            
            return new OkObjectResult(new TestResponse { 
                DateOfMessage = DateTime.Now, 
                Message = $"Hello from the Private Function! The APIM Managed Identity has been assigned to the role: {roleClaim.Value}" 
            });
        }
    }
}

public class TestResponse
{
    public string Message { get; set; }
    public DateTime DateOfMessage { get; set; }
}