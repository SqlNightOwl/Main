SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetCompanyDetailsForImport]
-- Input Parameters: As Below in Sequential order.  
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetCompanyDetailsForImport  Passing Input Parameters  
-- Revision History:  
-- 2011-09-14     : Mahaboob ( TFS 1030)     --  Gets Company Details for Import Validations based on CompanyType ( Executive or Child )
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetCompanyDetailsForImport] (  @IPVC_CompanyID varchar(11),
                                                                    @IPVC_CompanyType varchar(20) )
as   
BEGIN  
  set nocount on;    
  SET CONCAT_NULL_YIELDS_NULL off;  
  select @IPVC_CompanyID = LTRIM(RTRIM(UPPER(@IPVC_CompanyID)))

  if(@IPVC_CompanyType = 'Executive')
  begin
  ----------------------------------------------------------------------------  
  -- Local Variable Declaration  
  ----------------------------------------------------------------------------  
  declare @LVC_ExecutiveCompanyIDSeq varchar(11),  @LVC_CompanyIDSeq varchar(11)
  ----------------------------------------------------------------------------  
  --Initialization of Variables.  
	select @LVC_ExecutiveCompanyIDSeq = '',  @LVC_CompanyIDSeq = ''
	
	if(   charindex('E',@IPVC_CompanyID) = 1  )
	begin
			select @LVC_ExecutiveCompanyIDSeq = @IPVC_CompanyID
	end
	else if(   charindex('C',@IPVC_CompanyID) = 1  )
	begin
			select @LVC_CompanyIDSeq = @IPVC_CompanyID
	end 
	---------------------------------------------------------------------------- 
	if( len(NULLIF(@LVC_ExecutiveCompanyIDSeq,'')) > 0 )
	begin
			select ExecutiveCompanyIDSeq 'IDSeq', CompanyIDSeq 'CIDSeq', CompanyName 'CompanyName', 
            ( case ActiveFlag
              when 1 then 'ACTIV'
              else 'DEACT'
              end ) 'Status', 'NO' 'ChildCompany', 'NO' 'Owner' 
			from   Customers.dbo.ExecutiveCompany E with (nolock)  
			where  E.ExecutiveCompanyIDSeq  = @LVC_ExecutiveCompanyIDSeq  
			and    len(NULLIF(@LVC_ExecutiveCompanyIDSeq,'')) > 0  
	end
	else if( len(NULLIF(@LVC_CompanyIDSeq,'')) > 0 )
	begin
			if exists ( select 1 from   Customers.dbo.ExecutiveCompany E with (nolock)  
			where  E.CompanyIDSeq  = @LVC_CompanyIDSeq  
			and    len(NULLIF(@LVC_CompanyIDSeq,'')) > 0 )
            begin
					select ExecutiveCompanyIDSeq 'IDSeq', CompanyIDSeq 'CIDSeq', CompanyName 'CompanyName', 
					( case ActiveFlag
					  when 1 then 'ACTIV'
					  else 'DEACT'
					  end ) 'Status', 'NO' 'ChildCompany', 'NO' 'Owner' 
					from   Customers.dbo.ExecutiveCompany E with (nolock)  
					where  E.CompanyIDSeq  = @LVC_CompanyIDSeq  
					and    len(NULLIF(@LVC_CompanyIDSeq,'')) > 0  
            end
			else
            begin
                   select IDSeq 'IDSeq', null 'CIDSeq', Name 'CompanyName', StatusTypeCode 'Status', 
                   ( case
                     when (C.ExecutiveCompanyIDSeq is null or C.ExecutiveCompanyIDSeq = '') then 'NO'
                     else 'YES'
                     end ) 'ChildCompany',
				   ( case
				     when (C.OwnerFlag = 1 and C.PMCFlag = 0) then 'YES'
					 else 'NO'
					 end ) 'Owner'
				   from   Customers.dbo.Company C with (nolock)  
				   where  C.IDSeq  = @LVC_CompanyIDSeq  
				   and    len(NULLIF(@LVC_CompanyIDSeq,'')) > 0  
            end
	end
    end
    else if(@IPVC_CompanyType = 'Child')
    begin
			select IDSeq 'IDSeq', null 'CIDSeq', Name 'CompanyName', StatusTypeCode 'Status', 
			( case
			when (C.ExecutiveCompanyIDSeq is null or C.ExecutiveCompanyIDSeq = '') then 'NO'
			else 'YES'
			end ) 'ChildCompany',
            ( case 
              when len(NULLIF(E.ExecutiveCompanyIDSeq,'')) > 0  then 'YES'
              else 'NO'
              end
            )  'ExecutiveCompany',
			( case
		      when (C.OwnerFlag = 1 and C.PMCFlag = 0) then 'YES'
		      else 'NO'
			 end ) 'Owner'       
			from   Customers.dbo.Company C with (nolock)  
            left outer join
            Customers.dbo.ExecutiveCompany E on E.CompanyIDSeq = C.IDSeq and E.ActiveFlag = 1
			where  C.IDSeq  = @IPVC_CompanyID  
			and    len(NULLIF(@IPVC_CompanyID,'')) > 0  
    end
END
GO
