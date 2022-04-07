-- Group by LOOKUP_KEY and select one record per group having the max effective date
WITH Ordered AS
(
	SELECT LOOKUP_KEY, EFFECTIVE_DATE, RETURN_VALUE, ROW_NUMBER() OVER (PARTITION BY LOOKUP_KEY order by LOOKUP_KEY, EFFECTIVE_DATE desc) AS 'RowNumber'	
	FROM [dbo].[SomeTable]
	WHERE SomeColumn = 'SomeValue'
)
select * from  Ordered
where RowNumber = 1
  