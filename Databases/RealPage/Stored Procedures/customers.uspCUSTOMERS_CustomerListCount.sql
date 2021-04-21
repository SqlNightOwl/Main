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
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_CustomerListCount] ( 
                                                    @IPVC_CustomerName varchar(100), 
                                                    @IPC_City varchar(100), 
                                                    @IPVC_State varchar(100),
                                                    @IPVC_ZipCode varchar(10),
													@IPVC_Address varchar(200),
													@IPVC_PropertyName varchar(200) = '',
                                                    @IPVC_OwnerName varchar(200) = '',
													@IPVC_ActiveFlag    varchar(15) ='', 
													@IPVC_Country       varchar(30)='',
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
    @LVC_CustomerName varchar(100),
	@LVC_City          varchar(100),
	@LVC_State        varchar(100),
	@LVC_ZipCode      varchar(10),	
	@LVC_Address      varchar(200),
	@LVC_PropertyName varchar(200), 
	@LVC_OwnerName    varchar(200),
	@LVC_ActiveFlag    varchar(5),
	@LVC_Country       varchar(100),
	@LVC_CustomerType  varchar(5)

  SELECT
	@LVC_CustomerName = @IPVC_CustomerName,
	@LVC_City         = @IPC_City,
	@LVC_State        = @IPVC_State,
	@LVC_ZipCode      = @IPVC_ZipCode,
	@LVC_Address      = @IPVC_Address,
	@LVC_PropertyName = @IPVC_PropertyName,
	@LVC_OwnerName    = @IPVC_OwnerName,
	@LVC_Country	  = @IPVC_Country,
	@LVC_ActiveFlag   = @IPVC_ActiveFlag,
	@LVC_CustomerType = @IPVC_CustomerType; 
  ---------------------------------------------------------------------------    
  --Final Select   
  ---------------------------------------------------------------------------- 
  if @LN_CHECKSUM = 0
  begin 
    WITH tablefinal AS   
       ----------------------------------------------------------  
       (SELECT tableinner.[Count]   as [Count]  
           FROM  
           ----------------------------------------------------------     
           (select  count(source.[ID])  as [Count]    
            from  
             ----------------------------------------------------------  
             (select  distinct 
               c.IDSeq                                  as ID  
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
               and  coalesce(a.propertyidseq,0) = coalesce(a.propertyidseq,0)                 
               )source  
             ------------------------------------------------------------------------  
        ) tableinner  
      -----------------------------------------------------------------------------  
      )  
      SELECT  tablefinal.[Count]      
      from    tablefinal
  end
  else
  begin
    WITH tablefinal AS   
       ----------------------------------------------------------  
       (SELECT tableinner.[Count]   as [Count]  
           FROM  
           ----------------------------------------------------------     
           (select  count(source.[ID])  as [Count]    
            from  
             ----------------------------------------------------------  
             (select  distinct 
               c.IDSeq                                  as ID  
               from CUSTOMERS.dbo.Company c with (nolock)           
               inner join
               Customers.dbo.Address a with (nolock)
               on   a.CompanyIDSeq           = c.IDSeq   
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
               and  a.AddressTypeCode        =     'COM'                       
               and  a.City                   like  '%' + @LVC_City     + '%' 
               and  a.State                  like  '%' + @LVC_State   + '%' 
               and  a.Zip                    like  '%' + @LVC_ZipCode + '%' 
               and  a.AddressLine1	         like  '%' + @LVC_Address + '%' 
			        and	((@LVC_Country='' and 1=1) 
			            or 
				          (@LVC_Country<>'') AND  coalesce(a.CountryCode,'')	  =    coalesce(@LVC_Country,''))    
               left outer join
                     (select distinct  P.PMCIDSeq,
                             (case when @LVC_PropertyName='' then '' else P.Name end) as PropertyName
                      from   Customers.dbo.Property P with (nolock)
                      where   P.IDSeq                 = P.IDSeq
                      and     P.[Name]                like '%' + @LVC_PropertyName + '%'
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
                      and    cin.[Name] like '%' + @LVC_OwnerName + '%'                         
                     ) CO
               on  CO.Customeridseq = C.IDSeq                                                 
               where coalesce(PRP.PropertyName,'')  like '%' + @LVC_PropertyName + '%'
               and   coalesce(CO.OwnerName,'')      like '%' + @LVC_OwnerName + '%'   
               and   coalesce(c.Name,'')            like  '%' + @LVC_CustomerName + '%'       
)source  
             ------------------------------------------------------------------------  
        ) tableinner  
      -----------------------------------------------------------------------------  
      )  
      SELECT  tablefinal.[Count]      
      from    tablefinal
  end   
  --------------------------------------------------------------------------------------  
  ---Final Cleanup  
  --------------------------------------------------------------------------------------  
END-->Main End  
--exec Customers.dbo.uspCUSTOMERS_CustomerListCount '','','','','','',''
GO
