SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------
-- procedure  : dbo.uspTAXRECALCINVOICES_SetStatus
-- purpose    : Update current status of Tax Recalculation process, as of the present moment
-- parameters : Activity that was just completed.  P=Prequalify, or C=Calculate, or A=Apply
-- returns    : status and the three control date/time values
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-11-30   Larry Wilson             initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_SetStatus]
(
	@LastAction varchar(1)
)
AS
BEGIN
	DECLARE @Status int, @Pdate datetime, @Cdate datetime, @Adate datetime
	SELECT TOP 1 @Pdate=[LastPrequalifyDate],@Cdate=[LastCalculationDate],@Adate=[LastAppliedDate]
	  FROM [dbo].[TaxRecalculationStatus]
	IF @LastAction='P'
	BEGIN
		SELECT @Pdate=GETDATE()	
	END
	ELSE
	BEGIN
		IF @LastAction='C'
		BEGIN
			SELECT @Cdate=GETDATE()	
		END
		ELSE
		BEGIN
			IF @LastAction='A'
			BEGIN
				SELECT @Adate=GETDATE()	
			END
			ELSE
			BEGIN
				SELECT '0' AS confirmAction,
						'LastAction must be P, C, or A' AS responseMsg
				RETURN(2)
			END
		END
	END

	UPDATE [dbo].[TaxRecalculationStatus]
	   SET [LastPrequalifyDate] = @Pdate
		   ,[LastCalculationDate] = @Cdate
		   ,[LastAppliedDate] = @Adate

	SELECT '1' AS confirmAction, 'done' AS responseMsg
	RETURN(0)
END
GO
