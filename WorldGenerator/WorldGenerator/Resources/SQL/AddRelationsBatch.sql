WITH RelationData AS
(
	SELECT
	ordinality AS sequence_id,
	row->>'name' AS name,
	row->'elements' AS elements,
	ROW_NUMBER() OVER (ORDER BY row->>'name' ASC) AS group_id
	FROM
	jsonb_array_elements(
		@objects_array::jsonb
	) WITH ORDINALITY AS input_table(row, ordinality)
),
inserted_relations AS
(
	INSERT INTO relations(name) SELECT name FROM RelationData RETURNING id,name
),
inserted_with_gr AS
(
		SELECT rd.name, rd.elements, rd.sequence_id, rd.group_id, ins.id 
		FROM RelationData rd
		JOIN 
		(
			SELECT 
				ins.*,
				ROW_NUMBER() OVER (ORDER BY ins.name ASC) AS group_id 
			FROM inserted_relations ins
		) AS ins ON ins.group_id = rd.group_id
),
elements_to_insert AS
(
	SELECT 
	inserted_with_gr.id AS r_id,
	(relation_element.row->>'way_id')::uuid AS w_id,
	(relation_element.row->>'type')::boolean AS type
	FROM inserted_with_gr
	CROSS JOIN LATERAL jsonb_array_elements(
		inserted_with_gr.elements
	) AS relation_element(row)
),
inserted_elements AS
(
	INSERT INTO RelationsElements(relation_id, way_id, type) SELECT r_id, w_id, type FROM elements_to_insert RETURNING 1
)
SELECT id FROM inserted_with_gr 
WHERE EXISTS (SELECT 1 FROM inserted_elements)
ORDER BY sequence_id


-- 	example input object
--	[
--		{
--			'relation_name':'name',
--			'elements':[{'way_id':'uuid', 'type':'boolen'}]
--		}
--	]