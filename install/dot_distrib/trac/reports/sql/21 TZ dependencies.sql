WITH RECURSIVE
  Rec (parent, child, type)
  AS (
    SELECT pt.id, child, t.type
    FROM Subtickets, ticket AS pt, ticket AS t
    WHERE (parent = CAST(nullif($PARENT, '') AS integer))
    AND Subtickets.parent = pt.id AND Subtickets.child = t.id AND (
       (pt.type = 'F'  AND t.type='FR' ) OR
       (pt.type = 'F'  AND t.type='NFR') OR
       (pt.type = 'F'  AND t.type='F')   OR
       (pt.type = 'FR'  AND t.type='FR')  OR
       (pt.type = 'FR'  AND t.type='NFR') OR
       (pt.type = 'F'   AND t.type='UC')  OR
       (pt.type = 'FR'  AND t.type='UC')  OR
       (pt.type = 'F'   AND t.type='UI')  OR
       (pt.type = 'FR'  AND t.type='UI')  OR
       (pt.type = 'UI'  AND t.type='UI')  OR
       (pt.type = 'UI'  AND t.type='UC')  OR
       (pt.type = 'NFR' AND t.type='NFR')
    )
    UNION ALL
    SELECT  Subtickets.parent, Subtickets.child, t.type
    FROM Rec, Subtickets, ticket AS t, ticket AS pt
    WHERE Rec.child = Subtickets.parent
    AND Subtickets.parent=pt.id AND Subtickets.child=t.id
    AND (
       (pt.type = 'F'   AND t.type='FR' ) OR
       (pt.type = 'F'   AND t.type='NFR') OR
       (pt.type = 'FR'  AND t.type='FR')  OR
       (pt.type = 'FR'  AND t.type='NFR') OR
       (pt.type = 'F'   AND t.type='UC')  OR
       (pt.type = 'FR'  AND t.type='UC')  OR
       (pt.type = 'F'   AND t.type='UI')  OR
       (pt.type = 'FR'  AND t.type='UI')  OR
       (pt.type = 'UI'  AND t.type='UI')  OR
       (pt.type = 'UI'  AND t.type='UC')  OR
       (pt.type = 'NFR' AND t.type='NFR')
    )
  )
  SELECT  
    t.id AS ticket,
    t.summary, 
    t.status,
    t.type AS type,
    p.value AS __color__
  FROM ticket t, enum p,
  (
     SELECT DISTINCT s.child FROM subtickets s
     INNER JOIN  (
        SELECT rc.child FROM Rec rc 
        UNION ALL 
        SELECT t.id FROM ticket t 
        WHERE t.id=CAST(nullif($PARENT, '') AS integer)) AS r 
     ON s.parent = r.child
     LEFT OUTER JOIN (
        SELECT rc.child FROM Rec rc 
        UNION ALL 
        SELECT t.id FROM ticket t 
        WHERE t.id=CAST(nullif($PARENT, '') AS integer)) AS nr 
     ON s.child = nr.child
     WHERE nr.child is NULL
  ) as sr
  WHERE sr.child=t.id AND not t.type = 'BUG'
  AND p.name = t.priority AND p.type = 'priority' 
  ORDER BY t.type,  t.id, @SORT_COLUMN@
