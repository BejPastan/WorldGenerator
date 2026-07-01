using Microsoft.AspNetCore.Mvc;
using System.Threading.Tasks;
using WorldGenerator.Models;
using WorldGenerator.Services.Interfaces;

namespace WorldGenerator.Controllers
{
    [ApiController]
    [Route("api/map")]
    public class MapController(IMapService mapService) : Controller
    {
        readonly IMapService _mapService = mapService;


        /// <summary>
        /// Return part of map
        /// </summary>
        /// <param name="minLat"></param>
        /// <param name="maxLat"></param>
        /// <param name="minLng"></param>
        /// <param name="maxLng"></param>
        /// <param name="zoom">zoom level</param>
        /// <param name="type">type of map, allowed values: geojson, tile, default type is tile</param>
        /// <returns></returns>
        [HttpGet("{type}")]
        public async Task<IActionResult> GetGeoJson([FromQuery]float minLat, [FromQuery] float maxLat, [FromQuery] float minLng, [FromQuery] float maxLng, [FromQuery] int zoom, [FromRoute]MapType type = MapType.tile)
        {
            if(type == MapType.geojson)
            {
                var result = await _mapService.GetMapPart(minLat, maxLat, minLng, maxLng, zoom);
                return Ok(result);
            }
            else
            {
                throw new NotImplementedException("tile mode is not implemented yet, please use geojson mode");
            }
        }
    }
}
