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
    CAST(p.value AS int) AS __color__
  FROM Rec r,  ticket t, ticket pt, enum p 
  WHERE t.id = r.child AND r.parent = pt.id AND t.type = 'NFR' 
  AND CASE 
      WHEN not $KEYWORDS = '' THEN t.keywords like $KEYWORDS 
      ELSE  t.keywords like '%'
  END
  AND p.name = t.priority AND p.type = 'priority'
  ORDER BY Ticket