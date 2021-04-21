SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_GetCreditApproved
-- Description     : This procedure gets the list of Credits available.
--
-- Input Parameters: @IPVC_CreditIDSeq            varchar(20),

-- OUTPUT          : A recordSet of creditStatusCode. 
--                   
--
-- Code Example    : Exec Invoices.[dbo].[uspINVOICES_GetCreditApproved] @IPVC_CreditIDSeq = '209',
-- Revision History:
-- Author          : Anand Chakravarthy
--                 : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetCreditApproved]
                 (
                   @IPVC_CreditIDSeq         varchar(50)                         
                 )
AS
BEGIN
      select creditStatusCode from Invoices.dbo.CreditMemo with (nolock)
      where CreditMemoIDSeq = @IPVC_CreditIDSeq
end

-- exec dbo.uspINVOICES_GetCreditApproved '209'

GO
