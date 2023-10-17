
SELECT 
	count(*) as Total
FROM SomeTable CROSS APPLY OPENJSON(JsonValueColumn)
WITH 
(
	Parameters nvarchar(max) as JSON
) as Params CROSS APPLY OPENJSON (Parameters)
WITH
(
	SomeColumnValue nvarchar(4),
) as Vals
GROUP BY Vals.SomeColumnValue;

