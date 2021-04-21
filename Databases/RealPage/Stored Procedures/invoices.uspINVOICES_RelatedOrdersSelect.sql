SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_RelatedOrdersSelect
-- Description     : This stored procedure gets the orders related to the specified Invoice.
-- Input Parameters: @IPVC_InvoiceID varchar(15)
-- 
-- OUTPUT          : RecordSet of AccountIDSeq, OrderIDSeq, CreatedDate, StatusCode
--
-- Code Example    : Exec INVOICES.DBO.uspINVOICES_RelatedOrdersSelect  @IPVC_InvoiceID = 'I1007003534'
--	
-- Revision History:
-- Author          : STA
-- 04/13/2007      : Stored Procedure Created.
-- 08/05/2010      : Shashi Bhushan - Defect#7952 - Credit Reversals in OMS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_RelatedOrdersSelect] (@IPVC_InvoiceID varchar(50))	
AS
BEGIN
  /***************************************************************************/
  /************************** Related Invoices *******************************/
  /***************************************************************************/
	SELECT O.AccountIDSeq                            as AccountIDSeq,
               O.orderidseq                              as OrderIDSeq,
               convert(varchar (15),o.CreatedDate,101)   as CreatedDate,
               OST.Name                                  as StatusCode          
  FROM         Orders.dbo.[Order] O with (nolock)
  INNER JOIN  Orders.dbo.OrderStatusType OST (nolock)
    ON        ost.Code = o.StatusCode
    AND       O.orderidseq IN
                      (
                      /****************************************************/
                        SELECT DISTINCT TOP 3 IG.OrderIDSeq 
                        FROM            Invoices.dbo.InvoiceItem II with (nolock)
                        INNER JOIN      Invoices.dbo.InvoiceGroup IG with (nolock)
                          ON            II.InvoiceGroupIDSeq = IG.IDSeq
                          AND           IG.InvoiceIDSeq = @IPVC_InvoiceID
                          AND           II.InvoiceIDSeq = @IPVC_InvoiceID
                      /****************************************************/
                      )
  /***************************************************************************/

  /***************************************************************************/
  /************************** Related Credits ********************************/
  /***************************************************************************/
	SELECT      TOP 3
              CM.CreditMemoIDSeq                        as CreditIDSeq,
             (case when CM.CreditStatusCode = 'APPR' then convert(varchar(15),CM.ApprovedDate,101)
                   when CM.CreditStatusCode = 'PAPR' then convert(varchar(15),CM.CreatedDate,101)
                   else convert(varchar(15),CM.ModifiedDate,101)
              end)                                      as CreditCreatedDate,
              case when exists (SELECT top 1 ApplyToCreditMemoIDSeq 
                                FROM   Invoices.dbo.CreditMemo CrM
                                WHERE  CrM.ApplyToCreditMemoIDSeq = CM.CreditMemoIDSeq 
                                   and CrM.InvoiceIDSeq = @IPVC_InvoiceID
                                   and CrM.CreditMemoReversalFlag=1 and CrM.CreditStatusCode = 'APPR') 
                   then 'Reversed'
               else CST.Name
              end                                       as CreditStatusCode          
  FROM        Invoices.dbo.[CreditMemo] CM with (nolock)  
  INNER JOIN  Invoices.dbo.CreditStatusType CST with (nolock)
    ON        CST.Code        = CM.CreditStatusCode
   AND        CM.InvoiceIDSeq = @IPVC_InvoiceID
  ORDER BY    CM.CreditMemoIDSeq DESC,CM.CreatedDate ASC
  /***************************************************************************/

END
GO
