SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_GetAccountsForPullList]
-- Description     : This procedure inserts Account for a Pull List pertaining to passed AccountID
-- Input Parameters: 1. @IPVC_PullListIDSeq   AS varchar(10)
--                   
-- OUTPUT          : RecordSet of IDSEq is generated
--
--                   
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_GetAccountsForPullList '9'
-- 
-- 
-- Revision History:
-- Author          : Naval Kishore SIngh
-- 23/09/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetAccountsForPullList](@IPVC_PullListIDSeq bigint)
AS
BEGIN     
  set nocount on;
  ------------------------------------
  select  p.title	   as Title,               
          p.Description    as [Description]           
  from    invoices.dbo.PullList p with (nolock) 
  Where   p.IDSeq= @IPVC_PullListIDSeq 
  ------------------------------------
  select source.AccountID        as AccountID,
         source.[Name]           as [Name],
         source.Accounttypecode  as Accounttypecode
  from   
        (select distinct 
                pa.AccountIDSEQ    as AccountID,
	        pa.AccountIDSEQ + ' ' +
	             (case when (A.AccountTypeCode = 'AHOFF' and A.PropertyIdSeq is null)
                           then C.Name
                      when (A.AccountTypeCode = 'APROP' and A.PropertyIdSeq is not null)
                           then P.Name
                      else ''
               	      end) as [Name],
                A.Accounttypecode as Accounttypecode,
                DENSE_RANK() OVER (ORDER BY  A.CompanyIDSeq ASC,
                                             (case when A.PropertyIDSeq is null then 'A'
                                                   else 'Z'
                                              end) ASC,
                                              coalesce(P.Name,C.Name) asc
                                    ) as RankNo       
         from   invoices.dbo.PullListAccounts pa with (nolock)
         inner join
	        Customers.dbo.account A with (nolock)
         on     pa.AccountIDSEQ = A.IDSeq
         and    pa.PullListidSeq=@IPVC_PullListIDSeq
         inner join
          	Customers.dbo.company c with (nolock)
         on     A.CompanyIDSeq = C.IdSeq
         left outer join
	        Customers.dbo.Property P with (nolock)
         on     A.PropertyIdseq = P.IdSeq
        ) source
  order by RankNo asc
END

GO
