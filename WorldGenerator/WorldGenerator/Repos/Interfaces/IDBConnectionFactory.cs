namespace WorldGenerator.Repos.Interfaces
{
    public interface IDBConnectionFactory
    {
        string GetConnectionString(); 
        public string connectionString { get; }
    }
}
