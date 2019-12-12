use ipl;

# 1. Show the percentage of wins of each bidder in the order of highest to lowest percentage.
SELECT 
    total.BIDDER_NAME AS 'Bidder Name',
    num_bids AS 'Number of Bids',
    (CASE
        WHEN won.num_wins IS NULL THEN 0
        ELSE won.num_wins
    END) AS 'Number of Wins',
    (CASE
        WHEN won.num_wins IS NULL THEN 0
        ELSE (num_wins / num_bids) * 100
    END) AS win_percentage
FROM
    (SELECT 
        br.BIDDER_ID, br.BIDDER_NAME, COUNT(*) AS num_bids
    FROM
        ipl_bidder_details br, ipl_bidding_details bg
    WHERE
        br.BIDDER_ID = bg.BIDDER_ID
            AND (bg.BID_STATUS = 'Won'
            OR bg.BID_STATUS = 'Lost')
    GROUP BY br.BIDDER_ID) AS total
        LEFT JOIN
    (SELECT 
        br.BIDDER_ID, COUNT(*) AS num_wins
    FROM
        ipl_bidder_details br, ipl_bidding_details bg
    WHERE
        br.BIDDER_ID = bg.BIDDER_ID
            AND bg.BID_STATUS = 'Won'
    GROUP BY br.BIDDER_ID) AS won ON total.BIDDER_ID = won.BIDDER_ID
ORDER BY win_percentage DESC;

# 2. Which teams have got the highest and the lowest no. of bids?
SELECT 
    tm.TEAM_NAME as 'Team Name', 
    COUNT(*) AS num_bids
FROM
    ipl_team tm,
    ipl_bidding_details bd
WHERE
    tm.TEAM_ID = bd.BID_TEAM
GROUP BY tm.TEAM_ID
ORDER BY num_bids DESC;

# 3. In a given stadium, what is the percentage of wins by a team which had won the toss?
SELECT 
    total.STADIUM_NAME AS 'Stadium Name',
    total.num_match AS 'Number of Matches',
    toss.num_toss_match_win AS 'Number of Matches won by Toss Winners',
    (toss.num_toss_match_win / total.num_match) * 100 AS 'Percentage'
FROM
    (SELECT 
        stad.STADIUM_ID, stad.STADIUM_NAME, COUNT(*) AS num_match
    FROM
        ipl_match_schedule sch, ipl_match mat, ipl_stadium stad
    WHERE
        sch.MATCH_ID = mat.MATCH_ID
            AND sch.STADIUM_ID = stad.STADIUM_ID
    GROUP BY stad.STADIUM_ID) AS total
        JOIN
    (SELECT 
        stad.STADIUM_ID, COUNT(*) AS num_toss_match_win
    FROM
        ipl_match_schedule sch, ipl_match mat, ipl_stadium stad
    WHERE
        sch.MATCH_ID = mat.MATCH_ID
            AND sch.STADIUM_ID = stad.STADIUM_ID
            AND mat.TOSS_WINNER = mat.MATCH_WINNER
    GROUP BY stad.STADIUM_ID) AS toss ON total.STADIUM_ID = toss.STADIUM_ID;
    
# 4. What is the total no. of bids placed on the team that has won highest no. of matches?
SELECT 
    tm.TEAM_NAME as 'Team Name', 
    COUNT(*) AS 'Number of Bids'
FROM
    ipl_bidding_details dts,
    ipl_team tm
WHERE
    dts.BID_TEAM = tm.TEAM_ID
        AND bid_team = (SELECT 
							team_id
						FROM
							ipl_team_standings
						GROUP BY team_id
						ORDER BY SUM(MATCHES_WON) DESC
						LIMIT 1);
                        
# 5. From the current team standings, if a bidder places a bid on which of the teams, there is a possibility of 
# (s)he winning the highest no. of points – in simple words, identify the team which has the highest jump in its total points 
# (in terms of percentage) from the previous year to current year.
SELECT 
    tm.TEAM_NAME AS 'Team Name',
    yr17.TOTAL_POINTS AS '2017 - Total Points',
    yr18.TOTAL_POINTS AS '2018 - Total Points',
    ((yr18.TOTAL_POINTS - yr17.TOTAL_POINTS) / yr17.TOTAL_POINTS) * 100 AS jump_percentage
FROM
    ipl_team tm,
    (SELECT 
        TEAM_ID, TOTAL_POINTS
    FROM
        ipl_team_standings
    WHERE
        TOURNMT_ID = 2017) AS yr17,
    (SELECT 
        TEAM_ID, TOTAL_POINTS
    FROM
        ipl_team_standings
    WHERE
        TOURNMT_ID = 2018) AS yr18
WHERE
    tm.TEAM_ID = yr18.TEAM_ID
        AND yr18.TEAM_ID = yr17.TEAM_ID
ORDER BY jump_percentage DESC;
