SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_RelatedReversedCredits]
-- Description     : This stored procedure gets the orders related to the specified Invoice.
-- Input Parameters: @IPVC_CreditID varchar(15)
-- 
-- OUTPUT          : RecordSet of AccountIDSeq, OrderIDSeq, CreatedDate, StatusCode
--
-- Code Example    : Exec INVOICES.DBO.[uspINVOICES_RelatedReversedCredits]  @IPVC_CreditID = 'R0805000080'
--	
-- Revision History:
-- Author          : Naval Kishore
-- 05/07/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_RelatedReversedCredits] (@IPVC_CreditID VARCHAR(50))	
AS
BEGIN
  
  /***************************************************************************/
  /************************** Related reversed Credits ********************************/
  /***************************************************************************/
	SELECT top 1 
           CM.CreditMemoIDSeq                        AS ApplyToCreditMemoIDSeq,        
           convert(VARCHAR(15),CM.ApprovedDate,101)  AS ApprovedDate,  
           CST.Name                                  AS CreditStatusCode            
    FROM        Invoices.dbo.[CreditMemo] CM         WITH (NOLOCK) 
    INNER JOIN  Invoices.dbo.CreditStatusType CST    WITH (NOLOCK)  
       ON       CST.Code               = CM.CreditStatusCode  
    WHERE       ApplyToCreditMemoIDSeq = @IPVC_CreditID  
  /***************************************************************************/

END

GO
