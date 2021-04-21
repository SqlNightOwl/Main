SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------
-- procedure  : dbo.uspTAXRECALCINVOICES_GetStatus
-- purpose    : obtain processing status of Tax Recalculation process, at the present moment
-- parameters : none
-- returns    : status and the three control date/time values
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-11-17   Larry Wilson             initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_GetStatus]
AS
BEGIN
	DECLARE @Status int, @Pdate datetime, @Cdate datetime, @Adate datetime
	SELECT TOP 1 @Pdate=[LastPrequalifyDate],@Cdate=[LastCalculationDate],@Adate=[LastAppliedDate]
	  FROM [dbo].[TaxRecalculationStatus]
	IF @Adate>@Pdate AND @Adate>@Cdate
	BEGIN -- [LastAppliedDate] is the MAX winner
		select @Status=0	-- A => 0:Finished
	END
	ELSE
	BEGIN -- the contest is between C and P, for maximal date/time
		IF @Pdate>@Cdate
		BEGIN
			select @Status=1	-- P => 1:Initialized
		END
		ELSE
		BEGIN
			select @Status=2	-- C => 2:InProgress
		END
	END
	SELECT @Status as [Status]
		,@Pdate as [LastPrequalify]
		,@Cdate as [LastCalculation]
		,@Adate as [LastApplied]
	RETURN(0)
END
GO
