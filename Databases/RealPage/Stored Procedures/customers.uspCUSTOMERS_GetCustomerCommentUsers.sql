SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetCustomerCommentUsers]
-- Description     : This Proc returns distinct list of Users for given Company only who had created or modified
--                   alteast 1 Customer Comment for the Given Company.
--                   The results will be bound to drop down User Name : in  comments search section in UI.
-- Input Parameters: @IPVC_CompanyIDSeq
-- Syntax          : Exec CUSTOMERS.dbo.uspCUSTOMERS_GetCustomerCommentUsers @IPVC_CompanyIDSeq = 'C0901005742'
------------------------------------------------------------------------------------------------------
-- Revision History:
-- 06/10/2010      : SRS Defect7854
------------------------------------------------------------------------------------------------------
Create Procedure [customers].[uspCUSTOMERS_GetCustomerCommentUsers] (@IPVC_CompanyIDSeq varchar(50))
AS
BEGIN
  set nocount on;  
  select U.IDSeq                              as  UserIDSeq,  --UI Hidden value against the drop down shown in User Name 
         U.FirstName + ' '+ U.LastName        as  UserName    --UI Populate Drop down as User Name in Comment Section specific to Customer who created Customer Comments        
  from   SECURITY.dbo.[User] U with (nolock)
  where  exists (select top 1 1
                 from   CUSTOMERS.dbo.CustomerComment CC  with (nolock)
                 where  CC.CompanyIDSeq = @IPVC_CompanyIDSeq 
                 and   (CC.CreatedByIDSeq = U.IDSeq
                          OR
                         CC.ModifiedByIDSeq= U.IDSeq
                        )
                )
  order by  UserName ASC;
END
GO
