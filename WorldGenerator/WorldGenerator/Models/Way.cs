namespace WorldGenerator.Models
{

    public class Way
    {
        public virtual Guid? Id { get; set; } = null;
        public string? Name { get; set; } = null;
    }

    public class NewWay
    {
        public string? Name { get; set; } = null;
        public List<Guid> Nodes_Ids { get; set; } = null;
    }

    /// <summary>
    /// Extended way data, with nodes, and tags
    /// </summary>
    public class WayExtended : Way
    {
        public override Guid? Id { get => id; 
            set
            {
                if(value == null)
                {
                    throw new ArgumentNullException("Id cannot be null");
                }
                id = value.Value;
            } 
        }
        public Guid id { get; set; }
        public List<Node> nodes {  get; set; } = [];
        public List<Tag> tags { get; set; } = [];
        public List<Traversal> traversal { get; set; } = [];
    }
}
