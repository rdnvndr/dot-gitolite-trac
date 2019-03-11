WITH RECURSIVE
  Rec (parent, psummary, child, summary, status, type, description, priority)
  AS (
    SELECT parent, pt.summary,
           child,
           t.summary, 
           t.status,
           t.type,
           t.description, 
           t.priority
    FROM Subtickets, ticket AS t, ticket AS pt 
    WHERE (parent = CAST(nullif($PARENT, '') AS integer)
           OR  child = CAST(nullif($PARENT, '') AS integer))
      AND Subtickets.parent=pt.id AND Subtickets.child=t.id AND (
       (pt.type = 'F'  AND t.type='FR' ) OR
       (pt.type = 'F'  AND t.type='UI')  OR
       (pt.type = 'F'  AND t.type='F')   OR
       (pt.type = 'FR' AND t.type='UI')  OR
       (pt.type = 'UI' AND t.type='UI')  OR
       (pt.type = 'UI' AND t.type='UC')
      )
    UNION ALL
    SELECT Subtickets.parent, pt.summary,
           Subtickets.child,
           t.summary,
           t.status,
           t.type,
           t.description,
           t.priority
    FROM Rec, Subtickets, ticket AS t, ticket AS pt 
    WHERE Rec.child = Subtickets.parent 
    AND Subtickets.parent=pt.id AND Subtickets.child=t.id AND (
       (pt.type = 'F'  AND t.type='FR' ) OR
       (pt.type = 'F'  AND t.type='UI')  OR
       (pt.type = 'FR' AND t.type='UI')  OR
       (pt.type = 'UI' AND t.type='UI')  OR
       (pt.type = 'UI' AND t.type='UC')
      )
    )

  SELECT DISTINCT
    r.child AS ticket,
    r.summary, 
    r.status,
    r.type AS type,
    r.description AS _description_,
    (CASE r.type 
    WHEN 'UI' THEN 
       r.summary || ' (#'|| r.child || ')'
    ELSE
       r.psummary || ' (#'|| r.parent || ')'
    END) AS __group__,
    (CASE r.type 
    WHEN 'UI' THEN 
       '/ticket/'|| r.child 
    ELSE
       '/ticket/'|| r.parent
    END)  AS __grouplink__,
    p.value AS __color__
  FROM Rec r,  enum p 
  WHERE (r.type = 'UC' OR  r.type = 'UI') 
    AND  p.name = r.priority AND p.type = 'priority'
  ORDER BY __group__, r.type DESC, @SORT_COLUMN@, r.child