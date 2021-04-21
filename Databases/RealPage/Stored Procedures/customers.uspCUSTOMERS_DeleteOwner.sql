SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_DeleteOwner
-- Description     : This procedure deletes the Owner from the database.
-- Input Parameters: 1. @IPVC_CompanyIDSeq varchar(11)
--
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_DeleteOwner]  
--                   @IPVC_CompanyIDSeq = 'A0000000001'
--	
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 03/12/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_DeleteOwner] (@IPVC_OwnerIDSeq VARCHAR(50)
                                                  )
	
AS
BEGIN
  set nocount on;
  ----------------------------------------------
  --Step 1 : Delete relationship from CustomerOwner
  --         for passed @IPVC_OwnerIDSeq
  DELETE FROM  Customers.dbo.CustomerOwner
  WHERE  OwnerIDSeq = @IPVC_OwnerIDSeq

  --Step 1.5 : If Passed @IPVC_OwnerIDSeq is also a PMC and 
  --           a owner, since the Owner relationship is deleted
  --           as part of Delete Owner operation,
  --           this PMC-OWNER record should be updated to strictly 
  --           as PMC/

  if exists (select top 1 1 
             from   Customers.dbo.Company with(nolock)
             where  IDSeq = @IPVC_OwnerIDSeq
             and    OwnerFlag = 1 and PMCFlag=1
            )
  begin
    Update Customers.dbo.Company 
    set    OwnerFlag = 0,
           PMCFlag   = 1
    where  IDSeq = @IPVC_OwnerIDSeq
    and    OwnerFlag = 1 and PMCFlag=1
  end
  -----------------------------------------------
  --Step 2 : If Passed @IPVC_OwnerIDSeq is strictly a
  --         owner with OwnerFlag = 1 and PMCFlag=0
  --         then delete all traces of this orphan
  --         owner record from the system.
  if exists (select top 1 1 
             from   Customers.dbo.Company with(nolock)
             where  IDSeq = @IPVC_OwnerIDSeq
             and    OwnerFlag = 1 and PMCFlag=0
            )
  begin
    Delete from Customers.dbo.Address 
    where  CompanyIDSeq = @IPVC_OwnerIDSeq
    and    PropertyIDseq is NULL
  
    DELETE FROM Customers.dbo.Company
    WHERE  IDSeq = @IPVC_OwnerIDSeq
    and    OwnerFlag = 1 and PMCFlag=0
  end 
  ----------------------------------------------
END

GO
