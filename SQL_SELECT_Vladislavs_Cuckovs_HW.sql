-- 1.1) All animation movies released between 2017 and 2019 
-- 	  with rate more than 1
--    alphabetical
SELECT 
    f.title
FROM public.film f
-- Joining film_category to get the category of the film
INNER JOIN public.film_category fc ON fc.film_id = f.film_id  
-- Joining category to filter for 'Animation' movies
INNER JOIN public.category c ON c.category_id = fc.category_id  
-- Applying filters:
WHERE 
    c.name = 'Animation'  -- Selecting only animation movies
    AND f.rental_rate > 1  -- Ensuring rental rate is greater than 1
    AND f.release_year BETWEEN 2017 AND 2019  -- Filtering release years within the range
-- Sorting titles alphabetically
ORDER BY f.title ASC;


---1.2)The revenue earned by each rental store after March 2017 (columns: address and address2 – as one column, revenue)
SELECT 
    CONCAT(TRIM(a.address), ' ', COALESCE(TRIM(a.address2), '')) AS full_address, -- Combining address fields
    COALESCE(SUM(p.amount), 0) AS revenue  -- Ensuring revenue is never NULL
FROM public.payment p
-- Joining rental to associate payments with rentals
INNER JOIN public.rental r ON p.rental_id = r.rental_id
-- Joining inventory to associate rentals with store inventory
INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
-- Joining store to find out which store the inventory belongs to
INNER JOIN public.store s ON i.store_id = s.store_id
-- Joining address to get store location details
INNER JOIN public.address a ON s.address_id = a.address_id  
-- Filtering for payments made from March 1, 2017, onward
WHERE p.payment_date >= '2017-03-01 00:00:00'  
-- Grouping by the actual address fields (not the alias)
GROUP BY a.address, a.address2  
-- Sorting results by revenue in descending order
ORDER BY revenue DESC;


--1.3)Top-5 actors by number of movies (released after 2015) they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
SELECT 
    a.first_name, 
    a.last_name,
    COUNT(fa.film_id) AS number_of_movies  -- Counting the number of movies each actor participated in
FROM actor a
-- Joining the bridge table (film_actor) to link actors with movies
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
-- Joining the film table to filter based on the release year
INNER JOIN film f ON fa.film_id = f.film_id
WHERE f.release_year >= 2015  -- Only consider movies released after 2015
GROUP BY a.actor_id, a.first_name, a.last_name  -- aggregation
ORDER BY 
    number_of_movies DESC,  -- Sorting by the number of movies in descending order
    a.first_name ASC,        -- Sorting by first name 
    a.last_name ASC          -- Sorting by last name 
LIMIT 5;  -- Fetch only the top 5 actors based on the number of movies

--1.4)Number of Drama, Travel, Documentary per year (columns: release_year, number_of_drama_movies, number_of_travel_movies, number_of_documentary_movies),
--sorted by release year in descending order. Dealing with NULL values is encouraged)
-- Selecting the release year and counting the number of movies in Drama, Travel, and Documentary categories
SELECT f.release_year, 
-- Counting the number of Drama movies, using COALESCE to handle NULL values
COALESCE(SUM(CASE WHEN c.name = 'Drama' THEN 1 ELSE 0 END), 0) AS number_of_drama_movies, 
-- Counting the number of Travel movies
COALESCE(SUM(CASE WHEN c.name = 'Travel' THEN 1 ELSE 0 END), 0) AS number_of_travel_movies, 
-- Counting the number of Documentary movies
COALESCE(SUM(CASE WHEN c.name = 'Documentary' THEN 1 ELSE 0 END), 0) AS number_of_documentary_movies
FROM film f
-- Using INNER JOIN to link films with their respective categories
INNER JOIN film_category fc  ON f.film_id = fc.film_id  -- Joining on film_id ensures we only count films that have categories
-- Using INNER JOIN to get category details
INNER JOIN category c ON fc.category_id = c.category_id  -- Ensures we only get relevant category names
-- Filtering only relevant categories
WHERE c.name IN ('Drama', 'Travel', 'Documentary')
-- Grouping by release year to get movie counts per year
GROUP BY f.release_year 
-- Sorting by release year in descending order to get the latest years first
ORDER BY f.release_year DESC;

--2.1
--Which three employees generated the most revenue in 2017? They should be awarded a bonus for their outstanding performance. 
WITH staff_store AS (
    -- Find the last store each staff worked at in 2017
    SELECT 
        p.staff_id, 
        s.store_id,
        MAX(p.payment_date) AS last_payment_date  -- Find the latest payment date per staff to determine last store
    FROM payment p
    INNER JOIN staff s ON p.staff_id = s.staff_id
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017  -- Consider only payments in 2017
    GROUP BY p.staff_id, s.store_id
),

staff_revenue AS (
    -- Calculate total revenue per staff in 2017
    SELECT 
        p.staff_id, 
        SUM(p.amount) AS total_revenue
    FROM payment p
    WHERE EXTRACT(YEAR FROM p.payment_date) = 2017  -- Consider only payments in 2017
    GROUP BY p.staff_id
)

-- Fetch top 3 employees based on revenue and include their last store
SELECT 
    s.first_name, 
    s.last_name, 
    ss.store_id, 
    sr.total_revenue
FROM staff_revenue sr
INNER JOIN staff s ON sr.staff_id = s.staff_id
INNER JOIN staff_store ss ON sr.staff_id = ss.staff_id
ORDER BY sr.total_revenue DESC  -- Sort by revenue in descending order
LIMIT 3;

--2.2

WITH movie_rentals AS (
    -- Count number of times each movie was rented
    SELECT 
        i.film_id, 
        COUNT(r.rental_id) AS rental_count
    FROM public.rental r
    INNER JOIN public.inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
)

-- Retrieve movie details and expected audience age directly, without an extra CTE
SELECT 
    f.title, 
    mr.rental_count, 
    f.rating, 
    CASE 
        WHEN f.rating = 'G' THEN 'All ages'
        WHEN f.rating = 'PG' THEN '10+'
        WHEN f.rating = 'PG-13' THEN '13+'
        WHEN f.rating = 'R' THEN '17+'
        WHEN f.rating = 'NC-17' THEN '18+'
        ELSE 'Unknown'
    END AS expected_audience_age
FROM movie_rentals mr
INNER JOIN public.film f ON mr.film_id = f.film_id
ORDER BY mr.rental_count DESC  -- Sorting by rental count
LIMIT 5;  -- Get the top 5 movies only

--3
--Which actors/actresses didn't act for a longer period of time than the others? 
--gap between the latest release_year and current year per each actor;
SELECT 
    a.first_name, 
    a.last_name, 
    MAX(f.release_year) AS last_movie_year, 
    --get inactivity years
    EXTRACT(YEAR FROM CURRENT_DATE) - MAX(f.release_year) AS inactivity_period 
FROM actor a

-- Joining to find movies the actor has acted in
INNER JOIN film_actor fa ON a.actor_id = fa.actor_id
INNER JOIN film f ON fa.film_id = f.film_id

GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY inactivity_period DESC;
