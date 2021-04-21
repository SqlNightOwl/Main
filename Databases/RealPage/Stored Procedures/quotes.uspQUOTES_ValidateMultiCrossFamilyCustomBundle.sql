SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_ValidateMultiCrossFamilyCustomBundle]
-- Description     : This procedure validates whether the specific quote has Multi Cross Family Custom Bundle.
-- Input Parameters: @IPVC_QuoteIDSeq   VARCHAR(11)
-- 
-- OUTPUT          : 
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_ValidateMultiCrossFamilyCustomBundle]  @IPVC_QuoteIDSeq    = 'Q0000000001'
--                                                              
-- Revision History:
-- Author          : Anand Chakravarthy
-- 08/03/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_ValidateMultiCrossFamilyCustomBundle]  (@IPVC_QuoteIDSeq      VARCHAR(50)
                                                )                                                
AS
BEGIN
  set nocount on
  DECLARE @MultiCrossFamilyCustomBundleFlag BIT;
  DECLARE @loopid INT;
------------------------------------------------------------------------------------------------------

CREATE TABLE #Tbl1 (rowid int identity(1,1),
					GroupId bigint) 
------------------------------------------------------------------------------------------------------
INSERT INTO #Tbl1(GroupId)  
SELECT IDSeq from  Quotes.dbo.[Group] 
             where quoteidseq = @IPVC_QuoteIDSeq 
             and   custombundlenameenabledflag = 1   
------------------------------------------------------------------------------------------------------
SELECT @loopid = 0
WHILE @loopid <= (SELECT Count(GroupId) FROM #Tbl1)
BEGIN

IF EXISTS(SELECT TOP 1 1 from Quotes.dbo.QuoteItem QI join #Tbl1 t1 on QI.groupidseq = t1.groupid
		  where t1.rowid = @loopid  
		  having count(distinct(QI.familycode)) > 1)
          
 BEGIN
  select @MultiCrossFamilyCustomBundleFlag = 1;
 END 
         
SET @loopid = @loopid + 1
END
--Final Select

select @MultiCrossFamilyCustomBundleFlag as MultiCrossFamilyCustomBundleFlag  
------------------------------------------------------------------------------------------------------
drop table #Tbl1 
END

GO
