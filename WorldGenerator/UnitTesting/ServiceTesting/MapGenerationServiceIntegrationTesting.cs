
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using UnitTesting.IntegrationTests;
using WorldGenerator.Repos;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Services;
using WorldGenerator.Services.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

namespace UnitTesting.ServiceTesting
{
    [Collection("Database collection")]
    public class MapGenerationServiceIntegrationTesting
    {
        IDBHandler _db;
        IMapService _mapeService;

        public MapGenerationServiceIntegrationTesting(DbMockupContainer dbContainer)
        {
            var mockLogger = new Mock<ILogger<DBController>>();
            string testDbConnectionString = dbContainer._container.GetConnectionString();
            var fakeConnectionFactory = new Mock<IDBConnectionFactory>();
            fakeConnectionFactory.Setup(f => f.connectionString).Returns(testDbConnectionString);
            _db = new DBController(mockLogger.Object, fakeConnectionFactory.Object);
            var mockMapRepoLogger = new Mock<ILogger<MapRepo>>();
            var _mapRepo = new MapRepo(_db, mockMapRepoLogger.Object);
            var mockMapServiceLogger = new Mock<ILogger<MapService>>();

            _mapeService = new MapService(mockMapServiceLogger.Object, _mapRepo);
        }

        [Fact]
        public async Task MapGenerationServiceIntegration_GenerateTectonicPlates_ReturnSuccess()
        {
            //Arrange
            var pythonSettings = new Mock<IPythonSetting>();
            pythonSettings.Setup(f => f.GetPythonPath()).Returns("C:\\ProgramData\\miniforge3\\python313.dll");

            PythonFeatcher featcher = new PythonFeatcher(pythonSettings.Object);

            MapGenerator mapGenerator = new MapGenerator(featcher, _mapeService);

            int platesNum = 15;
            int segmentsNum = 10000;
            float planetSize = 1.0f;

            //Act
            var resp = await mapGenerator.GenerateTectonicPlates(platesNum, segmentsNum, planetSize);

            //Assert
            resp.Count().Should().Be(segmentsNum);      
        }
    }
}
