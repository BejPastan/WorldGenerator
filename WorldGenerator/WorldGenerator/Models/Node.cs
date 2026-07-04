using NetTopologySuite.Geometries;

using System.ComponentModel.DataAnnotations.Schema;

namespace WorldGenerator.Models
{
    /// <summary>
    /// Base node class
    /// </summary>
    public class Node
    {
        public string? Id { get; set; } = null;
        public string? Name { get; set; } = null;
        public string? TileId { get; set; } = null;
        [Column(TypeName = "geography")]
        public Point? Geom { get; set; } = null;
    }

    /// <summary>
    /// Class used for adding new nodes to DB
    /// </summary>
    public class NewNode(Point point) : Node
    {
        new public string Name { get; set; } = string.Empty;
        new public Point Geom { get; set; } = point;


    }

    /// <summary>
    /// Class used for adding new ways, as existing node
    /// </summary>
    public class ExistingNode(string id) : Node
    {
        new public string Id { get; set; } = id;
    }
}
