WITH data_with_tags AS 
(
	SELECT 
		inputed_data.new_name, 
		inputed_data.new_geom, 
		inputed_data.existing_id,
		inputed_data.sequence_id,
		DENSE_RANK() OVER (ORDER BY new_name, new_geom, existing_id) AS group_id
	FROM 
	(
		SELECT 
			(row->>'id')::uuid AS existing_id,
			ST_GeomFromGeoJSON(row->'geom') AS new_geom,
			row->>'name' AS new_name,
			ordinality AS sequence_id
		FROM jsonb_array_elements
		(
			@objects_array::jsonb
		) WITH ORDINALITY AS input_table(row, ordinality) 
	) AS inputed_data ORDER BY sequence_id
),
inserted_way AS 
(
	INSERT INTO Ways(name) VALUES(@way_name) RETURNING id
),
grouped AS 
(
	SELECT new_name, new_geom, existing_id, group_id FROM data_with_tags GROUP BY new_name, new_geom, existing_id, group_id ORDER BY group_id
),
inserted_nodes AS 
(
	INSERT INTO Nodes(geom, name)
	SELECT new_geom::geography, new_name FROM grouped WHERE existing_id IS NULL ORDER BY group_id
	RETURNING id, name, geom
),
inserted_nodes_with_groups AS
(
		SELECT 
			ins.id as new_id, 
			gr.group_id as group_id, 
			gr.new_name as new_name, 
			gr.new_geom as new_geom, 
			gr.existing_id as existing_id 
		FROM inserted_nodes ins
		JOIN grouped
		ON 
			grouped.new_name = ins.name 
			AND grouped.new_geom:geography = ins.geom
		WHERE grouped.existing_id IS NULL
),
ungrouped_with_ids AS 
(
	SELECT COALESCE(data_with_tags.existing_id, ins.new_id) as id, data_with_tags.sequence_id as sequence_id FROM data_with_tags
	LEFT JOIN inserted_nodes_with_groups ins ON ins.group_id = data_with_tags.group_id
)
INSERT INTO WaysNodes(way_id, node_id, sequence_id)
SELECT inserted_way.id, col.id, col.sequence_id
FROM inserted_way, ungrouped_with_ids col
Order BY sequence_id
RETURNING id, way_id, node_id, sequence_id


-- example of input object
--			'[
--			{"name":"first_node", "geom":{"type": "Point","coordinates": [21.134, 52.230]}},
--			{"id":"017c2b2e-5fe7-49a0-b047-bf203343d070"},
--			{"name":"second_node", "geom":{"type": "Point","coordinates": [21.135, 52.230]}},
--			{"id":"0423f07e-0b28-4281-97b1-e15776aec873"},
--			{"name":"first_node", "geom":{"type": "Point","coordinates": [21.134, 52.230]}}
--			]'::jsonb
--