USE ig_clone;

-- OBJECTIVE QUESTIONS:
-- ANS 1. CHECKING FOR NULL OR DUPLICATE VALUES

-- CHECKING NULL VALUES 
SELECT * FROM comments 
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL OR 4 IS NULL OR 5 IS NULL ;

SELECT * FROM follows 
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

SELECT * FROM likes 
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

SELECT * FROM photo_tags
WHERE 1 IS NULL OR 2 IS NULL;

SELECT * FROM photos
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL OR 4 IS NULL;

SELECT * FROM tags
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

SELECT * FROM users
WHERE 1 IS NULL OR 2 IS NULL OR 3 IS NULL;

-- CHECKING DUPLICATE VALUES
 SELECT * FROM comments
 GROUP BY 1,2,3,4,5 HAVING COUNT(*) > 1;
 
  SELECT * FROM follows
 GROUP BY 1,2,3 HAVING COUNT(*) > 1;
 
  SELECT * FROM likes
 GROUP BY 1,2,3 HAVING COUNT(*) > 1;
 
  SELECT * FROM photo_tags
 GROUP BY 1,2 HAVING COUNT(*) > 1;
 
  SELECT * FROM photos
 GROUP BY 1,2,3,4 HAVING COUNT(*) > 1;
 
   SELECT * FROM tags
 GROUP BY 1,2,3 HAVING COUNT(*) > 1;
 
   SELECT * FROM users
 GROUP BY 1,2,3 HAVING COUNT(*) > 1;
 
--  SELECT criteria, COUNT(id) FROM 
-- 	(SELECT id, CASE WHEN COUNT(id) > 1 THEN 'DUPLICATED' ELSE 'UNIQUE' END AS criteria, COUNT(*)
-- 	FROM comments
-- 	GROUP BY 1) Z 
-- GROUP BY 1;



-- ANS2. distribution of user activity levels 
SELECT u.id AS user_id
,username
,COUNT(DISTINCT p.id) AS photos_posted
,COUNT(DISTINCT pt.tag_id) AS tags_used
,COUNT(DISTINCT c.photo_id) AS comments_made
,COUNT(DISTINCT l.photo_id) AS likes_done
FROM users u 
LEFT JOIN photos p ON p.user_id=u.id
LEFT JOIN comments c ON c.user_id=u.id
LEFT JOIN likes l ON l.user_id=u.id
LEFT JOIN photo_tags pt ON pt.photo_id=p.id
GROUP BY 1,2;



-- ANS3. the average number of tags per post 

-- WAY 01: WITH SUBQUERY:
SELECT ROUND(AVG(tag_count),2) AS avg_tag_per_post 
FROM 
	(SELECT photo_id,COUNT(DISTINCT tag_id) AS tag_count
	FROM photo_tags
	GROUP BY 1
    ) Z;
 
 -- WAY 02: WITHOUT SUBQUERY
SELECT ROUND(COUNT(tag_id)/ COUNT(distinct photo_id),2) avg_tag_per_post 
FROM photo_tags;



-- ANS4. top users with the highest engagement rates (likes, comments) on their posts and rank them.
-- CTE to calculate likes and comments each user got on their posted photo = engagement
WITH engagement AS(
SELECT u.id
	,username
	,p.id AS photo_id
	,COUNT(DISTINCT l.user_id) AS likes
	,COUNT(DISTINCT c.user_id) AS comments
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
JOIN likes l ON l.photo_id=p.id
JOIN comments c ON c.photo_id=p.id
GROUP BY 1,2,3
)
-- MAIN QUERY adding likes and comment for each user and then ranking them 
SELECT id
,username
,(likes+comments) AS total_engagement
,DENSE_RANK() OVER( ORDER BY (likes+comments) DESC) AS engagement_rank
FROM engagement;




-- ANS5. user has the highest number of followers and followings
-- HIGHEST NO. OF FOLLOWERS
SELECT id,username,followers_count
FROM (
		SELECT id
		,username
		,COUNT(follower_id) AS followers_count
		,DENSE_RANK() OVER(ORDER BY COUNT(follower_id) DESC) AS count_rank
		FROM users u 
		LEFT JOIN follows f ON u.id=f.followee_id 
		GROUP BY 1,2
) Z
WHERE count_rank=1
ORDER BY 1;


-- HIGHEST NO. OF FOLLOWINGS
SELECT id,username,followings_count
FROM (
		SELECT id
		,username
		,COUNT(followee_id) AS followings_count
		,DENSE_RANK() OVER(ORDER BY COUNT(followee_id) DESC) AS count_rank
		FROM users u 
		LEFT JOIN follows f ON u.id=f.follower_id 
		GROUP BY 1,2
) Z
WHERE count_rank=1
ORDER BY 1;



-- ANS6. average engagement rate (likes, comments) per post for each user.
-- CTE to calculate likes and comments each user got on their posted photo
WITH engagement AS(
SELECT u.id
	,username
	,p.id AS photo_id
	,COUNT(DISTINCT l.user_id) AS likes
	,COUNT(DISTINCT c.user_id) AS comments
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
JOIN likes l ON l.photo_id=p.id
JOIN comments c ON c.photo_id=p.id
GROUP BY 1,2,3
)

-- MAIN QUERY to calculate the average engagement rate 
-- ENGAGEMENT = likes +comments
-- ENGAGEMENT RATE = (engagement/count of photo_id)
SELECT id,username
,ROUND((AVG(likes+comments)),2)AS avg_engagement
FROM engagement 
GROUP BY 1,2,likes,comments
ORDER BY 3 DESC, 1 ASC;



-- ANS7.list of users who have never liked any post 
SELECT id, username
FROM users u 
LEFT JOIN likes l ON l.user_id=u.id
GROUP BY 1,2 HAVING COUNT(DISTINCT photo_id)=0;



-- ANS 8. user-generated content (posts, hashtags, photo tags) 
-- Finding out tag_name for each photo liked by user
WITH tag_name AS(
SELECT l.user_id,tag_name,l.photo_id
FROM likes l
LEFT JOIN photo_tags pt ON  pt.photo_id=l.photo_id
LEFT JOIN tags t ON pt.tag_id=t.id
),

-- giving a tag_category to each tag_name to better understand the user liking
tag_category AS(
SELECT id tag_id,tag_name
, CASE WHEN tag_name IN ('happy', 'smile') THEN 'Joy-Emotions'
    WHEN tag_name IN ('stunning', 'dreamy') THEN 'Aesthetics'
    WHEN tag_name IN ('delicious', 'food', 'foodie') THEN 'Food'
    WHEN tag_name IN ('concert', 'party', 'drunk', 'lol','fun') THEN 'Party & Fun'
    WHEN tag_name IN ('beauty', 'hair') THEN 'Beauty'
    WHEN tag_name IN ('landscape', 'sunrise', 'sunset','beach') THEN 'Landscape'
    WHEN tag_name IN ('fashion', 'style') THEN 'Fashion'
    WHEN tag_name = 'photography' THEN 'Photography'
    ELSE NULL
END AS tag_category
FROM tags
),

-- counting the no. of likes a user did in each category and then ranking it 
likes_per_category AS (
SELECT user_id
,tag_category
,COUNT(photo_id) AS likes_done
,DENSE_RANK() OVER(PARTITION BY user_id ORDER BY COUNT(photo_id) DESC) AS likes_rank
FROM tag_name tn 
JOIN tag_category tc ON tn.tag_name=tc.tag_name
GROUP BY 1,2
ORDER BY 1,3 DESC
)

SELECT user_id,tag_category,likes_done
FROM likes_per_category a
WHERE likes_rank<=3;



-- ANS9. correlations between user activity levels and specific content types 
-- User Upload Activity:
WITH uploads AS (
SELECT u.id user_id,
    u.username, 
    COUNT(p.id) AS photo_uploads
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
GROUP BY 1,2
),

-- Likes per User's Photos:
likes AS (
SELECT u.id user_id
    , u.username 
    , COUNT(l.photo_id) AS total_likes
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON p.id = l.photo_id
GROUP BY 1,2
),

-- comments per User's Photos:
comments AS(
SELECT u.id user_id
    , u.username
    , COUNT(c.id) AS total_comments
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY 1,2
)

-- FINAL OUTPUT 01 
-- Combining Uploads, Likes, and Comments:
-- SELECT u.user_id
-- 	, u.username
--     , photo_uploads
--     , total_likes
--     , total_comments
-- FROM uploads u 
-- JOIN likes l ON u.user_id=l.user_id
-- JOIN comments c ON u.user_id=c.user_id;

-- (TO RUN OUTPUT 02, PLEASE COMMENT OUT FINAL OOUTPUT 01 QUERY)
-- FINAL OUTPUT 02 
-- CORRELATION BETWEEN NO. OF UPLOADS AND TOTAL_ENGAGAEMNET
	SELECT DISTINCT photo_uploads
	,ROUND(AVG(total_likes+total_comments) OVER(PARTITION BY photo_uploads),0) average_engagement
	FROM uploads u 
	JOIN likes l ON u.user_id=l.user_id
	JOIN comments c ON u.user_id=c.user_id;

-- ANS10. total number of likes, comments, and photo tags for each user.
SELECT user_id, username, SUM(likes) likes,SUM(comments) comments,SUM(tags) tags
FROM (
	SELECT u.id AS user_id
		,username
		,p.id AS photo_id
		,COUNT(DISTINCT l.user_id)AS likes
		,COUNT(DISTINCT c.id) AS comments
		,COUNT(DISTINCT pt.tag_id) AS tags
	FROM users u 
	JOIN photos p ON u.id=p.user_id
	JOIN photo_tags pt ON p.id=pt.photo_id
	JOIN likes l ON pt.photo_id=l.photo_id
	JOIN comments c ON pt.photo_id=c.photo_id
	GROUP BY 1,2,3
) z
GROUP BY 1,2; 


-- ANS 11. Rank users based on their total engagement (likes, comments, shares) over a month.
WITH engagement AS (
SELECT u.id AS user_id
,username
,MONTH(p.created_dat) `month`
,YEAR(p.created_dat) `year`
,p.id AS photo_id
,(COUNT(DISTINCT c.user_id)+ COUNT(DISTINCT l.user_id)) AS engagement_recieved
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
LEFT JOIN comments c ON c.photo_id=p.id
LEFT JOIN likes l ON l.photo_id=p.id
GROUP BY 1,2,3,4,5
)
SELECT user_id, username,`year`,`month`,SUM(engagement_recieved) AS total_engagement
,DENSE_RANK() OVER(ORDER BY SUM(engagement_recieved) DESC) AS engagement_rank
FROM engagement
GROUP BY 1,2,3,4;

-- ANS12. hashtags that have been used in posts with the highest average number of likes.
-- average like of each tag
WITH tag_name_and_likes AS (
SELECT t.id tag_id
,tag_name
,pt.photo_id 
,COUNT( DISTINCT l.user_id) total_likes
,AVG(COUNT( DISTINCT l.user_id)) OVER(PARTITION BY t.id) AS avg_likes
FROM tags t 
LEFT JOIN photo_tags pt ON t.id=pt.tag_id
JOIN likes l ON l.photo_id=pt.photo_id
GROUP BY 1,2,3
)

SELECT DISTINCT tag_id,tag_name
FROM tag_name_and_likes
WHERE avg_likes IN (SELECT MAX(avg_likes) FROM tag_name_and_likes )
ORDER BY 1;

-- ANS13. users who have started following someone after being followed by that person
SELECT f1.follower_id AS user1_as_follower
,f1.followee_id AS user2_as_following
,f1.created_at as followed_at
,f2.follower_id AS user2_as_follower
,f2.followee_id AS user1_as_following
,f2.created_at AS followed_back_at
FROM follows f1
JOIN follows f2 ON f1.followee_id=f2.follower_id
AND f1.follower_id=f2.followee_id
WHERE f2.created_at<f1.created_at
ORDER BY 1;





-- SUBJECTIVE ANSWERS 

-- ANS1.Based on user engagement and activity levels,the most loyal or valuable users

-- SELECTING BOT
-- USERS WHO ARE LIKING AND COMMENTING ON EACH PHOTO POSTED, WHICH IS GENERALLY RARE FOR A REAL USER TO DO 
WITH BOT_USERS AS(
SELECT u.id user_id,username
FROM likes l
RIGHT JOIN users u ON u.id=l.user_id
GROUP BY 1 HAVING COUNT(DISTINCT photo_id) = (SELECT COUNT(DISTINCT id) FROM photos)
UNION
SELECT u.id user_id,username
FROM comments c
RIGHT JOIN users u ON u.id=c.user_id
GROUP BY 1 HAVING COUNT(DISTINCT photo_id)= (SELECT COUNT(DISTINCT id) FROM photos)
),

-- engagement of users
engagement AS (
SELECT u.id AS user_id
,username
,p.id AS photo_id
,(COUNT(DISTINCT c.user_id)+ COUNT(DISTINCT l.user_id)) AS engagement_recieved
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
LEFT JOIN comments c ON c.photo_id=p.id
LEFT JOIN likes l ON l.photo_id=p.id
GROUP BY 1,2,3
),

-- activity of users
activity AS(
SELECT u.id AS user_id
,username
,(COUNT(DISTINCT c.photo_id)+COUNT(DISTINCT l.photo_id)) AS total_activity
FROM users u 
LEFT JOIN comments c ON c.user_id=u.id
LEFT JOIN likes l ON l.user_id=u.id
GROUP BY 1,2
),

-- Ranking user on the basis of activity and egagement
ranked_users AS(
SELECT e.user_id
,e.username
,SUM(engagement_recieved) total_engagement
,total_activity
,DENSE_RANK() OVER(ORDER BY (SUM(engagement_recieved)+ total_activity) DESC) activity_engagement_rank
,COUNT(*) OVER() total_users
FROM engagement e 
JOIN activity a ON e.user_id=a.user_id
WHERE e.user_id NOT IN (SELECT user_id FROM BOT_USERS)
GROUP BY 1,2
)

-- ensuring selecting users are in top 15% activity and engagement level
SELECT user_id
,username
,total_engagement
,total_activity
FROM ranked_users
WHERE activity_engagement_rank <= (0.15*total_users)
;


-- ANS2. INACTIVE USERS
-- Categorising Users as 'Active' & 'Inactive User'
WITH user_category AS(
SELECT DISTINCT u.id
, username
, CASE 
	WHEN p.id IS NULL THEN 'Inactive User'
	ELSE 'Active User'
END AS User_Category
FROM users u
LEFT JOIN photos p ON u.id=p.user_id
)

SELECT id, username
FROM user_category 
WHERE User_Category ='Inactive User' 
;


-- ANS 3. tags have the highest engagement rates
SELECT 
	t.tag_name,
    COUNT(*) AS total_used
FROM photo_tags pt
JOIN tags t
	ON pt.tag_id = t.id
GROUP BY t.id
ORDER BY total_used DESC
LIMIT 5;



-- ANS4.
-- QUERY01: Joining year and follower count act as proxies for segmenting user groups.
SELECT joining_year,
follower_count,
COUNT(DISTINCT user_id) user_count, 
ROUND(AVG(post_count),0) avg_post,
ROUND(AVG(engagement_recieved),2) avg_engagement
FROM (
	SELECT u.id user_id
	, username
	, year(u.created_at) joining_year
	, COUNT( DISTINCT follower_id) follower_count
	, COUNT( DISTINCT p.id) post_count
    ,(COUNT(DISTINCT c.user_id)+ COUNT(DISTINCT l.user_id)) AS engagement_recieved
	FROM users u 
	LEFT JOIN follows f ON u.id=f.followee_id
	LEFT JOIN photos p ON p.user_id=f.followee_id
	LEFT JOIN comments c ON c.photo_id=p.id
	LEFT JOIN likes l ON l.photo_id=p.id
	GROUP BY 1,2
)Z 
GROUP BY 1,2;





-- QUER02:  tag usage and the popularity of tags among users who joined in different years
WITH tag AS(
SELECT u.id user_id, username, year(u.created_at) joining_year
,tag_name
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
JOIN photo_tags pt ON p.id=pt.photo_id
JOIN tags t ON pt.tag_id=t.id
),

tag_ranking AS(
SELECT joining_year,tag_name, COUNT(user_id) user_count
, DENSE_RANK() OVER(PARTITION BY joining_year ORDER BY COUNT(user_id) DESC) tag_ranking
FROM tag
GROUP BY 1,2
)

SELECT joining_year,tag_name,user_count
FROM tag_ranking
WHERE tag_ranking<=5
;



-- ANS5. 
-- FOLLOWER COUNT OF EACH USER 
WITH followers AS(
SELECT u.id user_id
, username
, COUNT(follower_id) AS follower_count
FROM users u 
LEFT JOIN follows f ON u.id=f.followee_id
GROUP BY 1,2
),

-- ENGAGEMENT OF EACH USER 
engagement AS(
SELECT u.id AS user_id
,username
,p.id AS photo_id
,(COUNT(DISTINCT c.user_id)+ COUNT(DISTINCT l.user_id)) AS engagement_recieved
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
LEFT JOIN comments c ON c.photo_id=p.id
LEFT JOIN likes l ON l.photo_id=p.id
GROUP BY 1,2,3
),

-- potential influencers
influencers AS(
SELECT f.user_id
, f.username
, follower_count
, (SUM(engagement_recieved)/follower_count) avg_engagement_rate
FROM followers f 
JOIN engagement e ON f.user_id=e.user_id
GROUP BY 1,2,3
)

-- Identifying influencers with high follower count and high engagement_rate
SELECT * FROM influencers
ORDER BY 3 DESC, 4 DESC
LIMIT 5;


-- ANS 6. SEGMENTATION OF USER BASED ON  USER BEHAVIOUR AND ENGAGEMENT DATA 
-- Engagament received by each user
WITH engagement AS(
SELECT u.id AS user_id
,username
,p.id AS photo_id
,(COUNT(DISTINCT c.user_id)+ COUNT(DISTINCT l.user_id)) AS engagement_received
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
LEFT JOIN comments c ON c.photo_id=p.id
LEFT JOIN likes l ON l.photo_id=p.id
GROUP BY 1,2,3
),

-- activity of each user
activity AS(
SELECT u.id AS user_id
,username
,(COUNT(DISTINCT c.photo_id)+COUNT(DISTINCT l.photo_id)) AS total_activity
FROM users u 
LEFT JOIN comments c ON c.user_id=u.id
LEFT JOIN likes l ON l.user_id=u.id
GROUP BY 1,2
),

-- categorising user on engagement and activity status
user_segment AS(
SELECT e.user_id
	, e.username
	, SUM(engagement_received) engagement_received
	, total_activity
	, CASE 
        WHEN total_activity = 0 THEN 'No Activity'
        WHEN total_activity >= 250 THEN 'High Activity'
        WHEN total_activity < 150 THEN 'Low Activity'
        WHEN total_activity BETWEEN 150 AND 250 THEN 'Moderate Activity'
    END AS activity_category
	,     CASE 
        WHEN SUM(engagement_received) = 0 THEN 'No Engagement'
        WHEN SUM(engagement_received) >= 300 THEN 'High Engagement'
        WHEN SUM(engagement_received) < 200 THEN 'Low Engagement'
        WHEN SUM(engagement_received) BETWEEN 200 AND 300 THEN 'Moderate Engagement'
    END AS engagement_category
FROM engagement e
JOIN activity a ON e.user_id=a.user_id
GROUP BY 1,2,4
)

-- Main query
SELECT user_id
	, username
    , engagement_received
    , total_activity
    , CONCAT(activity_category,' ','And',' ', engagement_category) user_category
FROM user_segment;

-- ANS 8. POTENTIAL BRAND AMBASSDORS OR ADVOCATES
-- Follower count of each user 
WITH followers AS(
SELECT u.id user_id
, username
, COUNT(follower_id) AS follower_count
FROM users u 
LEFT JOIN follows f ON u.id=f.followee_id
GROUP BY 1,2
),

-- ENGAGEMENT OF EACH USER 
engagement AS(
SELECT u.id AS user_id
,username
,p.id AS photo_id
,COUNT(DISTINCT c.user_id) comments
, COUNT(DISTINCT l.user_id) likes 
FROM users u 
LEFT JOIN photos p ON u.id=p.user_id
LEFT JOIN comments c ON c.photo_id=p.id
LEFT JOIN likes l ON l.photo_id=p.id
GROUP BY 1,2,3
)

-- potential brand ambassadors  
SELECT f.user_id
, f.username
, follower_count
, SUM(comments) + SUM(likes) total_likes
FROM followers f 
JOIN engagement e ON f.user_id=e.user_id
WHERE follower_count = (SELECT MAX(follower_count) FROM followers)
GROUP BY 1,2,3 
ORDER BY 4 DESC LIMIT 4;





