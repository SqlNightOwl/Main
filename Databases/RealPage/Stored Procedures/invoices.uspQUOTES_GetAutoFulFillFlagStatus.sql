SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : QUOTES  
-- Procedure Name  : uspQUOTES_GetAutoFulFillFlagStatus  
-- Description     : This procedure checks and returns if the Quote has any product that qualify AutoFulfillFlag  
--                   If This proc value AutoFulfillFlag is 1, then Delay ACS/ANC Check box will be Shown so user can check if they want.  
--                   If This proc value AutoFulfillFlag is 0, then Delay ACS/ANC Check box will be Shown,kept unchecked and Greyout.  
--  
-- Input Parameters: @IPVC_QuoteID  varchar(50),  
  
-- OUTPUT          : Gets existence of AutoFulfillFlag product in the Quote.  
--                     
--  
-- Code Example    : Exec QUOTES.[dbo].[uspQUOTES_GetAutoFulFillFlagStatus] @IPVC_QuoteIDSeq = 'Q0000000046'  
-- Revision History:  
-- Author          : Anand Chakravarthy  
--                 : Stored Procedure Created.  
--   
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspQUOTES_GetAutoFulFillFlagStatus](@IPVC_QuoteIDSeq varchar(20)  
                                                           )  
AS  
BEGIN  
  set nocount on;  
  --------------------------------------  
  declare @LI_AutoFulfillFlag  int  
  select  @LI_AutoFulfillFlag = 0  
  --------------------------------------  
  if exists (select top 1 1  
             from   Quotes.dbo.QuoteItem QI with (nolock)  
             inner join  
                    Products.dbo.Product P with (nolock)  
             on     QI.ProductCode = P.Code  
             and    QI.PriceVersion= P.PriceVersion  
             and    QI.QuoteIDSeq  = @IPVC_QuoteIDSeq   
             and    P.AutoFulfillFlag=1  
            )  
  begin  
    select @LI_AutoFulfillFlag=1  
  end  
  else  
  begin  
    select @LI_AutoFulfillFlag = 0  
  end  
  --------------------------------------    
  select @LI_AutoFulfillFlag as AutoFulfillFlag  
end  
GO
