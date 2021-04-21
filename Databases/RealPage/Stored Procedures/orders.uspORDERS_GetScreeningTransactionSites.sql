SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetScreeningTransactionSites]
-- Description     : Gets sites needed for Screening Trasaction import.
-- Input Parameters: 
-- 
-- exec [uspORDERS_GetScreeningTransactionSites] '1/1/2006', '12/31/2008'
--
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Bhavesh Shah
--
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
-- Revision History: 
-- Author          : Bhavesh Shah 07/11/2008
--                 : Removed Product Code and added code get products from ScreeingProductMapping table.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetScreeningTransactionSites] 
(
  @IPD_StartDate    datetime, 
  @IPD_EndDate      datetime
) AS
BEGIN 
  select @IPD_StartDate = convert(datetime,convert(varchar(50),@IPD_StartDate,101)); 
  select @IPD_EndDate   = convert(datetime,convert(varchar(50),@IPD_EndDate,101));
  set nocount on;  
  ---------------------------------------------------------------
  -- Get the list of sites that are qulified for Screening Import.
  WITH Temp_List AS 
  (
      SELECT  DISTINCT
        O.CompanyIDSeq,
        O.PropertyIDSeq,
        O.AccountIDSeq,
        PROP.SiteMasterID,
        OI.MeasureCode
      from    
        Orders.dbo.[Order]   O  WITH (NOLOCK)
      inner join Orders.dbo.OrderItem OI WITH (NOLOCK)
      on  OI.OrderIDSeq  =  O.OrderIDSeq
      and OI.Familycode  = 'LSD'
      and OI.Statuscode  <> 'EXPD'  
      and OI.Chargetypecode = 'ACS'
      and OI.Measurecode = 'TRAN'
      and Coalesce(oi.canceldate,oi.ActivationEndDate) >= Getdate()         
      inner join Products.dbo.ScreeningProductMapping SPM WITH (NOLOCK)
      on  OI.ProductCode = SPM.ProductCode
      inner join Customers.dbo.[Property] prop WITH (NOLOCK) 
      on  O.PropertyIDSeq = prop.IDSeq
      and OI.Statuscode  <> 'EXPD'
      and not exists (select top 1 1
                      from   Orders.dbo.[Order]   XO WITH (NOLOCK)
                      inner join
                             Orders.dbo.OrderItem XI WITH (NOLOCK)
                      on     XO.Orderidseq     =  XI.Orderidseq
                      -------------
                      and    XO.AccountIDSeq   = O.AccountIDSeq
                      and    XI.ProductCode    = OI.ProductCode
                      -------------
                      and    XI.Familycode     =  'LSD'
                      and    XI.Statuscode    <> 'EXPD'                        
                      and    XI.Chargetypecode =  'ACS'
                      and    XI.Measurecode    <>  'TRAN'
                      and    XI.Frequencycode  <> 'OT'
                      and    Coalesce(XI.canceldate,XI.ActivationEndDate) >= Getdate()
                     )
     
      where OI.Measurecode = 'TRAN'
      and   Coalesce(oi.canceldate,oi.ActivationEndDate) >= Getdate()
    )                   
  -------------------------------------------------------
  -- Select the SiteMaster ID from Property List
    Select 
      CompanyIDSeq,
      PropertyIDSeq,
      AccountIDSeq,
      SiteMasterID 
    From   
      Temp_List 
    WHERE 
      nullif(SiteMasterID, '') IS NOT NULL
    -------
    UNION
    -------
    -- Select the SiteMaster ID from PropertyHistory for the given date range.
    Select 
      TL.CompanyIDSeq,
      TL.PropertyIDSeq,
      TL.AccountIDSeq,
      PH.SiteMasterID
    from 
      Customers.dbo.PropertyHistory PH with (nolock)
    inner join Temp_List TL 
    ON PH.PropertyIDSeq = TL.PropertyIDSeq AND TL.SiteMasterID IS NOT NULL
    Where 
      SystemLogDate >= @IPD_StartDate
      AND nullif(TL.SiteMasterID, '') IS NOT NULL
      AND nullif(PH.SiteMasterID, '') IS NOT NULL;
  -------------------------------------------------------
END

GO
