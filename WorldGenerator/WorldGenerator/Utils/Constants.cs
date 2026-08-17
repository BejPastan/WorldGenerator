namespace WorldGenerator.Utils
{
    public class Constants
    {
        public static int MIN_ZOOM { get; private set; } = 0;
        public static int MAX_ZOOM { get; private set; } = 18;//cannot be greater then 32 due to max size of tile_id in traversal
        public static string GEO_SYSTEM { get; private set; } = "4326";

        public static int PLATE_INPUT_BATCH { get; private set; } = 1000;
    }
}
