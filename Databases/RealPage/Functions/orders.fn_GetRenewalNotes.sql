SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Function Name   : [fn_GetRenewalNotes]
-- Description     : Returns Resultset of all RenewalCounts with corresponding RenewalNotes
--                   for a given OrderID,OrderGroupID and OrderitemID.
--                   UI can display the full result set by renewal count starting with for this orderitem to show complete history.
--                   Else if UI requirement is to show only previous years renewal notes, then it can pick up
--                    on the Renewal Notes pertaining to immediate previous renewal count other than the current one to show.
--                   For Eg: If the current Renewalcount of the orderitemid in question is 3, then out of the resultset
--                           UI can pick up the renewal Notes corresponding to renewalcount 2 to show as previous year renewal notes.
--                   Else if the requirement is show all, then UI can display all the result set of this function in the sequence it is returned.
-- Input Parameters: ORDERIDSEQ,ORDERGROUPIDSEQ,OrderItemIDSeq
-- Syntax          :
/*
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,126195,'DMD-OSD-SDE-SDE-SACE',1,'GetRenewalNotes')
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,227599,'DMD-OSD-SDE-SDE-SACE',2,'GetRenewalNotes')
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,450321,'DMD-OSD-SDE-SDE-SACE',3,'GetRenewalNotes')


 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,126195,'DMD-OSD-SDE-SDE-SACE',1,'GetRenewalUser')
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,227599,'DMD-OSD-SDE-SDE-SACE',2,'GetRenewalUser')
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,450321,'DMD-OSD-SDE-SDE-SACE',3,'GetRenewalUser')

 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,126195,'DMD-OSD-SDE-SDE-SACE',1,'GetRenewalReviewedDate')
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,227599,'DMD-OSD-SDE-SDE-SACE',2,'GetRenewalReviewedDate')
 select  ORDERS.dbo.fn_GetRenewalNotes('O0901013748',103033,450321,'DMD-OSD-SDE-SDE-SACE',3,'GetRenewalReviewedDate')
*/
--                  
------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/11/2010      : Created (Defect 7008)
-- Author          : SRS
-- 06/09/2010      : ShashiBhushan Defect#7088 - Modified to get only previous year renewal notes.
------------------------------------------------------------------------------------------------------
CREATE FUNCTION [orders].[fn_GetRenewalNotes](@IPVC_OrderIDSeq        varchar(50),
                                       @IPBI_OrderGroupIDSeq   bigint,
                                       @IPBI_OrderItemIDSeq    bigint,
                                       @IPVC_ProductCode       varchar(30),
                                       @IPBI_RenewalCount      bigint,
                                       @IPVC_Mode              varchar(50) = 'GetRenewalNotes'
                                      )
RETURNS VARCHAR(8000)
AS
BEGIN
  ---------------------------------------
  --Declaring Local Variables
  declare @LBI_MasterOrderItemIdSeq  bigint
  declare @LVC_ReturnValue           varchar(8000)
  ---------------------------------------
  select @LBI_MasterOrderItemIdSeq = coalesce(OI.MasterOrderItemIdSeq,OI.IDSeq)
  from   Orders.dbo.Orderitem  OI with (nolock) 
  where  OI.OrderIDSeq      = @IPVC_OrderIDSeq
  and    OI.OrderGroupIDSeq = @IPBI_OrderGroupIDSeq
  and    OI.IDSeq           = @IPBI_OrderItemIDSeq
  and    OI.ProductCode     = @IPVC_ProductCode
  ---------------------------------------  
  select @LVC_ReturnValue = (case when @IPVC_Mode = 'GetRenewalNotes'
                                    then coalesce(OI.RenewalNotes,'')
                                  when @IPVC_Mode = 'GetRenewalUser'
                                    then   (case when U.IDSeq is not null 
                                                  then U.FirstName + ' ' + U.LastName collate SQL_Latin1_General_CP850_CI_AI
                                                 else ''
                                            end)
                                  when @IPVC_Mode = 'GetRenewalReviewedDate'
                                    then (case when OI.RenewalReviewedDate is not null then convert(varchar(50),OI.RenewalReviewedDate,22)
                                                else ''
                                          end)
                                  else ''
                              end)
  from   Orders.dbo.Orderitem  OI with (nolock)
  left outer Join
         Security.dbo.[User] U with (nolock)
  on     OI.RenewedByUserIDSeq = U.IDSeq 
  where  OI.OrderIDSeq      = @IPVC_OrderIDSeq
  and    OI.OrderGroupIDSeq = @IPBI_OrderGroupIDSeq
  and    coalesce(OI.MasterOrderItemIdSeq,OI.IDSeq) = @LBI_MasterOrderItemIdSeq
  and    OI.ProductCode     = @IPVC_ProductCode
  and    OI.RenewalCount    = (case when @IPBI_RenewalCount= 0 then 0 else @IPBI_RenewalCount-1 end)
  --------------------------------------- 
  RETURN coalesce(@LVC_ReturnValue,'')
  --------------------------------------- 
END
GO
