WITH 
input_data AS (
	SELECT 
	ST_GeomFromGeoJSON(row->'geom') AS geom,
	COALESCE(row->>'name', 'node') AS name,
	ordinality AS sequence_id
	FROM jsonb_array_elements(
		@objects_array::jsonb
	) WITH ORDINALITY AS input_table(row, ordinality)
)
INSERT INTO Nodes(geom, name) 
SELECT geom, name 
FROM input_data
ORDER BY sequence_id
RETURNING id

-- example of input object
--		'[
--		{"geom":{"type": "Point","coordinates": [21.134, 52.230]}, "name":"name"},
--		{"geom":{"type": "Point","coordinates": [21.135, 52.230]}, "name":"name"},
--		{"geom":{"type": "Point","coordinates": [21.136, 52.230]}, "name":"name"}
--		]'
--