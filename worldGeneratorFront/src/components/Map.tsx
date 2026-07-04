import { MapContainer, GeoJSON, useMapEvents, useMap } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';
import { useEffect, useState } from 'react';

const sampleGeoJson: any = {
  type: "FeatureCollection",
  features: [
    {
      type: "Feature",
      properties: { name: "Sample Polygon" },
      geometry: {
        type: "Polygon",
        coordinates: [
          [
            [-0.5, 0.5],
            [-0.5, -0.5],
            [0.5, -0.5],
            [0.5, 0.5],
            [-0.5, 0.5]
          ]
        ]
      }
    },
    {
      type: "Feature",
      properties: { name: "Sample Polygon" },
      geometry: {
        type: "Polygon",
        coordinates: [
          [
            [-1.5, 0.5],
            [-1.5, -0.5],
            [-1.0, -0.5],
            [-1.0, 0.5],
            [-1.5, 0.5]
          ]
        ]
      }
    }
  ]
};

export interface MapProps {
    height: string;
    width: string;
    center?: [number, number];
    zoom?: number;
    onBboxChange?:(newBbox:any, zoom:number)=>void;
    geoData?: any;
}

export function Map({height, width, center=[0,0], zoom=10, onBboxChange, geoData=null}: MapProps) {
    const [ currentZoom, setCurrentZoom ] = useState(zoom);
    const [ currentCenter, setCurrentCenter ] = useState<[number, number]>(center);

    const MapEventListener = () =>
    {
        useMapEvents({
            zoomend:(e) => {
                setCurrentZoom(e.target.getZoom());
            },
            moveend:(e) => {
                setCurrentCenter([e.target.getCenter().lat, e.target.getCenter().lng]);
            }
        })  

        const map = useMap();
        const bounds = map.getBounds();

        useEffect(() => {
          const bbox = {
            northEast: bounds.getNorthEast(),
            southWest: bounds.getSouthWest()
          }
          onBboxChange && onBboxChange(bbox, currentZoom);
        }, [currentZoom, currentCenter]);
        return null;
    }

    return (
        <div style={{ height: height, width: width }}>
            <MapContainer 
                center={center} 
                zoom={zoom}
                style={{ height: "100%", width: "100%" }}
                maxZoom={18}
                >
                <MapEventListener/>
                {geoData!=null &&                 
                <GeoJSON data={geoData}
                style={() => ({
                    color: '#ff7800',
                    weight: 5,
                    opacity: 0.65,
                    fillColor: '#1a1d62',
                    fillOpacity: 0.4
                })}/>}
            </MapContainer>
        </div>
    )
}