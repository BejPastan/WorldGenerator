using Dapper;

namespace WorldGenerator.Utils.Interfaces
{    
    public interface IDBHandler
    {
        public Task<IEnumerable<T>> MakeQuery<T>(string query, DynamicParameters parameters);
    }
}
