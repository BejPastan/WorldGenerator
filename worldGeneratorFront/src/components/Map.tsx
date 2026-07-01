import { MapContainer, GeoJSON, useMapEvent, useMapEvents } from 'react-leaflet';
import 'leaflet/dist/leaflet.css';

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
    center: [number, number];
    zoom: number;
    onPan:()=>void;
    onZoom:()=>void;
}

export function Map(props: MapProps) {
    const MapEventListener = () =>
    {
        useMapEvents({
            zoomend:(e) => {
                console.log("new zoom: ", e.target.getZoom())
                props.onZoom();
            },
            moveend:(e) => {
                console.log('new center: ', e.target.getCenter())
                props.onPan();
            }
        })
        return null;
    }

    return (
        <div style={{ height: props.height, width: props.width }}>
            <MapContainer 
                center={props.center} 
                zoom={props.zoom}
                style={{ height: "100%", width: "100%" }}
                maxZoom={18}
                >
                <MapEventListener/>
                <GeoJSON data={sampleGeoJson}
                style={() => ({
                    color: '#ff7800',
                    weight: 5,
                    opacity: 0.65,
                    fillColor: '#1a1d62',
                    fillOpacity: 0.4
                })}/>
            </MapContainer>
        </div>
    )
}