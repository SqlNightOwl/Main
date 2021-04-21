SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--exec uspQUOTES_GetExpressionsWithTiers 
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetExpressionsWithTiers
-- Description     : This procedure is called UI to get all Expressions with corresponding TierLevels
-- Input Parameters: 1. @IPVC_QuoteID   as varchar(20)
--                   
-- OUTPUT          : None
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_GetExpressionsWithTiers @IPVC_SubSystem = 'QUOTES',@IPVC_ApplyToArea='DEALDESK' 
-- 
-- 
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created. TFS # 267 Deal Desk Project
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetExpressionsWithTiers] (@IPVC_SubSystem     varchar(50) = 'QUOTES',     --->Mandatory : This is the SubSystem for which all Active Expressions to be returned.
                                                                                                                ---Default is QUOTES. Expandable for future
                                                            @IPVC_ApplyToArea   varchar(50) = 'DEALDESK'    --->Mandatory : This is the SubSystems Area for which all Active Expressions to be returned.
                                                                                                                ---Default is DEALDESK. Expandable for future
                                                           )
as
BEGIN
  set nocount on;
  ----------------------------------------------------
  select ER.[Expression]                     as Expression,
         ERT.[TierLevel]                     as TierLevel
  from   QUOTES.dbo.ExpressionRuleTier ERT with (nolock)
  inner Join
         QUOTES.dbo.ExpressionRule     ER  with (nolock)
  on     ERT.ERuleIDSeq    = ER.ERuleIDSeq
  and    ERT.ActiveFlag    = 1
  and    ER.ActiveFlag     = 1
  and    ER.[SubSystem]    = @IPVC_SubSystem
  and    ER.[ApplyToArea]  = @IPVC_ApplyToArea
  where  ERT.ActiveFlag    = 1
  and    ER.ActiveFlag     = 1
  and    ER.[SubSystem]    = @IPVC_SubSystem
  and    ER.[ApplyToArea]  = @IPVC_ApplyToArea
END
GO
