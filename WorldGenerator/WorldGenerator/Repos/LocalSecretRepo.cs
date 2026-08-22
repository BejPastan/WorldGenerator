using Microsoft.Extensions.Configuration;
using System;
using System.Reflection;
using WorldGenerator.Repos.Interfaces;

namespace WorldGenerator.Repos
{
    public class LocalSecretRepo : IDBConnectionFactory, IPythonSetting
    {
        public LocalSecretRepo(IConfiguration config, ILogger<LocalSecretRepo> logger)
        {
            _logger = logger;
            _config = config;
            DbName = _config.GetRequiredSection("DBConnection:dbName").Value ?? "";
            DbUrl = _config.GetRequiredSection("DBConnection:url").Value ?? "";
            DbPort = _config.GetRequiredSection("DBConnection:port").Value ?? "";
            DbPass = _config.GetRequiredSection("DBConnection:pass").Value ?? "";
            DbUserName = _config.GetRequiredSection("DBConnection:username").Value ?? "";
            _logger.LogInformation("Database settings initialized");
            PythonPath = _config.GetRequiredSection("PythonSettings:path").Value ?? "";
            _logger.LogInformation("Python settings initialized");
        }

        readonly IConfiguration _config;
        readonly ILogger _logger;

        #region DataBase
        public string DbName { get; private set; } = "";
        public string DbPass { get; private set; } = "";
        public string DbUserName { get; private set; } = "";
        public string DbUrl { get; private set; } = "";
        public string DbPort { get; private set; } = "";
        public string connectionString
        {
            get => $"Host={DbUrl};Port={DbPort};Database={DbName};Username={DbUserName};Password={DbPass};";
            private set;
        }

        public string GetConnectionString()
        {
            _logger.LogInformation("Getting connection string");
            return connectionString;
        }
        #endregion


        #region PYTHON
        public string PythonPath { get; private set; }

        public string GetPythonPath()
        {
            return PythonPath;
        }
        #endregion
    }
}
