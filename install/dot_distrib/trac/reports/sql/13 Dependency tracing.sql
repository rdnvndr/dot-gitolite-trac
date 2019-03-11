(
WITH RECURSIVE
  Rec (child, parent)
  AS (
    SELECT child, parent 
    FROM Subtickets
    WHERE child = CAST(nullif($PARENT, '') AS integer)
    UNION ALL
    SELECT Subtickets.child, Subtickets.parent
     FROM Rec, Subtickets
     WHERE Subtickets.child = Rec.parent
    )
  SELECT DISTINCT
    t.id AS Ticket,
    t.summary,
    t.status,
    t.type AS type,
    'Родители / Зависят:' AS __group__,
    CAST(p.value AS int) AS __color__
  FROM Rec r,  ticket t, enum p 
  WHERE t.id = r.parent
  AND p.name = t.priority AND p.type = 'priority'
  ORDER BY Ticket
) UNION ALL (
WITH RECURSIVE
  Rec (child, parent)
  AS (
    SELECT child, parent 
    FROM Subtickets
    WHERE parent = CAST(nullif($PARENT, '') AS integer)
    UNION ALL
    SELECT Subtickets.child, Subtickets.parent
     FROM Rec, Subtickets
     WHERE Subtickets.parent = Rec.child
    )
  SELECT DISTINCT
    t.id AS Ticket,
    t.summary,
    t.status,
    t.type AS type,
    'Дети / Зависит от:' AS __group__,
    CAST(p.value AS int) AS __color__
  FROM Rec r,  ticket t, enum p 
  WHERE t.id = r.child 
  AND p.name = t.priority AND p.type = 'priority'
  ORDER BY Ticket
)