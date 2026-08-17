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
        public async Task MapRepoIntegration_GetWay_ReturnWay()
        {
            //Arrange
            var wayId = await AddTestWays(1);

            //Act
            var resp = await _mapRepo.GetWay(wayId[0]);

            //Assert
            resp.Id.Value.Should().Be(wayId[0]);
        }

        [Fact]
        public async Task MapRepoIntegrationTest_AddWay_ReturnSuccess()
        {
            //Arrange
            var nodes_ids = await AddTestNodes(2);



            var nodes = new List<Node>
            {
                new NewNode(new Point(new Coordinate(0.01, 0.01))) { Name = "new_node" },
                new NodeToReference(nodes_ids[0]),
                new NodeToReference(nodes_ids[1]),
                new NewNode(new Point(new Coordinate(0.01, 0.01))) { Name = "new_node" }
            };
            var wayName = "TestWay";

            //Act
            var resp = await _mapRepo.AddWay(nodes, wayName);

            //Assert
            resp.Should().NotBeEmpty(); ;
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
            var nodes_ids = await AddTestNodes(2);
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

        [Fact]
        public async Task MapRepoIntegrationTest_AddRelationsBatch_ReturnSuccess()
        {
            //Arrange
            var ways_ids = await AddTestWays(2);
            var relations = new List<NewRelation>();
            var elements = new List<NewRelationElement>();
            foreach (var wayId in ways_ids)
            {
                elements.Add(new NewRelationElement()
                {
                    Way_Id = wayId,
                    Type = true
                });
            }
            var relationName = "TestRelation";
            relations.Add(new NewRelation()
            {
                Elements = elements,
                Name = relationName
            });
            //Act
            var resp = await _mapRepo.AddRelationsBatch(relations);
            //Assert
            resp.Should().NotBeEmpty();
            resp.Count.Should().Be(relations.Count);
        }

        [Fact]
        private async Task MapRepoIntegrationTest_GetWay_ReturnWay()
        {
            //Arrange
            var wayId = await AddTestWays(1);

            //Act
            var way = await _mapRepo.GetWay(wayId[0]);

            //Assert
            way.Should().NotBeNull();
            way.Id.Should().Be(wayId[0]);
            way.nodes.Should().NotBeNull();
        }

        [Fact]
        private async Task MapRepoIntegrationTest_GetWayWayNotExist_ReturnNull()
        {
            //Arrange
            var wayId = Guid.CreateVersion7();

            //Act
            var way = await _mapRepo.GetWay(wayId);

            //Assert
            way.Should().BeNull();
        }

        [Fact]
        private async Task MapRepoIntegratioTest_GetNode_ReturnNode()
        {
            //Arrange
            var nodeId = await AddTestNodes(1);

            //Act
            var node = await _mapRepo.GetNode(nodeId[0]);

            //Assert
            node.Id.Should().Be(nodeId[0]);
        }

        [Fact]
        private async Task MapRepoIntegratioTest_GetNodeNodeNotExist_ReturnNull()
        {
            //Arrange
            var nodeId = Guid.CreateVersion7();

            //Act
            var node = await _mapRepo.GetNode(nodeId);

            //Assert
            node.Should().BeNull();
        }

        [Fact]
        private async Task MapRepoIntegrationTest_DeleteNode_ReturnSuccess()
        {
            //Arrange
            var nodeId = await AddTestNodes(1);

            //Act
            var resp = await _mapRepo.DeleteNode(nodeId[0]);

            //Assert
            var node = await _mapRepo.GetNode(nodeId[0]);
            resp.Should().BeTrue();
            node.Should().BeNull();
        }

        [Fact]
        private async Task MapRepoIntegrationTest_DeleteNode_UpdateWayTiles()
        {
            //Arrange
            var node = new NewNode(new Point(new Coordinate(-10.0f, 0.01))) { Name = "new_node" };
            var toDelete = await _mapRepo.AddNode(node);
            List<Guid> nodesIds = [toDelete];
            nodesIds.AddRange(await AddTestNodes(3));
            var waysIds = await AddTestWays(1, [nodesIds]);
            var oldData = await _mapRepo.GetWay(waysIds[0]);

            //Act
            var resp = await _mapRepo.DeleteNode(nodesIds[0]);

            //Assert
            var way = await _mapRepo.GetWay(waysIds[0]);
            resp.Should().BeTrue();

            way.nodes[0].Id.Should().Be(nodesIds[1]);
            way.traversal.Should().NotBeEquivalentTo(oldData.traversal);
        }

        private async Task MapRepoIntegrationTest_EditNode_ReturnNode()
        {
            //Arrange
            var point = new Point(new Coordinate(-10.0f, 0.01));
            var node = new NewNode(point) { Name = "test_node" };
            var toEdit = await _mapRepo.AddNode(node);
            List<Guid> nodesIds = [toEdit];
            nodesIds.AddRange(await AddTestNodes(3));
            var waysIds = await AddTestWays(1, [nodesIds]);
            var oldData = await _mapRepo.GetWay(waysIds[0]);

            UpdateNode update = new(toEdit) { Name = "edited_name" };

            //Act
            var resp = await _mapRepo.EditNode(update);

            //Assert
            resp.Name.Should().Be("edited_name");
            resp.Geom.Should().BeEquivalentTo(point);
        }

        [Fact]
        private async Task MapRepoIntegrationTest_EditNode_UpdateWayTiles()
        {
            //Arrange
            var node = new NewNode(new Point(new Coordinate(-10.0f, 0.01))) { Name = "test_node" };
            var toEdit = await _mapRepo.AddNode(node);
            List<Guid> nodesIds = [toEdit];
            nodesIds.AddRange(await AddTestNodes(3));
            var waysIds = await AddTestWays(1, [nodesIds]);
            var oldData = await _mapRepo.GetWay(waysIds[0]);

            Point newGeom = new Point(new Coordinate(0.0f, 0.0));
            UpdateNode update = new(toEdit) { Geom = newGeom };

            //Act
            var resp = await _mapRepo.EditNode(update);

            //Assert
            var way = await _mapRepo.GetWay(waysIds[0]);
            resp.Name.Should().Be(node.Name);
            resp.Geom.Should().BeEquivalentTo(newGeom);
            way.traversal.Should().NotBeEquivalentTo(oldData.traversal);
        }

        /// <summary>
        /// Add test nodes to the database and return their ids
        /// </summary>
        /// <param name="num"></param>
        /// <returns></returns>
        private async Task<List<Guid>> AddTestNodes(int num)
        {
            List<Guid> ids = [];
            for (int i = 0; i < num; i++)
            {
                var node = new NewNode(new Point(new Coordinate(0.01*i, 0.01*((i%2)-2)))) { Name = "new_node" };
                var resp = await _mapRepo.AddNode(node);
                ids.Add(resp);
            }
            return ids;
        }

        /// <summary>
        /// Add few test ways to the database and return their ids. Each way will consist of 3 nodes. and is closed polygon
        /// </summary>
        /// <param name="num"></param>
        /// <returns></returns>
        private async Task<List<Guid>> AddTestWays(int num, List<List<Guid>>? nodesIds = null)
        {
            List<Guid> ids = [];
            List<Guid> nodes_ids;
            int existingListCount = nodesIds?.Count ?? 0;
            for (int i = 0; i < num; i++)
            {
                if(i<existingListCount)
                {
                    nodes_ids = nodesIds[i];
                }
                else
                {
                    nodes_ids = await AddTestNodes(3);
                }
                var nodes = new List<Node>();
                nodes.Add(new NodeToReference(nodes_ids[0]));
                nodes.Add(new NodeToReference(nodes_ids[1]));
                nodes.Add(new NodeToReference(nodes_ids[2]));
                nodes.Add(new NodeToReference(nodes_ids[0]));
                var wayName = $"TestWay_{i}";
                var resp = await _mapRepo.AddWay(nodes, wayName);
                ids.Add(resp);
            }
            return ids;
        }
    }
}
