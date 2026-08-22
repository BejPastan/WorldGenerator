import { Map } from "./Map";
import { httpGet } from "../lib/services/httpService";
import { useRef, useState } from "react";
import { FeatureGroup } from "leaflet";

export function MapController(){
    const [ geojsonData, setGeojsonData ]= useState<FeatureGroup|null>(null);
    const bboxRef = useRef("");

    async function fetchData(bouds:any, zoom:number){
        var params = {
            "maxLat": bouds.northEast.lat,
            "maxLng": bouds.northEast.lng,
            "minLat": bouds.southWest.lat,
            "minLng": bouds.southWest.lng,
            "zoom": zoom
        }
        var response = await httpGet<FeatureGroup>("/api/map/geojson", params);
        setGeojsonData(response);
    }

    const handleBboxChange = (newBbox:any, newZoom:number) => {
        if(bboxRef.current === JSON.stringify(newBbox)){
            return;
        }   
        bboxRef.current = JSON.stringify(newBbox);
        console.log("New bbox: ", newBbox, "new zoom: ", newZoom);
        fetchData(newBbox, newZoom);
    }

    const jsonTest = {
    "type": "FeatureCollection",
    "features": [
        {
            "type": "Feature",
            "geometry": {
                "type": "LineString",
                "coordinates": [
                    [
                        -178,
                        0
                    ],
                    [
                        178,
                        0
                    ]
                ]
            },
            "properties": {}
        }
    ]
}

    return(
        <Map 
            height={"500px"}
            width={"100%"}
            onBboxChange={handleBboxChange} 
            geoData={geojsonData}
            />
    )
}