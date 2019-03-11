SELECT 
   tc.ticket,
   tc.time AS __tm__,  
   rt.summary,
   rt.type,
   tc.author,
   tc.time AS modified,
   array_to_string(array_agg(
      '* **' || tc.field || '**: [[BR]]' || Chr(10)
      || '{{{ ' || Chr(10)
      || CASE tc.newvalue is NULL 
         WHEN true THEN 'NULL' 
         ELSE  tc.newvalue END
      || Chr(10) || '}}}'
   ), Chr(10)) AS _description_
FROM (
WITH RECURSIVE
  Rec (child, parent, summary, type)
  AS (
    SELECT child, parent, t.summary, t.type 
      FROM Subtickets, ticket t, ticket pt 
     WHERE parent = CAST(nullif($PARENT, '') AS integer)
       AND t.id = Subtickets.child  AND Subtickets.parent = pt.id 
     UNION ALL
    SELECT Subtickets.child, Subtickets.parent, t.summary, t.type 
      FROM Rec, Subtickets, ticket t, ticket pt 
     WHERE Rec.child = Subtickets.parent
       AND t.id = Subtickets.child  AND Subtickets.parent = pt.id
    )
  SELECT DISTINCT
    r.child AS id, r.summary, r.type
  FROM Rec r
) AS rt
INNER JOIN ticket_change tc
ON tc.ticket = rt.id AND NOT tc.field = 'comment' AND NOT tc.field is NULL
GROUP BY tc.ticket, __tm__, rt.summary, rt.type, tc.author
ORDER BY  __tm__ DESC
LIMIT 7