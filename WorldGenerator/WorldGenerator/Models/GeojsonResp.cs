namespace WorldGenerator.Models
{
    public class GeojsonResp
    {
        public string Resp { get; set; } = string.Empty;
    }

    public class IdResp
    {
        public string Id { get; set; } = string.Empty;
    }

    public enum MapType
    {
        geojson,
        tile
    }
}
