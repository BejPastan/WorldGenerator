WITH
input_data AS(
	SELECT 
	(row->>'ElementId')::uuid AS element_id, 
		row->>'Value' AS v, 
		row->>'Key' AS k,
		ORDINALITY AS sequence_id
	FROM jsonb_array_elements(
		@objects_array::jsonb
	) WITH ORDINALITY AS input_table(row, ordinality)
)
INSERT INTO <name>sTags(v, k, <name>_id)
SELECT v,k,element_id FROM input_data
ORDER BY sequence_id
RETURNING id

-- example of input object
--		'[
--		{"element_id":"uuid", "value":"value", "key":"key"},
--		{"element_id":"uuid", "v":"value", "k":"key"},
--		{"element_id":"uuid", "v":"value", "k":"key"},
--		]'
--