using Microsoft.Extensions.Configuration;
using System.Reflection;
using WorldGenerator.Repos.Interfaces;

namespace WorldGenerator.Repos
{
    public class LocalSecretRepo(IConfiguration config, ILogger<LocalSecretRepo> logger) : ISecretRepo
    {
        readonly IConfiguration _config = config;
        readonly ILogger _logger = logger;
        string connectionString = "";

        public string GetConnectionString()
        {
            _logger.LogInformation("Getting connection string");

            if(!string.IsNullOrWhiteSpace(connectionString))
            {
                return connectionString;
            }

            string? dbName = _config.GetRequiredSection("DBConnection:dbName").Value;
            string? url = _config.GetRequiredSection("DBConnection:url").Value;
            string? port = _config.GetRequiredSection("DBConnection:port").Value;
            string? pass = _config.GetRequiredSection("DBConnection:pass").Value;
            string? userName = _config.GetRequiredSection("DBConnection:username").Value;

            connectionString = $"Host={url};Port={port};Database={dbName};Username={userName};Password={pass};";

            return connectionString;
        }
    }
}
