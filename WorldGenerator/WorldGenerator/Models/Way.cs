namespace WorldGenerator.Models
{

    public class Way
    {
        public Guid? Id { get; set; } = null;
        public string ? Name { get; set; } = null;
    }

    public class NewWay
    {
        public string? Name { get; set; } = null;
        public List<Guid> Nodes_Ids { get; set; } = null;
    }
}
