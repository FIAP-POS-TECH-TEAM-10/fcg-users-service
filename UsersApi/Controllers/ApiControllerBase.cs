using MediatR;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace UsersApi.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public abstract class ApiControllerBase<T> : ControllerBase where T : class
    {
        protected readonly ILogger<T> _logger;
        protected readonly ISender _sender;
        protected ApiControllerBase(ISender sender, ILogger<T> logger)
        {
            _sender = sender;
            _logger = logger;
        }
    }
}
