create function tcu.fn_FuzzyMatchPercent
(	@String1	varchar(128)
,	@String2	varchar(128)	)
returns int
as
/*
????????????????????????????????????????????????????????????????????????????????
			c 2000-08 ? Texans Credit Union ? All rights reserved.
????????????????????????????????????????????????????????????????????????????????
Developer:	Paul Hunter
Created  :	07/31/2006
Purpose  :	Express the similarity of two strings as a percentage; similar to the
			Levenshtein Distance algorithm.
Notes	 :	The routine's name is deliberately oxymoronic because it expresses
			the algorithm's intention of giving a reliable, but best guess,
			measurement of two strings sameness based soley on their alpha
			characters.  The strength of this algorithm is also its weakness in
			that similarity is determined based on matching characters positionally
			within the strings and not within words (version 2.0 anyone?)
Warning	 :	This routine does not do any type of phonetic comparison and as such
			is unsuitable for string grouping purposes if using the string's content
			as the matching criteria.
			For example: 'Kennys Automotive' and 'Pennys Automotive' are 94% similar
			in spelling but are obviously not the same merchant.
History	 :
   Date		Developer		Description
??????????	??????????????	????????????????????????????????????????????????????
????????????????????????????????????????????????????????????????????????????????
*/
begin
	declare
		@DeltaCount			float
	,	@String1Char		char(1)
	,	@String2Char		char(1)
	,	@String1CharCount	int
	,	@String2CharCount	int
	,	@String1Index		int
	,	@String2Index		int
	,	@String1Length		int
	,	@String2Length		int
	-- optimize the process by removing spaces (since they would be ignored anyway)
	select	@String1 = replace(@String1, ' ', '')
		,	@String2 = replace(@String2, ' ', '')
	-- initialize variables
	select	@DeltaCount			= 0
		,	@String1CharCount	= 0
		,	@String2CharCount	= 0
		,	@String1Index		= 1
		,	@String2Index		= 1
		,	@String1Length		= len(@String1)
		,	@String2Length 		= len(@String2)
	while 1 = 1
	begin
		-- get the next alpha character in @String1
		if @String1Index <= @String1Length
		begin
			if substring(@String1, @String1Index, 1) not between 'a' and 'z'
			begin
				while @String1Index <= @String1Length
				begin
					set	@String1Index = @String1Index + 1
					if substring(@String1, @String1Index, 1) between 'a' and 'z'
						break
				end
			end
		end
		-- past end of @String1?
		if @String1Index > @String1Length
			set	@String1Char = ''
		else
		begin
			set	@String1Char		= substring(@String1, @String1Index, 1)
			set	@String1CharCount	= @String1CharCount + 1
		end
		-- get the next alpha character in @String2
		if @String2Index <= @String2Length
		begin
			if substring(@String2, @String2Index, 1) not between 'a' and 'z'
			begin
				while @String2Index <= @String2Length
				begin
					set	@String2Index = @String2Index + 1
					if substring(@String2, @String2Index, 1) between 'a' and 'z'
						break
				end
			end
		end
		-- past end of @String2?
		if @String2Index > @String2Length
			set	@String2Char = ''
		else
		begin
			set	@String2Char		= substring(@String2, @String2Index, 1)
			set	@String2CharCount	= @String2CharCount + 1
		end
		-- are the characters different?
		if @String1Char != @String2Char
			set	@DeltaCount = @DeltaCount + 1
		-- next!
		select	@String1Index = @String1Index + 1
			,	@String2Index = @String2Index + 1
		-- past the end of both strings?
		if (@String1Index > @String1Length) and (@String2Index > @String2Length)
			break
	end
	-- if comparing numbers (ie. 7-11, 747, etc.) then...
	if (@String1CharCount = 0) and (@String2CharCount = 0)
	begin
		select	@String1 = case when charindex('#', @String1) = 0 then @String1
								else left(@String1, charindex('#', @String1) -1) end
			,	@String2 = case when charindex('#', @String2) = 0 then @String2
								else left(@String2, charindex('#', @String2) -1) end
		-- reinitialize variables
		select	@DeltaCount			= 0
			,	@String1CharCount	= 0
			,	@String2CharCount	= 0
			,	@String1Index		= 1
			,	@String2Index		= 1
			,	@String1Length		= len(@String1)
			,	@String2Length 		= len(@String2)
		while 1 = 1
		begin
			-- past end of @String1?
			if @String1Index > @String1Length
				set	@String1Char = ''
			else
			begin
				set	@String1Char		= substring(@String1, @String1Index, 1)
				set	@String1CharCount	= @String1CharCount + 1
			end
			-- past end of @String2?
			if @String2Index > @String2Length
				set	@String2Char = ''
			else
			begin
				set	@String2Char		= substring(@String2, @String2Index, 1)
				set	@String2CharCount	= @String2CharCount + 1
			end
			-- are the characters different?
			if @String1Char != @String2Char
				set	@DeltaCount = @DeltaCount + 1
			-- next!
			select	@String1Index = @String1Index + 1
				,	@String2Index = @String2Index + 1
			-- past the end of both strings?
			if (@String1Index > @String1Length) and (@String2Index > @String2Length)
				break
		end
	end
	-- no divide by zero errors, please
	if (@String1CharCount = 0) and (@String2CharCount = 0)
		set	@String1CharCount = 1
	-- percent certainty match
	--	NOTES:
	--		1.	aggressive matching due to rounding up via ceiling()
	--		2.	use the largest character count for the denominator
	return ceiling((1.0 - (@DeltaCount / case when @String1CharCount > @String2CharCount then @String1CharCount else @String2CharCount end)) * 100)
end
GO
