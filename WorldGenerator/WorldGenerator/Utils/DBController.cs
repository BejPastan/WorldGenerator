using Dapper;
using Npgsql;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils.Interfaces;

namespace WorldGenerator.Utils
{
    public class DBController : IDBHandler
    {
        readonly string CONNECTION_STRING = "";

        readonly NpgsqlDataSource dataSource;
        readonly ILogger _logger;

        public DBController(ISecretRepo secretRepo, ILogger<DBController> logger)
        {
            CONNECTION_STRING = secretRepo.GetConnectionString();
            dataSource = NpgsqlDataSource.Create(CONNECTION_STRING);
            _logger = logger;
            _logger.LogInformation("DB data source created");
        }

        public async Task<IEnumerable<T>> MakeQuery<T>(string query, DynamicParameters parameters)
        {
            _logger.LogInformation($"Executing Query: {query}");
            var conn = dataSource.CreateConnection();
            return await conn.QueryAsync<T>(query, parameters);
        }
    }
}
