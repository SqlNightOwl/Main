SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_ValidateForDuplicateSiteMasterID] (
                                                                       @IPVC_SiteMasterID  varchar(50) = '',
                                                                       @IPVC_CustomerID    varchar(22) = '',
                                                                       @IPVC_PropertyID    varchar(22) = ''
                                                                     )
AS
BEGIN
  set nocount on;
  -------------------------------------------------------------------------------------------------------------
  declare @LT_DuplicateResults table
                                     (sortseq       int not null  identity(1,1) primary key,
                                      SiteMasterID  varchar(50),
                                      CompanyID     varchar(50),
                                      CompanyName   varchar(255),
                                      PropertyID    varchar(50),
                                      PropertyName  varchar(255),
                                      Status        varchar(50),
                                      Type          varchar(50)
                                     )                               
  -------------------------------------------------------------------------------------------------------------
  Insert into @LT_DuplicateResults(SiteMasterID,CompanyID,CompanyName,PropertyID,PropertyName,status,Type)
  select @IPVC_SiteMasterID as SiteMasterID,C.IDSeq as CompanyID,C.Name as CompanyName,'' as PropertyID,'' as PropertyName,
         (case when C.StatusTypecode = 'ACTIV' then 'Active' 
               when C.StatusTypecode = 'INACT' then 'InActive'
               else '' 
          end),'Company' as Type
  from   Customers.dbo.Company C with (nolock)
  where  C.IDSeq <> @IPVC_CustomerID
  and    nullif(C.SiteMasterID,'') is not null
  and    C.SiteMasterID     = @IPVC_SiteMasterID
  and    C.StatusTypecode   = 'ACTIV'
  ------
  UNION
  ------
  select @IPVC_SiteMasterID as SiteMasterID,C.IDSeq as CompanyID,C.Name as CompanyName,P.IDSeq as PropertyID,P.Name as PropertyName,
         (case when C.StatusTypecode = 'ACTIV' then 'Active' 
               when C.StatusTypecode = 'INACT' then 'InActive'
               else '' 
          end),'Property' as Type
  from   Customers.dbo.Property P with (nolock)
  inner join
         Customers.dbo.Company  C with (nolock)
  on     P.PMCIDSeq = C.IDSeq
  and    P.IDSeq <> @IPVC_PropertyID
  and    nullif(P.SiteMasterID,'') is not null
  and    P.SiteMasterID = @IPVC_SiteMasterID
  and    P.StatusTypecode   = 'ACTIV'
  where  P.IDSeq <> @IPVC_PropertyID
  and    nullif(P.SiteMasterID,'') is not null
  and    P.SiteMasterID = @IPVC_SiteMasterID
  and    P.StatusTypecode   = 'ACTIV'
  Order by CompanyName ASC,PropertyName ASC
  -------------------------------------------------------------------------------------------------------------
  --Final Select to UI
  select CompanyID,CompanyName,PropertyID,PropertyName,Type,Status,SiteMasterID
  from   @LT_DuplicateResults
  order by sortseq asc;
  -------------------------------------------------------------------------------------------------------------
END
GO
