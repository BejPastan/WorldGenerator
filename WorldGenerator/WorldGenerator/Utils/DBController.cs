using Dapper;
using Npgsql;
using Slapper;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils.Interfaces;

namespace WorldGenerator.Utils
{
    public class DBController : IDBHandler
    {
        readonly string CONNECTION_STRING = "";

        readonly NpgsqlDataSource dataSource;
        readonly ILogger _logger;

        public DBController(ILogger<DBController> logger, IDBConnectionFactory secretRepo)
        {
            CONNECTION_STRING = secretRepo.connectionString;
            var dataSourceBuilder = new NpgsqlDataSourceBuilder(CONNECTION_STRING);
            dataSourceBuilder.UseNetTopologySuite();
            dataSource = dataSourceBuilder.Build();
            _logger = logger;
            _logger.LogInformation("DB data source created");
            Dapper.DefaultTypeMap.MatchNamesWithUnderscores = true;
            
        }


        /// <summary>
        /// Make query and return obejcts, for standard object use MakeQuery
        /// </summary>
        /// <typeparam name="T">Type of output obejcts</typeparam>
        /// <param name="query">sql string</param>
        /// <param name="parameters">parameters for query</param>
        /// <returns></returns>
        public async Task<IEnumerable<T>> MakeQuery<T>(string query, DynamicParameters parameters)
        {
            _logger.LogInformation($"Executing Query: {query}");
            var conn = dataSource.CreateConnection();

            return await conn.QueryAsync<T>(query, parameters);
        }

        /// <summary>
        /// Make query and return nested obejcts, for standard object use MakeQuery
        /// </summary>
        /// <typeparam name="T">Type of output obejcts</typeparam>
        /// <param name="query">sql string</param>
        /// <param name="parameters">parameters for query</param>
        /// <returns></returns>
        public async Task<IEnumerable<T>> MakeNestedQuery<T>(string query, DynamicParameters parameters)
        {
            _logger.LogInformation($"Executing nested query: {query}");
            var conn = dataSource.CreateConnection();
            IEnumerable<dynamic> rawRows = await conn.QueryAsync<dynamic>(query, parameters);
            var dictionaryRows = rawRows.Select(row => (IDictionary<string, object>)row);
            var resp = AutoMapper.MapDynamic<T>(dictionaryRows);//here
            return resp;
        }
    }
}
