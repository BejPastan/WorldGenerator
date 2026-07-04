	WITH input_data AS 
	(
		SELECT 
			(row->>'id')::uuid AS existing_id,
			ST_GeomFromGeoJSON(row->'geom') AS new_geom,
			row->>'name' AS new_name,
			ordinality AS sequence_id
		FROM jsonb_array_elements
		(
			@objects_array
		) WITH ORDINALITY AS input_table(row, ordinality)
	),
	inserted_way AS 
	(
		INSERT INTO Ways(name) VALUES(@way_name) RETURNING id
	),
	inserted_nodes AS 
	(
		INSERT INTO Nodes(geom, name)
		SELECT new_geom::geography, new_name FROM input_data WHERE existing_id IS NULL ORDER BY sequence_id
		RETURNING id
	),
	combined_ordered_nodes AS 
	(
		SELECT existing_id AS child_id, sequence_id FROM input_Data WHERE existing_id IS NOT NULL
		UNION ALL
		SELECT 
			n.id AS child_id,
			i.sequence_id
		FROM (
			SELECT id, row_number() OVER () AS rn FROM inserted_nodes 
		JOIN (
			SELECT sequence_id, row_number() over (ORDER BY sequence_id) AS rn
			FROM input_data WHERE existing_id IS NULL 
		) i ON n.rn = i.rn 
	)
	INSERT INTO WaysNodes(way_id, node_id, sequence_id)
	SELECT inserted_way.id, col.child_id, col.sequence_id
	FROM inserted_way, combined_ordered_nodes col
	Order BY col.sequence_id
	RETURNING id, way_id, node_id, sequence_id