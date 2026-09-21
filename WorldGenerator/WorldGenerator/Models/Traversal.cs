namespace WorldGenerator.Models
{
    public class Traversal
    {
        public Guid Id { get; set; }
        public Guid WayId { get; set; }
        /// <summary>
        /// spatial index of tile
        /// </summary>
        public long TileId { get; set; }

    }
}
