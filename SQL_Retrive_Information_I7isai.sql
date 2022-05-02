USE DB /* DB was a database set for this work. It was constituted by two tables with information regarding a certain game matches and player information */

--- Q1.
--- WHAT PERCENTAGE OF MATCHES ENDED IN A DRAW?

SELECT *, 
	SUM(SCORE = 0) / COUNT(SCORE) *100 AS EMPATE_PERCENTAGEM
	FROM MATCHES 
	
--- R: THE PERCENTAGE OF TIES WAS 12.9%	

--- Q2.
--- HOW MANY MATCHES WERE PLAYED EACH MONTH?

SELECT DATE_FORMAT(DT, '%m') AS MES,
	   COUNT(*) AS TOTAL
	FROM MATCHES
		GROUP BY MES
		ORDER BY MES ASC

--- R: IN THE MONTH 01, 02 AND 03 10, 7 AND 9 MATCHES ARE PLAYED RESPECTIVELY

--- Q3.
--- HOW MANY MATCHES HAVE BEEN PLAYED BY EACH PLAYER? 

CREATE TEMPORARY TABLE PLAY_P1 /* THIS TABLE CONTAINS THE PLAYER ID IN POSITION 1 AND HOW MANY GAMES he PLAYED AS PLAYER 1*/
SELECT PLAYER1_ID, COUNT(DT) AS P1_PLAY
	FROM MATCHES
		GROUP BY PLAYER1_ID
		
CREATE TEMPORARY TABLE PLAY_P2	/* THIS TABLE CONTAINS THE SAME INFORMATION BUT FOR PLAYER 2*/
SELECT PLAYER2_ID, COUNT(DT) AS P2_PLAY
	FROM MATCHES
		GROUP BY PLAYER2_ID

CREATE TEMPORARY TABLE PLAY /* THIS TEMPORARY TABLE IS A JOIN FROM BOTH PREVIOUS TABLES, REGARDLESS OF THE PLAYER BEING PLAYER 1 OR 2*/
SELECT PLAYER1_ID AS PLAYER_ID, P1_PLAY AS TOTAL_PLAY
	FROM PLAY_P1
UNION
SELECT PLAYER2_ID AS PLAYER_ID, P2_PLAY AS TOTAL_PLAY
	FROM PLAY_P2
	
SELECT PLAYER_ID, SUM(TOTAl_PLAY) AS TOTAL_PLAYS /* FINALLY, WE WILL FIND THE SUM OF THE TOTAL GAMES BY EACH PLAYER AND ORDER BY ID */
	FROM PLAY
		GROUP BY PLAYER_ID
		ORDER BY PLAYER_ID ASC

--- R: FOR EXAMPLE, PLAYER 1 PLAYED 4 MATCHES AND PLAYER 2 PLAYED 7 MATCHES.		
		
--- Q4.
--- LOOKING ONLY AT MATCHES BETWEEN MEN AND WOMEN, WHICH GENDER WIN MOST OFTEN?

CREATE TEMPORARY TABLE P1_SEX /* TABLE WITH PLAYER 1 GENDER*/
SELECT MATCHES.ID AS ID1, MATCHES.PLAYER1_ID, MATCHES.SCORE, 
	PLAYERS.GENDER AS P1SEX
	FROM MATCHES
		LEFT JOIN PLAYERS
		ON PLAYER1_ID = PLAYERS.ID
		ORDER BY MATCHES.ID ASC

CREATE TEMPORARY TABLE P2_SEX /* TABLE WITH PLAYER 2 GENDER*/
SELECT MATCHES.ID AS ID2, MATCHES.PLAYER2_ID, 
	PLAYERS.GENDER AS P2SEX
	FROM MATCHES
		LEFT JOIN PLAYERS
		ON PLAYER2_ID = PLAYERS.ID
		ORDER BY MATCHES.ID ASC

CREATE TEMPORARY TABLE SCORESEX /*JOINING BOTH PREVIOUS TABLES*/
SELECT *
	FROM P1_SEX 
		LEFT JOIN P2_SEX 
		ON P1_SEX.ID1 = P2_SEX.ID2

CREATE TEMPORARY TABLE WINNING_GENDER /* TABLE WITH THE GENDER OF YTHE WINNING PLAYER */
SELECT *,
	CASE WHEN SCORE=2 THEN P2SEX 
	WHEN SCORE=1 THEN P1SEX
	ELSE NULL 
	END AS WINNING_SEX
		FROM SCORESEX 

SELECT WINNING_SEX , COUNT(ID1) /* HOW MANY TIMES WOMEN/MEN WON WHEN PLAYED AGAINST EACH OTHER*/
	FROM WINNING_GENDER
		WHERE P1SEX != P2SEX 
		GROUP BY WINNING_SEX 
		
--- R: WHEN THE GAME IS BETWEEN OPPOSITE GENDER, THE FEMALE GENDER APPEARS TO WIN MORE TIMES, WITH 18 VICTORIES, AGAINST 14 FOR THE MALES. 		

--- Q5.
--- WHICH PLAYERS WON THE MOST MATCHES?

CREATE TEMPORARY TABLE WINNING_PLAYER
SELECT *,
	CASE WHEN SCORE = 2 THEN PLAYER2_ID
	WHEN SCORE = 1 THEN PLAYER1_ID
	ELSE NULL
	END AS WINNIGS_ID
		FROM MATCHES

SELECT WINNIGS_ID , COUNT(WINNIGS_ID) AS TOTAL_WINNING
	FROM WINNING_PLAYER
		GROUP BY WINNIGS_ID
		ORDER BY TOTAL_WINNING DESC

--- R: THE PLAYER WHO WON THE MOST MATCHES WAS PLAYER 6, WITH 7 WINS. FOLLOWED BY PLAYER 3 AND 9 WITH 6 AND 5 WINS RESPECTIVELY.		
		
--- Q6.
--- WHAT IS THE AVERAGE AGE OF THE WINNERS?
--- WHAT IS THE AVERAGE AGE OF THE DEFEATED?

CREATE TEMPORARY TABLE BIRTH_DATE_NOT_EMPTY /* ONLY PLAYER WHOSE BIRTH IS AVALIABLE */
SELECT *
	FROM PLAYERS
		WHERE BIRTH_DATE != '' 

CREATE TEMPORARY TABLE PLAYER_AGE /* CALCULATED THE PLAYERS AGE*/
SELECT ID AS AGE_ID, 
	CASE WHEN BIRTH_DATE_NOT_EMPTY.BIRTH_DATE IS NULL THEN ''
	ELSE YEAR(CURDATE())-YEAR(BIRTH_DATE_NOT_EMPTY.BIRTH_DATE) - (DAYOFYEAR(CURDATE()) < DAYOFYEAR(BIRTH_DATE_NOT_EMPTY.BIRTH_DATE)) 
	END AS 'AGE'
		FROM BIRTH_DATE_NOT_EMPTY

CREATE TEMPORARY TABLE WINNING_PLAYERS /* ONLY WINNING PLAYERS*/
SELECT *,
	CASE WHEN SCORE=2 THEN PLAYER2_ID
	WHEN SCORE=1 THEN PLAYER1_ID
	ELSE NULL 
	END AS WINNING_PLAYER
		FROM MATCHES

CREATE TEMPORARY TABLE WINNING_AGE /* WINNING PLAYERS AGE */
SELECT *
	FROM WINNING_PLAYERS 
		LEFT JOIN PLAYER_AGE 
		ON PLAYER_AGE.AGE_ID = WINNING_PLAYERS.WINNING_PLAYER 

SELECT *, /* AVERAGE OF WINNING PLAYERS*/
	AVG(AGE)
		FROM WINNING_AGE

--- NOW THE SAME FOR THE DEFEATED PLAYERS

CREATE TEMPORARY TABLE LOSING_PLAYERS /* ONLY DEFEATED PLAYERS*/
SELECT *,
	CASE WHEN SCORE=2 THEN PLAYER1_ID
	WHEN SCORE=1 THEN PLAYER2_ID
	ELSE NULL 
	END AS LOSING_PLAYER
		FROM MATCHES

CREATE TEMPORARY TABLE LOSING_AGE /* DEFEATED PLAYERS AGE */
SELECT *
	FROM LOSING_PLAYERS 
	LEFT JOIN PLAYER_AGE 
	ON PLAYER_AGE.AGE_ID = LOSING_PLAYERS.LOSING_PLAYER 

SELECT *, /* AVERAGE OF DEFEATED PLAYERS*/
	AVG(AGE)
		FROM LOSING_AGE

--- R: THE AVERAGE AGE OF THE WINNING PLAYERS IS 31,625 AND OF THE DEFEATED IS 31,644		
		
--- Q BONUS
--- ON AVERAGE OF X IN X HOURS/DAYS SOMEONE STARTS A MATCH. DETERMINE X

CREATE TEMPORARY TABLE HORAS_ATE_PROXIMA_PARTIDA /* HOW MANY HOURS TOOK FOR THE NEXT GAME TO START */
SELECT *,
	TIME_TO_SEC(TIMEDIFF(DT, LAG(DT) OVER (ORDER BY DT))) /3600 AS HORAS_PARTIDA/*HOURS BETWEEN THE NEXT GAME*/
		FROM MATCHES
		ORDER BY DT

SELECT *, /* AVERAGE OF THE HOURS BETWEEN MATCHES*/
	AVG(HORAS_PARTIDA)
		FROM HORAS_ATE_PROXIMA_PARTIDA

--- R: ON AVERAGE IT TAKES 74,627 HOURS TO START A NEW GAME		