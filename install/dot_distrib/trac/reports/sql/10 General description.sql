SELECT id AS ticket, summary,t.status, t.type AS type, description AS _description_
FROM ticket t
WHERE id = CAST(nullif($PARENT, '') AS integer)