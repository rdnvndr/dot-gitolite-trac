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
    t.status,
    t.type AS type,
    t.priority,
    pt.type || pt.id || ' ' || pt.summary || ' (' || pt.priority || ')' AS __group__,
   '/ticket/'|| pt.id AS __grouplink__,
    CAST(p.value AS int) AS __color__,
    pt.id AS _pid
  FROM Rec r,  ticket t, ticket pt, enum p, enum pp
  WHERE t.id = r.child AND r.parent = pt.id AND not pp.value = p.value
  AND t.milestone = pt.milestone
  AND p.name = t.priority AND p.type = 'priority'
  AND pp.name = pt.priority AND pp.type = 'priority'
  AND not r.parent =  CAST(nullif($PARENT, '') AS integer)
  ORDER BY _pid, __color__