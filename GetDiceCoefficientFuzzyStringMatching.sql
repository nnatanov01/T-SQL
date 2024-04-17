ALTER FUNCTION [dbo].[GetDiceCoefficientFuzzyStringMatching] (
	@str1 VARCHAR(max)
	,@str2 VARCHAR(max)
	,@nGramlength INT = 2
	)
RETURNS TABLE
AS
RETURN (
		WITH string1Ngrams AS (
				SELECT cntngrams = count(*) OVER ()
					,nGram = SUBSTRING(modstr.modifedStr1, n.n, @nGramlength)
				FROM (
					SELECT modifedStr1 = '%' + @str1 + '#'
					) modstr
				CROSS APPLY dbo.GetNums(1, len(modstr.modifedStr1) - 1) n
				)
			,string2NGrams AS (
				SELECT cntngrams = count(*) OVER ()
					,nGram = SUBSTRING(modstr.modifedStr2, n.n, @nGramlength)
				FROM (
					SELECT modifedStr2 = '%' + @str2 + '#'
					) modstr
				CROSS APPLY dbo.GetNums(1, len(modstr.modifedStr2) - 1) n
				)
		SELECT (cntMatches * 2) / cnttotal AS DiceCoefficient
		 FROM (
			(
				SELECT cntMatches = cast(count(*) AS DECIMAL(7, 2))
				FROM (
					SELECT a.nGram
						,rownum = ROW_NUMBER() OVER (
							PARTITION BY a.nGram ORDER BY (
									SELECT NULL
									)
							)
					FROM string1Ngrams a
					
					INTERSECT
					
					SELECT b.nGram
						,rownum = ROW_NUMBER() OVER (
							PARTITION BY b.nGram ORDER BY (
									SELECT NULL
									)
							)
					FROM string2NGrams b
					) g
				) y CROSS APPLY (
				SELECT cnttotal = cast(count(*) AS DECIMAL(7, 2))
				FROM (
					SELECT a.nGram
					FROM string1Ngrams a
					
					UNION ALL
					
					SELECT b.nGram
					FROM string2NGrams b
					) u
				) j
			)
			WHERE @nGramlength > 0 AND @str1 IS NOT NULL AND @str2 IS NOT NULL
		)