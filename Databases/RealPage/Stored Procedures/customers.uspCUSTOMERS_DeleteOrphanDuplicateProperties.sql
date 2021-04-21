SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_DeleteOrphanDuplicateProperties]
-- Description     : This is the Sanity SP called at tail end of Import Properties functionality to 
--                   delete any Orphan duplicate properties (not having a account) that may be inadventently imported in duplicate.
-- Input Parameters: @IPVC_CompanyIDSeq
-- Syntax          : Exec CUSTOMERS.dbo.uspCUSTOMERS_DeleteOrphanDuplicateProperties @IPVC_CompanyIDSeq='C0901000165'
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_DeleteOrphanDuplicateProperties] (@IPVC_CompanyIDSeq          varchar(50)     -- CompanyIDSeq (Mandatory)
                                                                       )
AS
BEGIN 
  set nocount on;  
  -----------------------------------------------------
  create table #LT_DuplicateOrphanProperties (SortSeq               int not null identity(1,1) Primary Key,
                                              DeletePropertyID      varchar(50),
                                              RetainPropertyID      varchar(50),
                                              CompanyIDSeq          varchar(50),
                                              PropertyName          varchar(500),
                                              Phase                 varchar(500),
                                              AddressLine1          varchar(500),
                                              AddressLine2          varchar(500),
                                              City                  varchar(500),
                                              State                 varchar(500),
                                              Zip                   varchar(500),
                                              Country               varchar(500),
                                              duplicatecount        int
                                             )

  -----------------------------------------------------
  ;WITH DUPCTE (RetainPropertyID,CompanyIDSeq,PropertyName,Phase,
                AddressLine1,AddressLine2,City,State,Zip,Country,duplicatecount) 
   as 
     (select Min(P.IDSeq)                                                as RetainPropertyID,
             P.PMCIDSeq                                                  as CompanyIDSeq, 
             ltrim(rtrim(P.Name))                                        as PropertyName,
             coalesce(nullif(ltrim(rtrim(P.phase)),''),'ABCDEF')         as Phase,
             coalesce(nullif(ltrim(rtrim(AP.AddressLine1)),''),'ABCDEF') as AddressLine1,
             coalesce(nullif(ltrim(rtrim(AP.AddressLine2)),''),'ABCDEF') as AddressLine2,
             coalesce(nullif(ltrim(rtrim(AP.City)),''),'ABCDEF')         as City,
             coalesce(nullif(ltrim(rtrim(AP.State)),''),'ABCDEF')        as State,
             coalesce(nullif(ltrim(rtrim(left(AP.Zip,5))),''),'ABCDEF')  as Zip,
             coalesce(nullif(ltrim(rtrim(AP.Country)),''),'ABCDEF')      as Country,
             count(1)                                                    as duplicatecount             
      from  customers.dbo.Property P with (nolock) 
      left outer join
            customers.dbo.Address  AP with (nolock)
      on    P.PMCIDSeq = AP.CompanyIDSeq
      and   P.IDSeq    = AP.PropertyIDSeq
      and   AP.Addresstypecode = 'PRO'
      and   AP.PropertyIDSeq is not null
      and   P.PMCIDSeq      = @IPVC_CompanyIDSeq
      and   AP.CompanyIDSeq = @IPVC_CompanyIDSeq
      where P.PMCIDSeq = @IPVC_CompanyIDSeq
      and   Not exists (select top 1 1
                        from   CUSTOMERS.dbo.Account A with (nolock)
                        where  A.CompanyIDSeq = @IPVC_CompanyIDSeq
                        and    A.CompanyIDSeq = P.PMCIDSeq
                        and    A.PropertyIDseq= P.IDSeq
                        and    A.PropertyIDSeq is not null
                       ) ---Account does not exists, before the duplicate can be removed
      and   Not exists (select top 1 1
                        from   ORDERS.dbo.[ORDER] O with (nolock)
                        where  O.CompanyIDSeq = @IPVC_CompanyIDSeq
                        and    O.CompanyIDSeq = P.PMCIDSeq
                        and    O.PropertyIDseq= P.IDSeq
                        and    O.PropertyIDSeq is not null
                       ) ---Order does not exists, before the duplicate can be removed   
      group by  P.PMCIDSeq
               ,ltrim(rtrim(P.Name))                                        
               ,coalesce(nullif(ltrim(rtrim(P.phase)),''),'ABCDEF')         
               ,coalesce(nullif(ltrim(rtrim(AP.AddressLine1)),''),'ABCDEF') 
               ,coalesce(nullif(ltrim(rtrim(AP.AddressLine2)),''),'ABCDEF') 
               ,coalesce(nullif(ltrim(rtrim(AP.City)),''),'ABCDEF')         
               ,coalesce(nullif(ltrim(rtrim(AP.State)),''),'ABCDEF')        
               ,coalesce(nullif(ltrim(rtrim(left(AP.Zip,5))),''),'ABCDEF')  
               ,coalesce(nullif(ltrim(rtrim(AP.Country)),''),'ABCDEF')      
      having count(1) > 1
     ),
  PROCTE (DeletePropertyID,CompanyIDSeq,PropertyName,Phase,
          AddressLine1,AddressLine2,City,State,Zip,Country) 
   as 
     (select P.IDSeq                                                     as DeletePropertyID,
             P.PMCIDSeq                                                  as CompanyIDSeq, 
             ltrim(rtrim(P.Name))                                        as PropertyName,
             coalesce(nullif(ltrim(rtrim(P.phase)),''),'ABCDEF')         as Phase,
             coalesce(nullif(ltrim(rtrim(AP.AddressLine1)),''),'ABCDEF') as AddressLine1,
             coalesce(nullif(ltrim(rtrim(AP.AddressLine2)),''),'ABCDEF') as AddressLine2,
             coalesce(nullif(ltrim(rtrim(AP.City)),''),'ABCDEF')         as City,
             coalesce(nullif(ltrim(rtrim(AP.State)),''),'ABCDEF')        as State,
             coalesce(nullif(ltrim(rtrim(left(AP.Zip,5))),''),'ABCDEF')  as Zip,
             coalesce(nullif(ltrim(rtrim(AP.Country)),''),'ABCDEF')      as Country                
      from  customers.dbo.Property P with (nolock) 
      left outer join
            customers.dbo.Address  AP with (nolock)
      on    P.PMCIDSeq = AP.CompanyIDSeq
      and   P.IDSeq    = AP.PropertyIDSeq
      and   AP.Addresstypecode = 'PRO'
      and   AP.PropertyIDSeq is not null
      and   P.PMCIDSeq      = @IPVC_CompanyIDSeq
      and   AP.CompanyIDSeq = @IPVC_CompanyIDSeq
      where P.PMCIDSeq      = @IPVC_CompanyIDSeq
      and   Not exists (select top 1 1
                        from   CUSTOMERS.dbo.Account A with (nolock)
                        where  A.CompanyIDSeq = @IPVC_CompanyIDSeq
                        and    A.CompanyIDSeq = P.PMCIDSeq
                        and    A.PropertyIDseq= P.IDSeq
                        and    A.PropertyIDSeq is not null
                       ) ---Account does not exists, before the duplicate can be removed
      and   Not exists (select top 1 1
                        from   ORDERS.dbo.[ORDER] O with (nolock)
                        where  O.CompanyIDSeq = @IPVC_CompanyIDSeq
                        and    O.CompanyIDSeq = P.PMCIDSeq
                        and    O.PropertyIDseq= P.IDSeq
                        and    O.PropertyIDSeq is not null
                       ) ---Order does not exists, before the duplicate can be removed   
     )
  insert into #LT_DuplicateOrphanProperties(DeletePropertyID,RetainPropertyID,
                                            CompanyIDSeq,PropertyName,Phase,
                                            AddressLine1,AddressLine2,City,State,Zip,Country,
                                            duplicatecount)
  select  PROCTE.DeletePropertyID,
          DUPCTE.RetainPropertyID,
          DUPCTE.CompanyIDSeq,
          DUPCTE.PropertyName,
          DUPCTE.Phase,
          DUPCTE.AddressLine1,
          DUPCTE.AddressLine2,
          DUPCTE.City,
          DUPCTE.State,
          DUPCTE.Zip,
          DUPCTE.Country,
          DUPCTE.duplicatecount
  from   DUPCTE
  inner join
         PROCTE
  on     DUPCTE.CompanyIDSeq = PROCTE.CompanyIDSeq
  and    DUPCTE.CompanyIDSeq = @IPVC_CompanyIDSeq
  and    PROCTE.CompanyIDSeq = @IPVC_CompanyIDSeq
  and    DUPCTE.RetainPropertyID <>  PROCTE.DeletePropertyID
  and    DUPCTE.PropertyName = PROCTE.PropertyName
  and    DUPCTE.Phase        = PROCTE.Phase
  and    DUPCTE.AddressLine1 = PROCTE.AddressLine1
  and    DUPCTE.AddressLine2 = PROCTE.AddressLine2
  and    DUPCTE.City         = PROCTE.City
  and    DUPCTE.State        = PROCTE.State
  and    DUPCTE.Zip          = PROCTE.Zip
  and    DUPCTE.Country      = PROCTE.Country
  where
        Not exists (select top 1 1
                    from   CUSTOMERS.dbo.Account A with (nolock)
                    where  A.CompanyIDSeq = @IPVC_CompanyIDSeq
                    and    A.CompanyIDSeq = PROCTE.CompanyIDSeq
                    and    A.PropertyIDseq= PROCTE.DeletePropertyID
                    and    A.PropertyIDSeq is not null
                   ) ---Account does not exists, before the duplicate can be removed
  and   Not exists (select top 1 1
                    from   ORDERS.dbo.[ORDER] O with (nolock)
                    where  O.CompanyIDSeq = @IPVC_CompanyIDSeq
                    and    O.CompanyIDSeq = PROCTE.CompanyIDSeq
                    and    O.PropertyIDseq= PROCTE.DeletePropertyID
                    and    O.PropertyIDSeq is not null
                   ) ---Order does not exists, before the duplicate can be removed 
  ---------------------------------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION DPA;
      Delete Addr
      from   CUSTOMERS.dbo.Address         Addr with (nolock)
      inner join
             #LT_DuplicateOrphanProperties S with (nolock)
      on     Addr.CompanyIDSeq  = S.CompanyIDSeq
      and    Addr.PropertyIDSeq = S.DeletePropertyID
      and    Addr.PropertyIDSeq is not null
      and    Addr.AddressTypecode in ('PRO','PBT','PST')
      and    Addr.CompanyIDSeq  = @IPVC_CompanyIDSeq
      where
           Not exists (select top 1 1
                       from   CUSTOMERS.dbo.Account A with (nolock)
                       where  A.CompanyIDSeq = @IPVC_CompanyIDSeq
                       and    A.CompanyIDSeq = S.CompanyIDSeq
                       and    A.PropertyIDseq= S.DeletePropertyID
                       and    A.PropertyIDSeq is not null
                      ) ---Account does not exists, before the duplicate can be removed
      and   Not exists (select top 1 1
                        from   ORDERS.dbo.[ORDER] O with (nolock)
                        where  O.CompanyIDSeq = @IPVC_CompanyIDSeq
                        and    O.CompanyIDSeq = S.CompanyIDSeq
                        and    O.PropertyIDseq= S.DeletePropertyID
                        and    O.PropertyIDSeq is not null
                       ); ---Order does not exists, before the duplicate can be removed 

      DELETE PRO
      FROM   CUSTOMERS.DBO.Property PRO with (nolock)
      inner join
             #LT_DuplicateOrphanProperties S with (nolock)
      on     PRO.PMCIDSeq      = S.CompanyIDSeq
      and    PRO.IDSeq         = S.DeletePropertyID
      and    PRO.PMCIDSeq      = @IPVC_CompanyIDSeq
      where
        Not exists (select top 1 1
                    from   CUSTOMERS.dbo.Account A with (nolock)
                    where  A.CompanyIDSeq = @IPVC_CompanyIDSeq
                    and    A.CompanyIDSeq = S.CompanyIDSeq
                    and    A.PropertyIDseq= S.DeletePropertyID
                    and    A.PropertyIDSeq is not null
                   ) ---Account does not exists, before the duplicate can be removed
      and   Not exists (select top 1 1
                        from   ORDERS.dbo.[ORDER] O with (nolock)
                        where  O.CompanyIDSeq = @IPVC_CompanyIDSeq
                        and    O.CompanyIDSeq = S.CompanyIDSeq
                        and    O.PropertyIDseq= S.DeletePropertyID
                        and    O.PropertyIDSeq is not null
                       ); ---Order does not exists, before the duplicate can be removed
      ---------------------------------------------------------------------------------
      COMMIT TRANSACTION DPA; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION DPA;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION DPA;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION DPA;        
    return;                  
  END CATCH;
  ---------------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_DuplicateOrphanProperties') is not null) 
  begin
    drop table #LT_DuplicateOrphanProperties;
  end;
  ---------------------------------------------------------------------------------
END
GO
