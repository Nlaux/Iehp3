--Create FormFieldValues 
IF NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'FormFieldValues')
BEGIN
	CREATE TABLE [dbo].[FormFieldValues](
		[FieldValueId] bigint NOT NULL,
		[FieldValue] nvarchar(max) NOT NULL,
		CONSTRAINT [PK_FormFieldValues] PRIMARY KEY CLUSTERED ([FieldValueId])
	)
END

--Create Fact_FormSummary
IF NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'Fact_FormSummary')
BEGIN
	CREATE TABLE [dbo].[Fact_FormSummary](
		[FormId] uniqueidentifier NOT NULL,
		[FieldId] uniqueidentifier NOT NULL,
		[FieldValueId] bigint NOT NULL,
		[FieldName] nvarchar(max) NOT NULL,
		[Count] int NOT NULL,
		CONSTRAINT [PK_FormSummary] PRIMARY KEY ([FormId], [FieldId], [FieldValueId]),
		CONSTRAINT [FK_FormSummary_FieldValueId] FOREIGN KEY ([FieldValueId]) REFERENCES [dbo].[FormFieldValues] ([FieldValueId])
	)
	ALTER TABLE [dbo].[Fact_FormSummary] NOCHECK CONSTRAINT [FK_FormSummary_FieldValueId];
	CREATE NONCLUSTERED INDEX [IX_ByFieldValueId] ON [dbo].[Fact_FormSummary] ([FieldValueId]);
END

--Create Fact_FormEvents
IF NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'Fact_FormEvents')
BEGIN
	CREATE TABLE [dbo].[Fact_FormEvents](
		[ContactId] uniqueidentifier NOT NULL,	
		[InteractionId] uniqueidentifier NOT NULL,
		[InteractionStartDate] smalldatetime NOT NULL,
		[PageEventDefinitionId] uniqueidentifier NOT NULL,
		[FormId] uniqueidentifier NOT NULL,
		[Count] int NOT NULL,
		CONSTRAINT [PK_FormEvents] PRIMARY KEY ([ContactId], [InteractionId], [InteractionStartDate], [PageEventDefinitionId], [FormId])
	)
END

--Create Fact_FormStatisticsByContact
IF NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'Fact_FormStatisticsByContact')
BEGIN
CREATE TABLE [dbo].[Fact_FormStatisticsByContact](
	[ContactId] uniqueidentifier NOT NULL,
	[FormId] uniqueidentifier NOT NULL,
	[LastInteractionDate] smalldatetime NOT NULL,
        [Submits]  int NOT NULL,
        [Success]  int NOT NULL,
        [Dropouts]  int NOT NULL,
        [Failures]  int NOT NULL,
        [Visits]  int NOT NULL,
        [Value]  int NOT NULL,
        [FinalResult] int NOT NULL
	CONSTRAINT [PK_FormStatisticsByContact] PRIMARY KEY ([ContactId], [LastInteractionDate], [FormId])
)
END

GO

--Drop Add_FormStatisticsByContact procedure if exists
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'Add_FormStatisticsByContact')
BEGIN
	DROP PROCEDURE [dbo].[Add_FormStatisticsByContact]
END

GO

--Create Add_FormStatisticsByContact procedure
CREATE PROCEDURE [dbo].[Add_FormStatisticsByContact]
  @ContactId [uniqueidentifier],
  @FormId [uniqueidentifier],
  @LastInteractionDate [datetime],
  @Submits [int],
  @Success [int],
  @Dropouts [int],
  @Failures [int],
  @Visits [int],
  @Value [int],
  @FinalResult [int]
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		MERGE [dbo].[Fact_FormStatisticsByContact] AS t
		USING
		(
		  VALUES
		  (
			@ContactId,
			@FormId,
			@LastInteractionDate,
			@Submits,
			@Success,
			@Dropouts,
			@Failures,
			@Visits,
			@Value,
			@FinalResult
		  )
		)
		as s
		(
		  [ContactId],
		  [FormId],
		  [LastInteractionDate],
			[Submits],
			[Success],
			[Dropouts],
			[Failures],
			[Visits],
			[Value],
			[FinalResult]
		)
		ON
		(
		  t.[ContactId] = s.[ContactId] AND
		  t.[FormId] = s.[FormId]
		)
		WHEN MATCHED and (t.[LastInteractionDate] < s.[LastInteractionDate]) THEN UPDATE SET 
		  t.[LastInteractionDate] = s.[LastInteractionDate],
		  t.[Submits] = s.[Submits],
		  t.[Success] = s.[Success],
		  t.[Dropouts] = s.[Dropouts],
		  t.[Failures] = s.[Failures],
		  t.[Visits] = s.[Visits],
		  t.[Value] = s.[Value],
		  t.[FinalResult] = s.[FinalResult]
		WHEN NOT MATCHED THEN
		  INSERT(
		  [ContactId],
		  [FormId],
		  [LastInteractionDate],
			[Submits],
			[Success],
			[Dropouts],
			[Failures],
			[Visits],
			[Value],
			[FinalResult]
			)
		  VALUES(
		  s.[ContactId],
		  s.[FormId],
		  s.[LastInteractionDate],
			s.[Submits],
			s.[Success],
			s.[Dropouts],
			s.[Failures],
			s.[Visits],
			s.[Value],
			s.[FinalResult]
			);
	END TRY
	BEGIN CATCH
		DECLARE @error_number INTEGER = ERROR_NUMBER();
		DECLARE @error_severity INTEGER = ERROR_SEVERITY();
		DECLARE @error_state INTEGER = ERROR_STATE();
		DECLARE @error_message NVARCHAR(4000) = ERROR_MESSAGE();
		DECLARE @error_procedure SYSNAME = ERROR_PROCEDURE();
		DECLARE @error_line INTEGER = ERROR_LINE();
		RAISERROR( N'T-SQL ERROR %d, SEVERITY %d, STATE %d, PROCEDURE %s, LINE %d, MESSAGE: %s', @error_severity, 1, @error_number, @error_severity, @error_state, @error_procedure, @error_line, @error_message ) WITH NOWAIT;
	END CATCH;
END;

GO

--Drop Upsert_FormSummary procedure if exists
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = 'Upsert_FormSummary')
BEGIN
	DROP PROCEDURE [dbo].[Upsert_FormSummary]
END

GO

--Create Upsert_FormSummary procedure
CREATE PROCEDURE [dbo].[Upsert_FormSummary]
         @FormId  uniqueidentifier
      ,@FieldId   uniqueidentifier
      ,@FieldValueId  bigint
      ,@FieldName  nvarchar(max)
      ,@Count  int
AS
BEGIN

  SET NOCOUNT ON;
  BEGIN TRY

    MERGE
      [Fact_FormSummary] AS [target]
    USING
    (
      VALUES
      (
       @FormId 
      ,@FieldId
      ,@FieldValueId
      ,@FieldName
      ,@Count
      )
    )
    AS [source]
    (
      [FormId],
      [FieldId],
      [FieldValueId],
      [FieldName],
      [Count]
    )
    ON
      ([target].[FormId] = [source].[FormId] AND [target].[FieldId] = [source].[FieldId] AND [target].[FieldValueId] = [source].[FieldValueId] )

    WHEN MATCHED THEN
      UPDATE
        SET
          [target].[FieldName] = [source].[FieldName],
          [target].[Count] = [target].[Count] +[source].[Count] 

    WHEN NOT MATCHED THEN
      INSERT
      (
        [FormId],
        [FieldId],
      [FieldValueId],
      [FieldName],
      [Count]
      )
      VALUES
      (
        [source].[FormId],
        [source].[FieldId],
        [source].[FieldValueId],
        [source].[FieldName],
        [source].[Count]
      );

  END TRY
  BEGIN CATCH

    DECLARE @error_number INTEGER = ERROR_NUMBER();
    DECLARE @error_severity INTEGER = ERROR_SEVERITY();
    DECLARE @error_state INTEGER = ERROR_STATE();
    DECLARE @error_message NVARCHAR(4000) = ERROR_MESSAGE();
    DECLARE @error_procedure SYSNAME = ERROR_PROCEDURE();
    DECLARE @error_line INTEGER = ERROR_LINE();

    IF( @error_number = 2627 )
    BEGIN
      
      UPDATE
        [Fact_FormSummary]
      SET
        [FieldName] = @FieldName,
        [Count] = @Count + [Count]
      WHERE
      ( 
        ([FormId] = @FormId AND [FieldId] = @FieldId AND [FieldValueId] = @FieldValueId)
      )

      IF( @@ROWCOUNT != 1 )
      BEGIN
        RAISERROR( 'Failed to update row in the [Fact_FormSummary] table.', 18, 1 ) WITH NOWAIT;
      END

    END
    ELSE
    BEGIN

      RAISERROR( N'T-SQL ERROR %d, SEVERITY %d, STATE %d, PROCEDURE %s, LINE %d, MESSAGE: %s', @error_severity, 1, @error_number, @error_severity, @error_state, @error_procedure, @error_line, @error_message ) WITH NOWAIT;

    END

  END CATCH

END
GO
