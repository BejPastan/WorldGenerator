using Moq;
using Testcontainers.PostgreSql;
using WorldGenerator.Repos.Interfaces;

namespace UnitTesting.IntegrationTests
{
    public class DbMockupContainer : IAsyncLifetime
    {
        public PostgreSqlContainer _container { get; private set; }

        public async Task InitializeAsync()
        {
            var sqlPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "db.sql");

            if (!File.Exists(sqlPath))
            {
                throw new FileNotFoundException($"SQL file not found at path: {sqlPath}");
            }

            _container = new PostgreSqlBuilder("postgis/postgis:17-3.5-alpine")
                .WithBindMount(sqlPath, "/docker-entrypoint-initdb.d/init.sql")
                .Build();
                await _container.StartAsync();
                //string connectionString = _container.GetConnectionString();
                //var fakeConnectionFactory = new Mock<IDBConnectionFactory>();
                //fakeConnectionFactory.Setup(f => f.GetConnectionString()).Returns(connectionString);
        }

        public async Task DisposeAsync()
        {
            await _container.DisposeAsync();
        }
    }

    [CollectionDefinition("Database collection")]
    public class DatabaseCollection : ICollectionFixture<DbMockupContainer>
    {

    }
}
