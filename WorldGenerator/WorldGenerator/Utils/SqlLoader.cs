using System.Reflection;
using WorldGenerator.Utils.Interfaces;

namespace WorldGenerator.Utils
{
    public class SqlLoader
    {
        public static string Load(string fileName)
        {
            var assmebly = Assembly.GetExecutingAssembly();

            string resoueceName = assmebly.GetManifestResourceNames().FirstOrDefault(str => str.EndsWith(fileName)) ?? throw new FileNotFoundException("Could not find file");

            using Stream stream = assmebly.GetManifestResourceStream(resoueceName);
            using StreamReader sr = new StreamReader(stream);

            return sr.ReadToEnd();
        }
    }
}
