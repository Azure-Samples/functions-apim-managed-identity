using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace PublicFunction
{
    public class Test
    {
        [FunctionName("test")]
        public static async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)] HttpRequest req, ILogger log)
        {
            log.LogInformation("Starting function call");
            return new OkObjectResult(new TestResponse { DateOfMessage = DateTime.Now, Message = "Hello from the Private Function!" });
        }
    }
}

public class TestResponse
{
    public string Message { get; set; }
    public DateTime DateOfMessage { get; set; }
}