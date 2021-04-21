SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_OrderList
-- Description     : This procedure gets Order Details pertaining to passed 
--                        CustomerName,City,State,ZipCode,PropertyID and StatusType
-- Input Parameters:   @IPI_PageNumber       as  int, 
--                     @IPI_RowsPerPage      as  int, 
--                     @IPVC_CustomerName    as  varchar, 
--                     @IPVC_City            as  varchar, 
--                     @IPVC_State           as  varchar,
--                     @IPVC_ZipCode         as  varchar,
--                     @IPB_IsFirst          as  bit
-- OUTPUT          : RecordSet of the ID, Name, City, State of Customers from Customers..Address,
--                   Customers..Company and Customers..Account 
-- Code Example    :   Exec CUSTOMERS.dbo.[uspCUSTOMERS_CustomerList]
--                     @IPI_RowsPerPage       =   10, 
--                     @IPVC_CustomerName     =   '4000 NORTH' 
--                     @IPVC_City             =   'STILLWATER'
--                     @IPC_State             =   'OK'
--                     @IPVC_Zip              =   '74075-3402'
--                     @IPB_IsFirst           =   1
	
-- Revision History:
-- Author          : RP
-- 11/25/2006      : Stored Procedure Created.
-- 12/20/2006      : Changed by KISHORE KUMAR A S. Changed Variable Names, added variables
-- 05/17/2010      : Naval Kishore Modified to add Active Flag Filter Search, Defect #7750
-- 06/20/2011	   : Naval Kishore Modofoed to add Customer Type Filter Search, TFS #556	
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_CustomerList] (@IPI_PageNumber    int, 
                                                    @IPI_RowsPerPage   int, 
                                                    @IPVC_CustomerName varchar(100), 
                                                    @IPC_City          varchar(100), 
                                                    @IPVC_State        varchar(100),
                                                    @IPVC_ZipCode      varchar(10),						
            										@IPVC_Address      varchar(200),
                                                    @IPVC_PropertyName varchar(200),
                                                    @IPVC_OwnerName    varchar(200),
													@IPVC_ActiveFlag    varchar(15) ='',
													@IPVC_Country    varchar(100)='',
													@IPVC_CustomerType varchar(10) = ''
                                                    )  --WITH RECOMPILE -- THIS IS TO HANDLE CACHING AND LOCKING
AS
BEGIN-->Main Begin
  set nocount on;  
  --------------------------------------
  declare @LN_CHECKSUM  numeric(30,0)
  ---------------------------------------
  select @LN_CHECKSUM = checksum(coalesce(@IPVC_CustomerName,''),
                                 coalesce(@IPC_City,''),
                                 coalesce(@IPVC_State,''),
                                 coalesce(@IPVC_ZipCode,''),
                                 coalesce(@IPVC_Address,''),
                                 coalesce(@IPVC_PropertyName,''),
                                 coalesce(@IPVC_OwnerName,''),
								 coalesce(@IPVC_ActiveFlag,''),
								 coalesce(@IPVC_Country,''),
								 coalesce(@IPVC_CustomerType,'')
                                );
  ---------------------------------------
  DECLARE
	@LVI_PageNumber    int, 
	@LVI_RowsPerPage   int, 
	@LVC_CustomerName  varchar(100),
	@LVC_City          varchar(100),
	@LVC_State         varchar(100),
	@LVC_ZipCode       varchar(10),	
	@LVC_Address       varchar(200),
	@LVC_PropertyName  varchar(200), 
	@LVC_OwnerName     varchar(200),
	@LVC_ActiveFlag    varchar(5) ,
	@LVC_Country       varchar(100),
	@LVC_CustomerType  varchar(5)

  SELECT
	@LVI_PageNumber   = @IPI_PageNumber,
	@LVI_RowsPerPage  = @IPI_RowsPerPage,
	@LVC_CustomerName = @IPVC_CustomerName,
	@LVC_City         = @IPC_City,
	@LVC_State        = @IPVC_State,
	@LVC_ZipCode      = @IPVC_ZipCode,
	@LVC_Address      = @IPVC_Address,
	@LVC_PropertyName = @IPVC_PropertyName,
	@LVC_OwnerName    = @IPVC_OwnerName,
	@LVC_ActiveFlag   = @IPVC_ActiveFlag,
	@LVC_Country	  = @IPVC_Country,
	@LVC_CustomerType = @IPVC_CustomerType

    
  
  declare @LI_Min        bigint;
  declare @LI_Max        bigint;
  ---------------------------------------------------------------------------
  select  @LI_Min = (@LVI_PageNumber-1) * @LVI_RowsPerPage,
          @LI_Max = (@LVI_PageNumber)   * @LVI_RowsPerPage;
  SET ROWCOUNT @LI_Max;
  --Final Select 
  if @LN_CHECKSUM = 0
  begin
    ----------------------------------------------------------------------------
    WITH tablefinal AS 
    ----------------------------------------------------------------------------  
       (SELECT tableinner.*
        FROM
       ----------------------------------------------------------------------------
       (select  row_number() over(order by source.[Name]   asc)
                                     as RowNumber,
                source.*
        from
        (
         select distinct
          c.IDSeq                                       as ID, 
          c.Name                                        as Name, 
          a.City                                        as City, 
          a.State                                       as State, 
          a.Zip                                         as Zip, 
          a.addressline1                                as address,	
          isnull(convert(varchar(20),acct.IDSeq),'N/A') as AccountID,
          Customers.dbo.GetProperties(c.IDSeq)          as NoOfProperties
          from CUSTOMERS.dbo.Company c with (nolock)           
          inner join
               Customers.dbo.Address a with (nolock)
          on   a.CompanyIDSeq           = c.IDSeq
          and  a.AddressTypeCode        =     'COM'
          and  a.CompanyIDSeq              = a.CompanyIDSeq  
          and  coalesce(a.propertyidseq,0) = coalesce(a.propertyidseq,0)   
          --and  c.pmcflag = 1
		  AND (@LVC_CustomerType = '0'  
			OR (@LVC_CustomerType='1' and c.MultiFamilyFlag=1)
			OR (@LVC_CustomerType='2' and c.GSAEntityFlag=1)
			OR (@LVC_CustomerType='3' and c.VendorFlag=1)
			)                  
          left outer join 
               Customers.dbo.Account acct with (nolock)
          on   acct.CompanyIDSeq  = c.IDSeq 
          and  acct.CompanyIDSeq  = acct.CompanyIDSeq
          and  coalesce(acct.propertyidseq,0) = coalesce(acct.propertyidseq,0) 
          and  acct.accounttypecode = 'AHOFF'
    ) source
   -----------------------------------------------------------------------------------
    )tableinner 
 
    WHERE tableinner.RowNumber >  @LI_Min
    AND   tableinner.RowNumber <= @LI_Max
    )
    SELECT  tablefinal.RowNumber,
            tablefinal.[ID]                     as [ID],
            tablefinal.[Name]                   as [Name],
			tablefinal.City                     as City,
            tablefinal.State                    as State,
            tablefinal.Zip                      as Zip,
            tablefinal.address                  as address,
			tablefinal.AccountID                as AccountID, 
			tablefinal.NoOfProperties           as NoOfProperties
    FROM    tablefinal 
  end
  else
  begin
    ----------------------------------------------------------------------------
    WITH tablefinal AS 
    ----------------------------------------------------------------------------  
       (SELECT tableinner.*
        FROM
       ----------------------------------------------------------------------------
       (select  row_number() over(order by source.[Name]   asc)
                                     as RowNumber,
                source.*
        from
        (
         select distinct
          c.IDSeq                                       as ID, 
          c.Name                                        as Name, 
          a.City                                        as City, 
          a.State                                       as State, 
          a.Zip                                         as Zip, 
          a.addressline1                                as address,	
          isnull(convert(varchar(20),acct.IDSeq),'N/A') as AccountID,
          Customers.dbo.GetProperties(c.IDSeq)          as NoOfProperties 
          from CUSTOMERS.dbo.Company c with (nolock)           
          inner join
               Customers.dbo.Address a with (nolock)
          on   a.CompanyIDSeq           = c.IDSeq
          and  a.AddressTypeCode        =     'COM'   
          --and  c.pmcflag = 1    
          and  (
                c.Name like  '%' + @LVC_CustomerName + '%'                                         
                )
		  AND (@LVC_CustomerType = '0'  
			OR (@LVC_CustomerType='1' and c.MultiFamilyFlag=1)
			OR (@LVC_CustomerType='2' and c.GSAEntityFlag=1)
			OR (@LVC_CustomerType='3' and c.VendorFlag=1)
			)
			
		  AND ((@LVC_ActiveFlag='')or  (c.StatusTypecode LIKE '%' + @LVC_ActiveFlag + '%')) 
          and  a.CompanyIDSeq              = a.CompanyIDSeq            
          and  coalesce(a.propertyidseq,0) = coalesce(a.propertyidseq,0)                              
          and  coalesce(a.City,'')                   like  '%' + @LVC_City    + '%' 
          and  coalesce(a.State,'')                  like  '%' + @LVC_State   + '%' 
          and  coalesce(a.Zip,'')                    like  '%' + @LVC_ZipCode + '%' 
          and  coalesce(a.AddressLine1,'')	         like  '%' + @LVC_Address + '%'     
		      and	((@LVC_Country='' and 1=1) 
			         or 
				    (@LVC_Country<>'') AND  coalesce(a.CountryCode,'')	  =    coalesce(@LVC_Country,''))            
          left outer join
                (select distinct  P.PMCIDSeq, 
                       (case when @LVC_PropertyName='' then '' else P.Name end) as PropertyName
                       from   Customers.dbo.Property P with (nolock)
                       where   P.IDSeq                 = P.IDSeq
                       and     coalesce(P.[Name],'')      like '%' + @LVC_PropertyName + '%'
                 ) PRP
          on  C.idseq = PRP.PMCIDSeq
          left outer join
                (select distinct co.Customeridseq,
                         (case when @LVC_OwnerName='' then '' else cin.[Name] end) as OwnerName
                         from   Customers.dbo.CustomerOwner co with (nolock)
                         inner join
                                Customers.dbo.Company cin with (nolock)
                         on     cin.IDSeq = co.OwnerIDSeq 
                         and    cin.IDSeq = cin.IDSeq
                         and    cin.ownerflag = 1
                         and    coalesce(cin.[Name],'') like '%' + @LVC_OwnerName + '%'                         
                ) CO
          on  CO.Customeridseq = C.IDSeq         
          left outer join 
               Customers.dbo.Account acct with (nolock)
          on   acct.CompanyIDSeq  = c.IDSeq 
          and  acct.accounttypecode = 'AHOFF' 
          and  acct.CompanyIDSeq  = acct.CompanyIDSeq
          and  coalesce(acct.propertyidseq,0) = coalesce(acct.propertyidseq,0)          
          where coalesce(PRP.PropertyName,'')  like '%'  + @LVC_PropertyName + '%'
          and   coalesce(CO.OwnerName,'')      like '%'  + @LVC_OwnerName    + '%'   
          and   coalesce(c.Name,'')            like  '%' + @LVC_CustomerName + '%'
  
     
    ) source
   -----------------------------------------------------------------------------------
    )tableinner 
 
    WHERE tableinner.RowNumber >  @LI_Min
    AND   tableinner.RowNumber <= @LI_Max
    )
    SELECT  tablefinal.RowNumber,
            tablefinal.[ID]                     as [ID],
            tablefinal.[Name]                   as [Name],
			tablefinal.City                     as City,
            tablefinal.State                    as State,
            tablefinal.Zip                      as Zip,
            tablefinal.address                  as address,
			tablefinal.AccountID                as AccountID, 
		    tablefinal.NoOfProperties           as NoOfProperties
    FROM    tablefinal 
  end
  --------------------------------------------------------------------------------------
  ---Final Cleanup 
  --------------------------------------------------------------------------------------
END--->Main End


--exec Customers.dbo.uspCUSTOMERS_CustomerList 1,210000,'','','','','','',''
GO
