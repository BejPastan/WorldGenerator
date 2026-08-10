using Dapper;
using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using NetTopologySuite.Features;
using NetTopologySuite.Geometries;
using NetTopologySuite.Index.Bintree;
using NetTopologySuite.IO;
using Testcontainers.PostgreSql;
using UnitTesting.IntegrationTests;
using WorldGenerator.Models;
using WorldGenerator.Repos;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

namespace UnitTesting.RepoTesting
{
    [Collection("Database collection")]
    public class MapRepoIntegrationTesting
    {
        private IDBHandler _db;
        private MapRepo _mapRepo;

        public MapRepoIntegrationTesting(DbMockupContainer dbContainer)
        {
            var mockLogger = new Mock<ILogger<DBController>>();

            string testDbConnectionString = dbContainer._container.GetConnectionString();
            var fakeConnectionFactory = new Mock<IDBConnectionFactory>();
            fakeConnectionFactory.Setup(f => f.connectionString).Returns(testDbConnectionString);

            _db = new DBController(mockLogger.Object, fakeConnectionFactory.Object);
            var mockMapRepoLogger = new Mock<ILogger<MapRepo>>();
            _mapRepo = new MapRepo(_db, mockMapRepoLogger.Object);
        }

        [Fact]
        public async Task MapRepoIntegrationTest_AddNode_ReturnSuccess()
        {
            //Arrange
            var node = new NewNode(new Point(new Coordinate(0.01, 0.01))) { Name = "new_node" };
            //Act
            var resp = await _mapRepo.AddNode(node);
            //Assert
            resp.Should().NotBeEmpty();
        }

        [Fact]
        public async Task MapRepoIntegrationTest_AddWay_ReturnSuccess()
        {
            //Arrange
            var nodes_ids = new List<Guid>();

            var node = new NewNode(new Point(new Coordinate(0.015, 0.01))) { Name = "new_node" };
            var id = await _mapRepo.AddNode(node);
            nodes_ids.Add(id);

            node = new NewNode(new Point(new Coordinate(0.01, 0.015))) { Name = "new_node" };
            var id_2 = await _mapRepo.AddNode(node);
            nodes_ids.Add(id);

            var nodes = new List<Node>();
            nodes.Add(new NewNode(new Point(new Coordinate(0.01, 0.01))) { Name = "new_node" });
            nodes.Add(new NodeToReference(id));
            nodes.Add(new NodeToReference(id_2));
            nodes.Add(new NewNode(new Point(new Coordinate(0.01, 0.01))) { Name = "new_node" });
            var wayName = "TestWay";

            //Act
            var resp = await _mapRepo.AddWay(nodes, wayName);

            //Assert
            resp.Should().NotBeEmpty();;
        }

        [Fact]
        public async Task MapRepoIntegrationTest_AddNodesBatch_ReturnSuccess()
        {
            //Arrange
            var nodes = new List<NewNode>();
            nodes.Add(new NewNode(new Point(new Coordinate(0.01, 0.01))) { Name = "new_node" });
            nodes.Add(new NewNode(new Point(new Coordinate(0.015, 0.01))) { Name = "new_node" });
            nodes.Add(new NewNode(new Point(new Coordinate(0.01, 0.015))) { Name = "new_node" });
            //Act
            var resp = await _mapRepo.AddNodesBatch(nodes);
            //Assert
            resp.Should().NotBeEmpty();
            resp.Count.Should().Be(nodes.Count);
        }

        [Fact]
        public async Task MapRepoIntegrationTest_GetMapPart_ReturnSuccess()
        {
            //Arrange
            float minLat = 0;
            float maxLat = 0.01f;
            float minLng = -1;
            float maxLng = 1;
            int zoom = 10;
            //Act
            var response = await _mapRepo.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
            //Assert
            response.Should().NotBeNull();
            response.Should().BeOfType<FeatureCollection>();
        }

        [Fact]
        public async Task MapRepoIntegrationTest_GetMapPart_InvertedEnvelopeReturnSuccess()
        {
            //Arrange
            float minLat = 0;
            float maxLat = 0.01f;
            float minLng = 1;
            float maxLng = -1;
            int zoom = 10;
            //Act
            var response = await _mapRepo.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
            //Assert
            response.Should().NotBeNull();
            response.Should().BeOfType<FeatureCollection>();
        }

        [Fact]
        public async Task MapRepoIntegrationTest_GetMapPart_ZoomOutOfRangeThrowError()
        {
            //Arrange
            float minLat = 0;
            float maxLat = 0.01f;
            float minLng = -1;
            float maxLng = 1;
            int zoom = -10;
            //Act
            Func<Task> response = async () => await _mapRepo.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
            //Assert
            response.Should().ThrowAsync<ArgumentException>();
        }

        [Fact]
        public async Task MapRepoIntegrationTest_AddWaysBatch_ReturnSuccess()
        {
            //Arrange
            var nodes_ids = new List<Guid>();
            var node = new NewNode(new Point(new Coordinate(0.015, 0.01))) { Name = "new_node" };
            var id = await _mapRepo.AddNode(node);
            nodes_ids.Add(id);
            node = new NewNode(new Point(new Coordinate(0.01, 0.015))) { Name = "new_node" };
            var id_2 = await _mapRepo.AddNode(node);
            nodes_ids.Add(id);
            var ways = new List<NewWay>();
            var wayName = "TestWay";
            ways.Add(new NewWay()
            {
                Nodes_Ids = nodes_ids,
                Name = wayName
            });
            //Act
            var resp = await _mapRepo.AddWaysBatch(ways);
            //Assert
            resp.Should().NotBeEmpty();
            resp.Count.Should().Be(ways.Count);
        }
    }
}
