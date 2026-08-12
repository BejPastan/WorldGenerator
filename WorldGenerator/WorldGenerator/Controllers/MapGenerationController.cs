using Microsoft.AspNetCore.SignalR;
using WorldGenerator.Models;
using WorldGenerator.Services;
using WorldGenerator.Services.Interfaces;

namespace WorldGenerator.Controllers
{

    public class MapGenerationController : Hub
    {
        private readonly ILogger<MapGenerationController> _logger ;
        private readonly IHubContext<MapGenerationController> _hubContext;
        private readonly IMapGenerator _mapGenerator;

        public MapGenerationController(ILogger<MapGenerationController> logger, IHubContext<MapGenerationController> hubContext, IMapGenerator mapGenerator)
        {
            _logger = logger;
            _hubContext = hubContext;
            _mapGenerator = mapGenerator;

            _mapGenerator.progressMessage += SendProgressUpdate;
        }

        private void SendProgressUpdate(ProgressMessage message, string connectionId)
        {
            Clients.Client(connectionId).SendAsync("ReceiveProgressUpdate", message);
        }

        public override Task OnConnectedAsync()
        {
            return base.OnConnectedAsync();
        }

        public override Task OnDisconnectedAsync(Exception? exception)
        {
            return base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Websocket endpoint for generating map, it will send progress updates to the client
        /// </summary>
        /// <param name="incomingMessage"></param>
        /// <returns></returns>
        public async Task GenerateMap(PlateGenerationRequest request)
        {
            
        }
    }
}
