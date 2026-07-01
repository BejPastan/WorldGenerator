using System.Net.WebSockets;
using System.Runtime.CompilerServices;
using Microsoft.AspNetCore.SignalR;
using Python.Runtime;

namespace Testing.Controllers
{
    public class StreamingHub : Hub
    {

        private readonly ILogger<StreamingHub> _logger;
        private readonly IHubContext<StreamingHub> _hubContext;

        public StreamingHub(ILogger<StreamingHub> logger, IHubContext<StreamingHub> hubContext)
        {
            _logger = logger;
            _hubContext = hubContext;
        }

        string lastMessage = "";

        public async Task SendDataToServer(string incomingMessage)
        {
            _logger.LogInformation($"message recieved: {incomingMessage}");

            int a = 2;
            int b = 3;

            Runtime.PythonDLL = @"C:\ProgramData\miniforge3\python313.dll";
            PythonEngine.Initialize();

            using(Py.GIL())
            {
                dynamic sys = Py.Import("sys");
                sys.path.append($"{AppDomain.CurrentDomain.BaseDirectory}/Python");

                dynamic pyModule = Py.Import("calculating");

                dynamic pyResult = pyModule.add_number(a,b);

                int finalResult = (int)pyResult;

                _logger.LogInformation($"python result: {finalResult}");
            }

            PythonEngine.Shutdown();

            string response = $"recieved Message {incomingMessage}, and sending it back";
            //Context.Items["lastMessage"] = incomingMessage;
            await Clients.Caller.SendAsync("ReceiveStreamUpdate", response);

        }

        public override Task OnConnectedAsync()
        {
            //string connectionId = Context.ConnectionId;
            //CancellationToken disconnectToken = Context.ConnectionAborted;
            //var connectionItems = Context.Items;
            _logger.LogInformation($"Client connected");
            //_ = Task.Run(()=>PingingUser(_hubContext, connectionId, connectionItems, disconnectToken));
            return base.OnConnectedAsync();
        }

        private async Task PingingUser(IHubContext<StreamingHub> hubContext, string connectionId, IDictionary<object, object> items, CancellationToken cancellationToken)
        {
            while (!cancellationToken.IsCancellationRequested)
            {
                items.TryGetValue("lastMessage", out object value);
                if (value != null)
                {
                    string lastMessage = value.ToString();
                    await hubContext.Clients.Client(connectionId).SendAsync("ReceiveStreamUpdate", $"your last message: {lastMessage}");
                }
                await Task.Delay(1000);
            }
        }
    }
}
