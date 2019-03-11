WITH RECURSIVE
  Rec (child, parent)
  AS (
    SELECT child, parent 
    FROM Subtickets
    WHERE parent = CAST(nullif($PARENT, '') AS integer)
    UNION ALL
    SELECT Subtickets.child, Subtickets.parent
     FROM Rec, Subtickets
     WHERE Rec.child = Subtickets.parent
    )
  SELECT DISTINCT
    t.id AS Ticket,
    t.summary,
    t.type AS type,
    t.priority,
    t.milestone,
    pt.type || pt.id || ' ' || pt.summary || ' (' || pt.priority ||')' AS  __group__,
    '/ticket/'|| pt.id AS __grouplink__,
    CAST(p.value AS int) AS __color__
  FROM Rec r,  ticket t, ticket pt, enum p 
  WHERE t.id = r.child AND r.parent = pt.id AND t.type = 'NFR' 
  AND p.name = t.priority AND p.type = 'priority'
  ORDER BY __group__