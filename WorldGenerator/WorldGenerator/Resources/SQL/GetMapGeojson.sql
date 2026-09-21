SELECT 
jsonb_build_object
(
                'type', 'FeatureCollection',
                'features', COALESCE(jsonb_agg
                (
                        jsonb_build_object
						(
						'typ', objects.type,
						'geometry', objects.geometry,
						'properties', COALESCE(objects.properties, '{}'::jsonb)
						)
                ), '[]'::jsonb)
 ) as resp
 FROM
 (
                SELECT
                        'Feature'as type,
                        CASE
                                WHEN ST_IsClosed(geom_data.geom_line)
                                THEN
                                        ST_AsGeoJSON(ST_MakePolygon(geom_data.geom_line)::geography)::jsonb
                                ELSE
                                        geom_data.geom_line::jsonb
                        END as geometry,
						geom_data.properties as properties
                FROM
                (
                        SELECT
                        ST_MakeLine(n.geom::geometry ORDER BY wn.sequence_id ASC) as geom_line,
						COALESCE(
						        jsonb_object_agg(wt.k, wt.v) FILTER (WHERE wt.k IS NOT NULL), 
						        '{}'::jsonb
						    ) AS properties
						FROM Ways w
                        LEFT JOIN WaysNodes wn ON wn.way_id = w.id
                        LEFT JOIN Nodes n ON n.id = wn.node_id
                        LEFT JOIN WaysTags wt ON wt.way_id = w.id
                        WHERE w.id = ANY(get_way_in_bbox(@minLng, @minLat, @maxLng, @maxLat, @zoom_level))
                        GROUP BY w.id
                ) geom_data
 ) objects