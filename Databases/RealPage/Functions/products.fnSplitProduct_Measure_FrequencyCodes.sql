SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE function [products].[fnSplitProduct_Measure_FrequencyCodes](@string varchar(8000))

RETURNS @parsedList TABLE
 (
  ProductCode VARCHAR(30),
  ilfMeasureCode VARCHAR(30),
  ilfFrequencyCode VARCHAR(30),
  acsMeasureCode VARCHAR(30),
  acsFrequencyCode VARCHAR(30)
 )
AS
BEGIN

 IF left(@string,1)='|'
   BEGIN
    select @string=substring(@string,2,len(@string))
   END

	declare @Pos varchar(3000)
	declare @Pos1 varchar(30)

	set @Pos=(select charindex('|',@string)) 
	set @Pos1=(select charindex(',',@string)) 

	while (charindex('|',@string) <> 0) 
		begin  if @Pos > 0  
				begin  
					declare @singlefile varchar(3000)  
					set @singlefile=(select substring(@string,1,charindex('|',@string)-1))
					set @singlefile=@singlefile+','
					declare @count int 
					SET @Count = 1
						while (charindex(',',@singlefile) <> 0) 
							begin  
										
										if @Pos1 > 0  
										begin  
											
											declare @ProductCode varchar(3000)  
											declare @ilfMeasureCode varchar(3000)  
											declare @ilfFrequencyCode varchar(3000) 
                      declare @acsMeasureCode varchar(3000)  
											declare @acsFrequencyCode varchar(3000) 
    
                      declare  @countString int
											
										   if (@Count =1)
											 begin
											   set @ProductCode=(select substring(@singlefile,1,charindex(',',@singlefile)-1))
                         set @countString = len(@ProductCode)
                       end

											if (@Count =2)
											 begin
											   set @ilfMeasureCode=(select substring(@singlefile,1,charindex(',',@singlefile)-1))
                         set @countString = len(@ilfMeasureCode)
                       end

											if (@Count =3)
											  begin
											   set @ilfFrequencyCode=(select substring(@singlefile,1,charindex(',',@singlefile)-1))
                         set @countString = len(@ilfFrequencyCode)
                        end
                  
                      if (@Count =4)
											 begin
                        set @acsMeasureCode=(select substring(@singlefile,1,charindex(',',@singlefile)-1))
                        set @countString = len(@acsMeasureCode)
                       end

											if (@Count =5)
											  begin
                           set @acsFrequencyCode=(select substring(@singlefile,1,charindex(',',@singlefile)-1))
                           set @countString = len(@acsFrequencyCode)
                        end
										
                    
												SET @Count = @Count + 1
                     
                      --set @singlefile=(select replace(@singlefile,substring(@singlefile,1,charindex(',',@singlefile)),''))
                      set @singlefile=substring(@singlefile,@countString+2,len(@singlefile))
                   	end
							end  
				 insert into @ParsedList (ProductCode,ilfMeasureCode,ilfFrequencyCode,acsMeasureCode,acsFrequencyCode) 
				 values (CAST(@ProductCode AS varchar(30)),CAST(@ilfMeasureCode AS varchar(30)),CAST(@ilfFrequencyCode AS varchar(30)),
                    CAST(@acsMeasureCode AS varchar(30)),CAST(@acsFrequencyCode AS varchar(30))) 
						
        set @string=(select replace(@string,substring(@string,1,charindex('|',@string)),''))

				end
		end  
RETURN
end

--SELECT * from [fnSplitProduct_Measure_FrequencyCodes]('|DMD-OSD-OLR-CNV-RCNV,SITE,SG,SITE,YR|DMD-OSD-OLR-SPA-RSPA,SITE,SG,SITE,SG|DMD-OSD-PAY-PAY-PACH,null,null,ITEM,SG|DMD-OSD-ACT-ACT-ACON,MODULE,SG,MODULE,YR|DMD-OSD-SCR-SCR-SCSC,SITE,SG,SITE,MN|DMD-OSD-SCR-SCR-SCMC,null,null,UNIT,YR|DMD-OSD-SCR-SCR-SEFS,SITE,SG,UNIT,MN|DMD-CFR-COL-COL-CGCW,SITE,SG,UNIT,SG|')
 
--drop function [fnSplitProduct_Measure_FrequencyCodes]
 



GO
