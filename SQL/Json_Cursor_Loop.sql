DECLARE @TestCaseId INT
DECLARE @Wsd INT
DECLARE @JsonValue NVARCHAR(MAX)
DECLARE @Results NVARCHAR(MAX)

DECLARE JSON_CURSOR CURSOR FAST_FORWARD FOR
SELECT 
	Id,
	Wsd,
	JsonValue
FROM 
	(
		SELECT 
			Id,
			JSON_VALUE(InputParameters,'$.Some.Old.Object.Path') as Wsd,
			InputParameters as JsonValue
		FROM 
		TestCase
	) Tests 
WHERE 
	Tests.Wsd IS NOT NULL

OPEN JSON_CURSOR
FETCH NEXT FROM JSON_CURSOR INTO @TestCaseId, @Wsd, @JsonValue

WHILE @@FETCH_STATUS = 0
BEGIN
	
	-- Remove Old Value
	SET @Results=JSON_MODIFY(@JsonValue,'$.Some.Old.Object.Path',NULL)

	-- Add New Value
	SET @Results=JSON_MODIFY(@Results,'$.Some.New.Object.Path',JSON_QUERY('[{ "Value": ' + CONVERT(varchar(12), @Wsd ) + ' }]'))

	UPDATE TestCase SET InputParameters = @Results WHERE Id = @TestCaseId

	FETCH NEXT FROM JSON_CURSOR INTO @TestCaseId, @Wsd, @JsonValue
END 
 
CLOSE JSON_CURSOR 
DEALLOCATE JSON_CURSOR 
GO