import MapGL, { Source, Layer, type MapRef } from 'react-map-gl/maplibre';
import type { RasterSourceSpecification, FillLayerSpecification, LineLayerSpecification, StyleSpecification } from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { useCallback, useRef, useState } from 'react';
import type { FeatureCollection } from 'geojson';

export interface Bbox {
    northEast: { lat: number; lng: number };
    southWest: { lat: number; lng: number };
}

export interface MapProps {
    height: string;
    width: string;
    center?: [number, number];
    zoom?: number;
    onBboxChange?: (newBbox: Bbox, zoom: number) => void;
    geoData?: FeatureCollection | null;
    tileUrl?: string;
}

const DEFAULT_TILE_URL = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

function buildStyle(tileUrl: string): StyleSpecification {
    const osmSource: RasterSourceSpecification = {
        type: 'raster',
        tiles: [tileUrl],
        tileSize: 256,
        maxzoom: 19,
        attribution: '© OpenStreetMap contributors'
    };

    return {
        version: 8,
        projection: { type: 'globe' },
        sky: {
            'atmosphere-blend': [
                'interpolate', ['linear'], ['zoom'],
                0, 1,
                5, 1,
                7, 0
            ]
        },
        sources: {
            osm: osmSource
        },
        layers: [
            {
                id: 'background',
                type: 'background',
                paint: { 'background-color': '#0b1026' }
            },
            {
                id: 'osm',
                type: 'raster',
                source: 'osm'
            }
        ]
    };
}

export function Map({ height, width, center = [0, 0], zoom = 10, onBboxChange, geoData = null, tileUrl = DEFAULT_TILE_URL }: MapProps) {
    const mapRef = useRef<MapRef>(null);
    const [ ready, setReady ] = useState(false);

    const reportBbox = useCallback(() => {
        const map = mapRef.current;
        if (!map || !onBboxChange) return;
        const bounds = map.getBounds();
        onBboxChange(
            {
                northEast: { lat: bounds.getNorth(), lng: bounds.getEast() },
                southWest: { lat: bounds.getSouth(), lng: bounds.getWest() }
            },
            map.getZoom()
        );
    }, [onBboxChange]);

    const geoDataStyle = {
        fill: {
            id: 'geo-data-fill',
            type: 'fill',
            source: 'geo-data',
            paint: {
                'fill-color': '#1a1d62',
                'fill-opacity': 0.4
            }
        } as FillLayerSpecification,
        line: {
            id: 'geo-data-line',
            type: 'line',
            source: 'geo-data',
            paint: {
                'line-color': '#ff7800',
                'line-width': 5,
                'line-opacity': 0.65
            }
        } as LineLayerSpecification
    };

    return (
        <div style={{ height: height, width: width }}>
            <MapGL
                ref={mapRef}
                initialViewState={{ longitude: center[0], latitude: center[1], zoom: zoom }}
                maxZoom={18}
                style={{ height: '100%', width: '100%' }}
                mapStyle={buildStyle(tileUrl)}
                onLoad={() => { setReady(true); reportBbox(); }}
                onMoveEnd={reportBbox}
                onZoomEnd={reportBbox}
            >
                {geoData != null && ready &&
                    <Source id="geo-data" type="geojson" data={geoData}>
                        <Layer {...geoDataStyle.fill} />
                        <Layer {...geoDataStyle.line} />
                    </Source>}
            </MapGL>
        </div>
    );
}