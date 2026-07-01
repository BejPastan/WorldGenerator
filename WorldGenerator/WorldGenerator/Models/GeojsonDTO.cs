namespace WorldGenerator.Models
{
    public class GeojsonDTO
    {
        public string Resp { get; set; } = string.Empty;
    }

    public enum MapType
    {
        geojson,
        tile
    }
}
