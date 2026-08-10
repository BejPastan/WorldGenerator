
using FluentAssertions;
using Moq;
using WorldGenerator.Repos;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Services;

namespace UnitTesting.ServiceTesting
{
    public class MapGenerationServiceTesting
    {
        [Fact]
        public async Task MapGenerationService_GenerateTectonicPlates_ReturnSuccess()
        {
            //Arrange
            var pythonSettings = new Mock<IPythonSetting>();
            pythonSettings.Setup(f => f.GetPythonPath()).Returns("C:\\ProgramData\\miniforge3\\python313.dll");

            PythonFeatcher featcher = new PythonFeatcher(pythonSettings.Object);

            MapGenerator mapGenerator = new MapGenerator(featcher);

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
