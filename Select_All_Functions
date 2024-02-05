SELECT O.name, M.definition, O.type_desc, O.type
FROM sys.sql_modules M
INNER JOIN sys.objects O ON M.object_id=O.object_id
WHERE O.type IN ('IF','TF','FN')
