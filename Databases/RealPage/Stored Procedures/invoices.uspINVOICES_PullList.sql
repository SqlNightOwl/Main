SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : [INVOICES]
-- Procedure Name  : uspINVOICES_PullList
-- Description     : This procedure returns the accounts based on the parameters
-- Input Parameters: As Defined below
-- 
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU
-- Code Example    : 

-- Revision History:
-- Author          : SRS
-- 08/07/2008      : Stored Procedure Created
------------------------------------------------------------------------------------------------------
CREATE procedure [invoices].[uspINVOICES_PullList](
                                              @IPVC_CompanyName     varchar(100), 
                                              @IPVC_PropertyName    varchar(100), 
                                              @IPVC_City            varchar(100), 
                                              @IPVC_State           varchar(100),                                             
                                              @IPVC_PullListIDSeq   bigint='' 						
                                             )
                                                  
AS
BEGIN      
  set nocount on;
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  If (@IPVC_PullListIDSeq = '' or @IPVC_PullListIDSeq is null)
  begin
    WITH tablefinal AS
       (select DENSE_RANK() OVER (ORDER BY  source.CompanyIDSeq ASC,
                                           (case when source.PropertyIDSeq is null then 'A'
                                                 else 'Z'
                                            end) ASC,
                                            source.AccountName asc
                                 ) as RankNo,
                source.AccountID         as AccountID,
                source.[Name]            as [Name],
                source.Accounttypecode   as Accounttypecode,
                source.CompanyIDSeq      as CompanyID,
                source.propertyidseq     as PropertyID
        from (
              ------------------------------------------------------------
              --->1.  Get all Company Accounts for passed criteria
              ---     and when @IPVC_PropertyName = '' 
              ------------------------------------------------------------
              select DISTINCT
                     A.IDSeq                 as AccountID,
                     A.Accounttypecode       as Accounttypecode,
                     C.Name                  as AccountName,
                     A.CompanyIDSeq          as CompanyIDSeq,
                     A.PropertyIDSeq         as PropertyIDSeq,
                     A.IDSeq + '   ' +C.Name as [Name]                     
              from   CUSTOMERS.dbo.Account A with (nolock)
              inner join
                     CUSTOMERS.dbo.Company C with (nolock)
              on     A.CompanyIDSeq    = C.IDSeq
              and    A.Accounttypecode = 'AHOFF'
              and    A.PropertyIDSeq   is null
              and    @IPVC_PropertyName = ''
              and    C.Name         like '%' + @IPVC_CompanyName + '%'
              inner join
                     CUSTOMERS.dbo.Address AddrCom with (nolock)
              on     AddrCom.CompanyIDSeq    = C.IDSeq
              and    AddrCom.Addresstypecode = 'COM'
              and    AddrCom.propertyIdSeq is null
              and    AddrCom.City             like '%'+ @IPVC_City  + '%'
              and    AddrCom.State            like '%'+ @IPVC_State + '%'
              -------------
              UNION
              ------------------------------------------------------------
              --->2.  When @IPVC_PropertyName <> '', get corresponding
              ---     Properties Company Account
              ------------------------------------------------------------ 
              select DISTINCT
                     A.IDSeq                 as AccountID,
                     A.Accounttypecode       as Accounttypecode,
                     C.Name                  as AccountName,
                     A.CompanyIDSeq          as CompanyIDSeq,
                     A.PropertyIDSeq         as PropertyIDSeq,
                     A.IDSeq + '   ' +C.Name as [Name]                     
              from   CUSTOMERS.dbo.Account A with (nolock)
              inner join
                     CUSTOMERS.dbo.Company C with (nolock)
              on     @IPVC_PropertyName <> ''   
              and    A.CompanyIDSeq    = C.IDSeq  
              and    A.Accounttypecode = 'AHOFF'
              and    A.PropertyIDSeq   is null                             
              and    C.IDSeq in (select COM.IDSeq
                                 from   CUSTOMERS.dbo.Company  COM  with (nolock)
                                 inner join
                                        CUSTOMERS.dbo.Property PROP with (nolock)
                                 on     @IPVC_PropertyName <> ''
                                 and    COM.IDSeq = PROP.PMCIDSEQ
                                 and    COM.Name         like '%' + @IPVC_CompanyName + '%'
                                 and    PROP.Name        like '%' + @IPVC_PropertyName + '%'                                     
                                 inner join
                                        CUSTOMERS.dbo.Address AddrPropinner with (nolock)
                                 on     @IPVC_PropertyName <> ''
                                 and    AddrPropinner.CompanyIDSeq    = COM.IDSeq
                                 and    AddrPropinner.PropertyIdseq   = PROP.IDSeq
                                 and    AddrPropinner.Addresstypecode = 'PRO'
                                 and    AddrPropinner.propertyIdSeq is not null
                                 and    AddrPropinner.City             like '%'+ @IPVC_City  + '%'
                                 and    AddrPropinner.State            like '%'+ @IPVC_State + '%'
                                )
              -------------
              UNION
              ------------------------------------------------------------
              --->3.  Get all Property Accounts for passed criteria             
              ------------------------------------------------------------
              select DISTINCT
                     A.IDSeq                  as AccountID,
                     A.Accounttypecode        as Accounttypecode,
                     P.Name                   as AccountName,
                     A.CompanyIDSeq           as CompanyIDSeq,
                     A.PropertyIDSeq          as PropertyIDSeq,
                     A.IDSeq + '   ' + P.Name as [Name]                     
              from   CUSTOMERS.dbo.Account A with (nolock)
              inner join
                     CUSTOMERS.dbo.Company C with (nolock)
              on     A.CompanyIDSeq    = C.IDSeq  
              and    A.Accounttypecode = 'APROP'
              and    A.PropertyIDSeq   is not null
              and    C.Name         like '%' + @IPVC_CompanyName + '%'
              inner join
                     CUSTOMERS.dbo.Property P with (nolock)
              on     A.Propertyidseq = P.IdSeq
              and    C.IDSeq         = P.PMCIDSeq
              and    P.Name         like '%' + @IPVC_PropertyName + '%'
              inner join
                     CUSTOMERS.dbo.Address AddrProp with (nolock)
              on     AddrProp.CompanyIDSeq    = C.IDSeq
              and    AddrProp.PropertyIdseq   = P.IDSeq
              and    AddrProp.Addresstypecode = 'PRO'
              and    AddrProp.propertyIdSeq is not null
              and    AddrProp.City             like '%'+ @IPVC_City  + '%'
              and    AddrProp.State            like '%'+ @IPVC_State + '%'
              ------------------------------------------------------------ 
             ) as source
       )
    Select *
    From   tablefinal order by RankNo asc    
  End
  Else---> Else
  begin
print 'here';
    WITH tablefinal AS
       (select DENSE_RANK() OVER (ORDER BY  source.CompanyIDSeq ASC,
                                           (case when source.PropertyIDSeq is null then 'A'
                                                 else 'Z'
                                            end) ASC,
                                            source.AccountName asc
                                 ) as RankNo,
                source.AccountID         as AccountID,
                source.[Name]            as [Name],
                source.Accounttypecode   as Accounttypecode,
                source.CompanyIDSeq      as CompanyID,
                source.propertyidseq     as PropertyID
        from (
              ------------------------------------------------------------
              --->1.  Get all Company Accounts for passed criteria
              ---     and when @IPVC_PropertyName = '' 
              ------------------------------------------------------------
              select DISTINCT
                     A.IDSeq                 as AccountID,
                     A.Accounttypecode       as Accounttypecode,
                     C.Name                  as AccountName,
                     A.CompanyIDSeq          as CompanyIDSeq,
                     A.PropertyIDSeq         as PropertyIDSeq,
                     A.IDSeq + '   ' +C.Name as [Name]                     
              from   CUSTOMERS.dbo.Account A with (nolock)
              inner join
                     CUSTOMERS.dbo.Company C with (nolock)
              on     A.CompanyIDSeq    = C.IDSeq
              and    A.Accounttypecode = 'AHOFF'
              and    A.PropertyIDSeq   is null
              and    @IPVC_PropertyName = ''
              and    C.Name         like '%' + @IPVC_CompanyName + '%'              
              inner join
                     CUSTOMERS.dbo.Address AddrCom with (nolock)
              on     AddrCom.CompanyIDSeq    = C.IDSeq
              and    AddrCom.Addresstypecode = 'COM'
              and    AddrCom.propertyIdSeq is null
              and    AddrCom.City             like '%'+ @IPVC_City  + '%'
              and    AddrCom.State            like '%'+ @IPVC_State + '%'
              -------------
              UNION
              ------------------------------------------------------------
              --->2.  When @IPVC_PropertyName <> '', get corresponding
              ---     Properties Company Account
              ------------------------------------------------------------ 
              select DISTINCT
                     A.IDSeq                 as AccountID,
                     A.Accounttypecode       as Accounttypecode,
                     C.Name                  as AccountName,
                     A.CompanyIDSeq          as CompanyIDSeq,
                     A.PropertyIDSeq         as PropertyIDSeq,
                     A.IDSeq + '   ' +C.Name as [Name]                     
              from   CUSTOMERS.dbo.Account A with (nolock)
              inner join
                     CUSTOMERS.dbo.Company C with (nolock)
              on     @IPVC_PropertyName <> ''   
              and    A.CompanyIDSeq    = C.IDSeq  
              and    A.Accounttypecode = 'AHOFF'
              and    A.PropertyIDSeq   is null                                           
              and    C.IDSeq in (select COM.IDSeq
                                 from   CUSTOMERS.dbo.Company  COM  with (nolock)
                                 inner join
                                        CUSTOMERS.dbo.Property PROP with (nolock)
                                 on     @IPVC_PropertyName <> ''
                                 and    COM.IDSeq = PROP.PMCIDSEQ
                                 and    COM.Name         like '%' + @IPVC_CompanyName + '%'
                                 and    PROP.Name        like '%' + @IPVC_PropertyName + '%'                                     
                                 inner join
                                        CUSTOMERS.dbo.Address AddrPropinner with (nolock)
                                 on     @IPVC_PropertyName <> ''
                                 and    AddrPropinner.CompanyIDSeq    = COM.IDSeq
                                 and    AddrPropinner.PropertyIdseq   = PROP.IDSeq
                                 and    AddrPropinner.Addresstypecode = 'PRO'
                                 and    AddrPropinner.propertyIdSeq is not null
                                 and    AddrPropinner.City             like '%'+ @IPVC_City  + '%'
                                 and    AddrPropinner.State            like '%'+ @IPVC_State + '%'
                                )
              -------------
              UNION
              ------------------------------------------------------------
              --->3.  Get all Property Accounts for passed criteria             
              ------------------------------------------------------------
              select DISTINCT
                     A.IDSeq                  as AccountID,
                     A.Accounttypecode        as Accounttypecode,
                     P.Name                   as AccountName,
                     A.CompanyIDSeq           as CompanyIDSeq,
                     A.PropertyIDSeq          as PropertyIDSeq,
                     A.IDSeq + '   ' + P.Name as [Name]                     
              from   CUSTOMERS.dbo.Account A with (nolock)
              inner join
                     CUSTOMERS.dbo.Company C with (nolock)
              on     A.CompanyIDSeq    = C.IDSeq  
              and    A.Accounttypecode = 'APROP'
              and    A.PropertyIDSeq   is not null
              and    C.Name         like '%' + @IPVC_CompanyName + '%'              
              inner join
                     CUSTOMERS.dbo.Property P with (nolock)
              on     A.Propertyidseq = P.IdSeq
              and    C.IDSeq         = P.PMCIDSeq
              and    P.Name         like '%' + @IPVC_PropertyName + '%'
              inner join
                     CUSTOMERS.dbo.Address AddrProp with (nolock)
              on     AddrProp.CompanyIDSeq    = C.IDSeq
              and    AddrProp.PropertyIdseq   = P.IDSeq
              and    AddrProp.Addresstypecode = 'PRO'
              and    AddrProp.propertyIdSeq is not null
              and    AddrProp.City             like '%'+ @IPVC_City  + '%'
              and    AddrProp.State            like '%'+ @IPVC_State + '%'
              ------------------------------------------------------------ 
             ) as source
             where source.AccountID not in (select  pa.AccountIdSeq              
				            from    invoices.dbo.PullListAccounts pa with (nolock) 
				            Where   pa.pullListIDSeq= @IPVC_PullListIDSeq
                                           )
            
       )
       Select *
       From   tablefinal order by RankNo asc    
  End
END

GO
