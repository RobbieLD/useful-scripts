-- Group by LOOKUP_KEY and select one record per group having the max effective date
WITH Ordered AS
(
	SELECT LOOKUP_KEY, EFFECTIVE_DATE, RETURN_VALUE, ROW_NUMBER() OVER (PARTITION BY LOOKUP_KEY order by LOOKUP_KEY, EFFECTIVE_DATE desc) AS 'RowNumber'	
	FROM [dbo].[RatingFactorsAddressRating]
	WHERE FACTOR_NAME = 'PSMA_FEATURES' AND PERIL_GROUP = 'COMP' AND RISK_CODE = 'ALL' AND PERIL = 'UWI'
)
select * from  Ordered
where RowNumber = 1
  