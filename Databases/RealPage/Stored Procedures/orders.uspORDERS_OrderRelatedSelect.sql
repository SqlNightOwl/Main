SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_OrderRelatedSelect
-- Description     : This procedure gets Order Details pertaining to passed OrderID
-- Input Parameters: 1. @IPVC_OrderID   as varchar(10)
--                   
-- OUTPUT          : RecordSet of company OrderIDSeq,CreatedDate,
--                   StatusCode     if PropertyIDSeq is null  
--
--                   RecordSet of Property OrderIDSeq,CreatedDate,
--                   StatusCode,ApprovedDate,
--                   and RecordSet of company        
--                   
-- Code Example    : Exec ORDERS.DBO.uspORDERS_OrderRelatedSelect 'O0810000130'
-- 
-- 
-- Revision History:
-- Author          : TMN
-- 12/12/2006      : Stored Procedure Created.
-- 02/19/2008      : Naval Kishore Modified the procedure to get related PMC Orders.  

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_OrderRelatedSelect] (@IPVC_OrderID varchar(50)                                                       
                                                      )
AS
BEGIN 
  set nocount on;
  declare @LV_AccountID  varchar(50)
  select Top 1 @LV_AccountID=o1.AccountIdseq 
  from   Orders.dbo.[order] o1 with (nolock)
  where  o1.OrderIDSeq=@IPVC_OrderID

  SELECT  top 3 o.AccountIDSeq                                         as AccountIDSeq,
                        Convert(bit, 1)                                as PMCFlag,
                        o.OrderIDSeq                                   as ROrderIDSeq,
                        convert(varchar (15),o.CreatedDate,101)        as RCreatedDate,
                        ost.Name                                       as RStatusCode
  from   Orders.dbo.[order] o with (nolock)
  inner join
         Orders.dbo.OrderStatusType ost with (nolock)
  on    ost.Code = o.StatusCode
  and   o.AccountIDSeq=@LV_AccountID
  and   o.OrderIDSeq <> @IPVC_OrderID
  where o.AccountIDSeq=@LV_AccountID	
  and 	o.OrderIDSeq <> @IPVC_OrderID          
  ORDER by o.OrderIDSeq desc,RCreatedDate desc
    
  /********************************/ 
  SELECT  top 5 
              isnull(I.InvoiceIDSeq,'N/A')                               as RInvoiceIDSeq,
              (case when I.PrintFlag=1 then convert(varchar(15),I.InvoiceDate,101)
                    else convert(varchar(12),I.CreatedDate,101)
               end)                                                      as RInvoiceDate,
              (case when I.PrintFlag=1 then 'Printed' 
                    else 'Pending'
               end)                                                      as RpaymentDetails                  
  from   Invoices.dbo.invoice I (nolock)
  where  I.AccountIDSeq=@LV_AccountID 
  and    exists (select top 1 1
                 from   Invoices.dbo.InvoiceItem II (nolock)
                 where  I.InvoiceIDSeq=II.InvoiceIDSeq
                 --->and    II.OrderIDSeq  =@IPVC_OrderID
                )	          
  ORDER by convert(int,I.PrintFlag) asc,RInvoiceIDSeq desc

    /********************************/

END -- PROCEDURE ENDS
 

--Exec ORDERS.DBO.uspORDERS_OrderRelatedSelect 100





GO
