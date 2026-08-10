WITH WayData AS 
(
	SELECT 
		inputed_data.name as wayName, 
		inputed_data.sequence_id as sequence_id,
		ROW_NUMBER() OVER (ORDER BY inputed_data.name ASC) AS group_id,
		inputed_data.nodes_ids
	FROM 
	(
		SELECT 
			row->>'name' AS name,
			row->'nodes_ids' AS nodes_ids,
			ordinality AS sequence_id
		FROM jsonb_array_elements
		(
			@objects_array::jsonb
		) WITH ORDINALITY AS input_table(row, ordinality) 
	) AS inputed_data
),
inserted_ways AS 
(
	INSERT INTO Ways(name) SELECT wayName FROM WayData RETURNING id, name
),
inserted_ranked AS
(
	SELECT ins.id AS id, ins.name AS name, ROW_NUMBER() OVER (ORDER BY ins.name ASC) AS group_id
	FROM inserted_ways ins
),
grouped AS
(
	SELECT ins.id AS id, ins.name AS name, wd.nodes_ids, wd.sequence_id 
	FROM inserted_ranked ins
	JOIN WayData wd ON wd.group_id = ins.group_id
),
way_nodes AS
(
	SELECT 
		g.id AS way_id,
		node_elem.node_id::uuid AS node_id,
		node_elem.node_seq AS node_sequence_id
	FROM grouped g
	CROSS JOIN LATERAL jsonb_array_elements_text(g.nodes_ids) WITH ORDINALITY AS node_elem(node_id, node_seq)
),
inserted_way_nodes AS
(
	INSERT INTO WaysNodes(way_id, node_id, sequence_id)
	SELECT way_nodes.way_id, way_nodes.node_id, way_nodes.node_sequence_id
	FROM way_nodes
	RETURNING 1
)
SELECT id 
FROM grouped 
WHERE EXISTS (SELECT 1 FROM inserted_way_nodes)
ORDER by sequence_id;




-- example of input object
--			
--			'
--			[
--			{
--				"name":"way_name",
--				"nodes_ids":
--				[
--					"017c2b2e-5fe7-49a0-b047-bf203343d070","0423f07e-0b28-4281-97b1-e15776aec873"
--				]
--			}
--			]'::jsonb
--