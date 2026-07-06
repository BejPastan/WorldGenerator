using Microsoft.Extensions.Configuration;
using System;
using System.Reflection;
using WorldGenerator.Repos.Interfaces;

namespace WorldGenerator.Repos
{
    public class LocalSecretRepo : IDBConnectionFactory
    {
        public LocalSecretRepo(IConfiguration config, ILogger<LocalSecretRepo> logger)
        {
            _logger = logger;
            _config = config;
            _logger.LogInformation("LocalSecretRepo initialized");
            dbName = _config.GetRequiredSection("DBConnection:dbName").Value ?? "";
            dbUrl = _config.GetRequiredSection("DBConnection:url").Value ?? "";
            dbPort = _config.GetRequiredSection("DBConnection:port").Value ?? "";
            dbName = _config.GetRequiredSection("DBConnection:pass").Value ?? "";
            dbUserName = _config.GetRequiredSection("DBConnection:username").Value ?? "";
            _logger.LogInformation($"DB Connection Info: dbName={dbName}, dbUrl={dbUrl}, dbPort={dbPort}, dbUserName={dbUserName}");
        }

        readonly IConfiguration _config;
        readonly ILogger _logger;

        public string dbName { get; private set; } = "";
        public string dbPass { get; private set; } = "";
        public string dbUserName { get; private set; } = "";
        public string dbUrl { get; private set; } = "";
        public string dbPort { get; private set; } = "";
        public string connectionString
        {
            get => $"Host={dbUrl};Port={dbPort};Database={dbName};Username={dbUserName};Password={dbPass};";
            private set;
        }

        public string GetConnectionString()
        {
            _logger.LogInformation("Getting connection string");
            return connectionString;
        }
    }
}
