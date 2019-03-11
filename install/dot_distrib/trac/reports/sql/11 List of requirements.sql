WITH RECURSIVE
  Rec (fparent, fsummary, child, summary, description, status, priority, type )
  AS (
    SELECT pt.id, pt.summary,
           child, 
           t.summary, 
           t.description,
           t.status,
           t.priority,
           t.type
    FROM Subtickets, ticket AS pt, ticket AS t
    WHERE parent = CAST(nullif($PARENT, '') AS integer)
    AND Subtickets.parent = pt.id AND Subtickets.child = t.id AND (
       (pt.type = 'F'   AND t.type='FR' ) OR
       (pt.type = 'F'   AND t.type='NFR') OR
       (pt.type = 'F'   AND t.type='F')   OR
       (pt.type = 'FR'  AND t.type='FR')  OR
       (pt.type = 'FR'  AND t.type='NFR') OR
       (pt.type = 'NFR' AND t.type='NFR') 
    )
    UNION ALL
    SELECT  
           (CASE pt.type
            WHEN 'F' THEN
               pt.id
            ELSE
               Rec.fparent
            END),
            (CASE pt.type
            WHEN 'F' THEN
               pt.summary
            ELSE
               Rec.fsummary
            END),
            Subtickets.child,
            t.summary, 
            t.description,
            t.status,
            t.priority,
            t.type
    FROM Rec, Subtickets, ticket AS t, ticket AS pt
    WHERE Rec.child = Subtickets.parent
    AND Subtickets.parent=pt.id AND Subtickets.child=t.id
    AND (
       (pt.type = 'F'   AND t.type='FR' ) OR
       (pt.type = 'F'   AND t.type='NFR') OR
       (pt.type = 'FR'  AND t.type='FR')  OR
       (pt.type = 'FR'  AND t.type='NFR') OR
       (pt.type = 'NFR' AND t.type='NFR')
    )
  )
  SELECT DISTINCT
    r.child AS ticket,
    r.summary, 
    r.status,
    r.type AS type,
    '[[BR]]'|| r.description  || ' [[BR]][[BR]]' AS _description_,
    (CASE r.type 
     WHEN 'F' THEN 
         r.summary || ' (#'|| r.child || ')' 
     ELSE
         r.fsummary || ' (#'|| r.fparent || ')' 
     END) AS __group__,  
     (CASE r.type 
      WHEN 'F' THEN  
         '/ticket/'|| r.child 
      ELSE 
         '/ticket/'|| r.fparent
      END) AS __grouplink__,
    p.value AS __color__
  FROM Rec r, enum p 
  WHERE p.name = r.priority AND p.type = 'priority'
  ORDER BY __group__, r.type, @SORT_COLUMN@, r.child