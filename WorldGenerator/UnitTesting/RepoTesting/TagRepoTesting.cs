using FluentAssertions;
using Microsoft.Extensions.Logging;
using Moq;
using NetTopologySuite.Geometries;
using System.Threading.Tasks;
using UnitTesting.IntegrationTests;
using WorldGenerator.Models;
using WorldGenerator.Repos;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

namespace UnitTesting.RepoTesting
{
    [Collection("Database collection")]
    public class TagRepoTesting
    {
        private IDBHandler _db;
        private TagRepo _tagRepo;
        private MapRepo _mapRepo;

        public TagRepoTesting(DbMockupContainer dbContainer)
        {
            var mockLogger = new Mock<ILogger<DBController>>();

            string testDbConnectionString = dbContainer._container.GetConnectionString();
            var fakeConnectionFactory = new Mock<IDBConnectionFactory>();
            fakeConnectionFactory.Setup(f => f.connectionString).Returns(testDbConnectionString);

            _db = new DBController(mockLogger.Object, fakeConnectionFactory.Object);
            var mockMapRepoLogger = new Mock<ILogger<MapRepo>>();
            var mockTagRepoLogger = new Mock<ILogger<TagRepo>>();
            _tagRepo = new TagRepo(_db, mockTagRepoLogger.Object);
            _mapRepo = new MapRepo(_db, mockMapRepoLogger.Object);
        }

        [Fact]
        public async Task TagRepoIntegrationTest_AddTagBatch_ReturnSuccess()
        {
            //Arrange

            var node = new NewNode(new Point(new Coordinate(0.015, 0.01))) { Name = "new_node" };
            var id = await _mapRepo.AddNode(node);

            node = new NewNode(new Point(new Coordinate(0.01, 0.015))) { Name = "new_node" };
            var id_2 = await _mapRepo.AddNode(node);

            var tagsToAdd = new List<Tag>
            {
                new NodeTag(){ Key="test", Value="1", ElementId=id},
                new NodeTag(){ Key="test", Value="1", ElementId=id_2},
            };
            //Act
            var resp = await _tagRepo.AddTagBatch(tagsToAdd);
            //Assert
            resp.Should().NotBeEmpty();
            resp.Count.Should().Be(tagsToAdd.Count);
        }

        [Fact]
        public async Task TagRepoIntegrationTest_AddTagBatch_EmptyList_ReturnSuccess()
        {
            //Arrange
            var tagsToAdd = new List<Tag>();
            //Act
            var resp = await _tagRepo.AddTagBatch(tagsToAdd);
            //Assert
            resp.Count.Should().Be(tagsToAdd.Count);
        }

        [Fact]
        public async Task TagRepoIntegrationTest_AddTagBatch_DifferentTypes_ThrowError()
        {
            //Arrange
            var node = new NewNode(new Point(new Coordinate(0.015, 0.01))) { Name = "new_node" };
            var id = await _mapRepo.AddNode(node);

            var tagsToAdd = new List<Tag>
            {
                new NodeTag(){ Key="test", Value="1", NodeId=new Guid("9ed6f024-2f02-45d7-a182-f1a32cb4f5f5")},
                new WayTag(){ Key="test", Value="1", ElementId=new Guid("9ed6f024-2f02-45d7-a182-f1a32cb4f5f5")},
            };
            //Act
            Func<Task> resp =async () => await _tagRepo.AddTagBatch(tagsToAdd);
            //Assert
            resp.Should().ThrowAsync<ArgumentException>();
        }
    }
}
