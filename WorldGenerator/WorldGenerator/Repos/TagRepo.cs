using Dapper;
using System.Text.Json;
using WorldGenerator.Models;
using WorldGenerator.Repos.Interfaces;
using WorldGenerator.Utils;
using WorldGenerator.Utils.Interfaces;

namespace WorldGenerator.Repos
{
    public class TagRepo(IDBHandler dBHandler, ILogger<TagRepo> logger) : ITagRepo
    {
        IDBHandler _db = dBHandler;
        ILogger _logger = logger;

        public async Task<List<Guid>> AddTagBatch<T>(List<T> toAdd) where T : Tag
        {
            if(toAdd.Count == 0)
            {
                return new List<Guid>();
            }
            if(toAdd.Select(x=>x.GetType()).Distinct().Count() > 1)
            {
                throw new ArgumentException("All elements in the list must be of the same type.");
            }
            string tableName = toAdd.FirstOrDefault().ElementType.ToString();
            var sql = new Lazy<string>(() => SqlLoader.Load("AddBatchTags.sql"));
            string finalSql = sql.Value.Replace("<name>", tableName);
            DynamicParameters param = new();
            var json = JsonSerializer.Serialize(toAdd);
            param.Add("objects_array", json);
            var result = await _db.MakeQuery<Guid>(finalSql, param);
            return result.ToList();
        }
    }
}
