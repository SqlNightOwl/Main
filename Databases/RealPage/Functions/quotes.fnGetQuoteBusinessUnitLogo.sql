SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [fnGetQuoteBusinessUnitLogo]
-- Description     : This Functions returns BusinessUnitLogo for a given Quote. Default is Realpage unless specifix.
-- Input Parameters: @IPVC_QuoteIDSeq
-- Syntax          : select  Quotes.dbo.fnGetQuoteBusinessUnitLogo('Q1006000008')
/*
                     declare @LVC_BusinessUnit varchar(10)
                     select  @LVC_BusinessUnit = Quotes.dbo.fnGetQuoteBusinessUnitLogo('Q1006000008');
                     select @LVC_BusinessUnit
*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 05/17/2010      : SRS (Defect 7887, 7884)
------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION [quotes].[fnGetQuoteBusinessUnitLogo](@IPVC_QuoteIDSeq varchar(50)) 
returns varchar(100) 
as
BEGIN  
  --------------------------------------------- 
  declare @LVC_FamilyCode           varchar(10) 
  declare @LVC_BusinessUnitLogo     varchar(100)
  ----------------------------------------------
  select top 1 @LVC_FamilyCode = QI.FamilyCode
  from   QUOTES.dbo.Quoteitem QI with (nolock)
  where  QI.QuoteIDSeq = @IPVC_QuoteIDSeq
  ----------------------------------------------
  --Final Select
  ----------------------------------------------
  select Top 1 @LVC_BusinessUnitLogo = coalesce(F.BusinessUnitLogo,'RealPage')
  from   Products.dbo.Family F with (nolock)
  where  F.Code = @LVC_FamilyCode
  ----------------------------------------------
  return coalesce(@LVC_BusinessUnitLogo,'RealPage')  
END
GO
