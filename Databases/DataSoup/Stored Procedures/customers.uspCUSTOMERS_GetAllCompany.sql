SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspCUSTOMERS_GetAllCompany @IPVC_RETURNTYPE = 'XML1', @IPVC_MATCHCHAR = 'N'
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetAllCompany] (@IPVC_RETURNTYPE  varchar(100) = 'XML',
                                                @IPVC_MATCHCHAR varchar(5) = 'ALL')
AS
BEGIN
  set nocount on 
  -----------------------------------------------------------------------------------------------------
  ---Declaring local variables
  declare @LT_AllCompany   table (seq                       int identity(1,1) not null,                                     
                                  companyid                 varchar(50)       not null default '0',
                                  companyname               varchar(300)      not null default '',  
                                  quotes                    int               not null default 0 
                                 )
   -----------------------------------------------------------------------------------------------------
  if exists (select Top 1 1 from CUSTOMERS.DBO.Company (nolock)
                            where (
                                    (@IPVC_MATCHCHAR = 'ALL')
                                    or
                                    ( (@IPVC_MATCHCHAR = '0') and (isnumeric(substring(name, 1, 1)) = 1) )
                                    or
                                    (substring(name, 1, 1) = @IPVC_MATCHCHAR)
                                  )
            )
  begin
    insert into @LT_AllCompany(companyid,companyname,quotes)
    select coalesce(A.IDSeq,'0')               as companyid,
           coalesce(A.name,'')                 as companyname,
           (select count(Q.QuoteIDSeq) 
            from   QUOTES.dbo.Quote Q (nolock)
            where  Q.CustomerIDSeq=A.IDSeq)    as quotes
    from  CUSTOMERS.DBO.Company A (nolock)
    where (
            (@IPVC_MATCHCHAR = 'ALL')
            or
            ( (@IPVC_MATCHCHAR = '0') and (isnumeric(substring(A.name, 1, 1)) = 1) )
            or
            (substring(A.name, 1, 1) = @IPVC_MATCHCHAR)
          )
  end
  else
  begin
    insert into @LT_AllCompany(companyid,companyname,quotes)
    select '0'  as companyid,
           ''   as companyname,
           0    as quotes               
  end 
  -------------------------------------------------------------------------------
  --Final Select 
  -------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select companyid,companyname,quotes from @LT_AllCompany
    order by companyname asc
    FOR XML raw ,ROOT('company'), TYPE    
  end
  else 
  begin
    select companyid,companyname,quotes from @LT_AllCompany 
    order by companyname asc
  end
END

GO
