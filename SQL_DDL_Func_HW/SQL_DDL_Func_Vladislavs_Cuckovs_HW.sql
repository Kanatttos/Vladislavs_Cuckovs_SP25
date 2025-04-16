-- 1 Create a view called 'sales_revenue_by_category_qtr' that shows the film category and total sales revenue for the current quarter
-- and year. The view should only display categories with at least one sale in the current quarter. 
-- DROP VIEW IF EXISTS to ensure rerunnable behavior

-- Create the view
CREATE OR REPLACE VIEW public.sales_revenue_by_category_qtr AS
WITH current_quarter AS (
    SELECT 
        EXTRACT(YEAR FROM CURRENT_DATE)::INT AS current_year,
        EXTRACT(QUARTER FROM CURRENT_DATE)::INT AS current_quarter
),
category_sales AS (
    SELECT 
        public.category.name AS category_name,
        SUM(public.payment.amount)::NUMERIC(10,2) AS total_revenue,
        EXTRACT(YEAR FROM public.payment.payment_date)::INT AS payment_year,
        EXTRACT(QUARTER FROM public.payment.payment_date)::INT AS payment_quarter
    FROM 
        public.payment
        JOIN public.rental ON public.payment.rental_id = public.rental.rental_id
        JOIN public.inventory ON public.rental.inventory_id = public.inventory.inventory_id
        JOIN public.film ON public.inventory.film_id = public.film.film_id
        JOIN public.film_category ON public.film.film_id = public.film_category.film_id
        JOIN public.category ON public.film_category.category_id = public.category.category_id
    GROUP BY 
        public.category.name, payment_year, payment_quarter
)
SELECT 
    category_sales.category_name,
    category_sales.total_revenue,
    category_sales.payment_year,
    category_sales.payment_quarter
FROM 
    category_sales
    JOIN current_quarter 
      ON category_sales.payment_year = current_quarter.current_year 
     AND category_sales.payment_quarter = current_quarter.current_quarter
WHERE 
    category_sales.total_revenue > 0;

--use
SELECT * FROM public.sales_revenue_by_category_qtr;


--2.Create a query language function called 'get_sales_revenue_by_category_qtr' that accepts one parameter representing 
--the current quarter and year and returns the same result as the 'sales_revenue_by_category_qtr' view.

-- Create the function
CREATE OR REPLACE FUNCTION public.get_sales_revenue_by_category_qtr(
    in_quarter INT,
    in_year INT
)
RETURNS TABLE (
    category_name VARCHAR,
    total_revenue NUMERIC(10,2),
    payment_year INT,
    payment_quarter INT
)
LANGUAGE sql
AS $$
    SELECT 
        public.category.name AS category_name,
        SUM(public.payment.amount)::NUMERIC(10,2) AS total_revenue,
        EXTRACT(YEAR FROM public.payment.payment_date)::INT AS payment_year,
        EXTRACT(QUARTER FROM public.payment.payment_date)::INT AS payment_quarter
    FROM 
        public.payment
        JOIN public.rental ON public.payment.rental_id = public.rental.rental_id
        JOIN public.inventory ON public.rental.inventory_id = public.inventory.inventory_id
        JOIN public.film ON public.inventory.film_id = public.film.film_id
        JOIN public.film_category ON public.film.film_id = public.film_category.film_id
        JOIN public.category ON public.film_category.category_id = public.category.category_id
    WHERE 
        EXTRACT(YEAR FROM public.payment.payment_date) = in_year
        AND EXTRACT(QUARTER FROM public.payment.payment_date) = in_quarter
    GROUP BY 
        public.category.name, payment_year, payment_quarter
    HAVING 
        SUM(public.payment.amount) > 0;
$$;
-- use
SELECT * FROM public.get_sales_revenue_by_category_qtr(2, 2017);


--3.Create a function that takes a country as an input parameter and 
--returns the most popular film in that specific country.
-- Drop existing function for clean rerun

CREATE OR REPLACE FUNCTION public.most_popular_films_by_countries(country_list TEXT[])
RETURNS TABLE (
    country TEXT,
    film TEXT,
    rating TEXT,
    language TEXT,
    length INT,
    release_year INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF array_length(country_list, 1) IS NULL THEN
        RAISE EXCEPTION 'Input country list cannot be null or empty';
    END IF;

    RETURN QUERY
    SELECT DISTINCT ON (public.country.country)
        public.country.country,
        public.film.title AS film,
        public.film.rating::TEXT,
        public.language.name::TEXT AS language,
        public.film.length::INT,
        public.film.release_year::INT
    FROM public.rental
    JOIN public.customer ON public.rental.customer_id = public.customer.customer_id
    JOIN public.address ON public.customer.address_id = public.address.address_id
    JOIN public.city ON public.address.city_id = public.city.city_id
    JOIN public.country ON public.city.country_id = public.country.country_id
    JOIN public.inventory ON public.rental.inventory_id = public.inventory.inventory_id
    JOIN public.film ON public.inventory.film_id = public.film.film_id
    JOIN public.language ON public.film.language_id = public.language.language_id
    WHERE public.country.country = ANY (country_list)
    GROUP BY 
        public.country.country, 
        public.film.title, 
        public.film.rating, 
        public.language.name, 
        public.film.length, 
        public.film.release_year
    ORDER BY 
        public.country.country, 
        COUNT(public.rental.rental_id) DESC;
END;
$$;

--use
SELECT * FROM public.most_popular_films_by_countries(ARRAY['Afghanistan', 'Brazil', 'United States']);

--4.Create a function that generates a list of movies available in stock based on 
--a partial title match (e.g., movies containing the word 'love' in their title).
CREATE OR REPLACE FUNCTION public.films_in_stock_by_title(title_pattern TEXT)
RETURNS TABLE (
    row_num INT,
    film_title TEXT,
    language TEXT,
    customer_name TEXT,
    rental_date TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    WITH matching_films AS (
        SELECT
            public.film.film_id,
            public.film.title AS mf_title,
            public.language.name AS mf_language
        FROM public.film
        JOIN public.language ON public.film.language_id = public.language.language_id
        WHERE UPPER(public.film.title) ILIKE UPPER(title_pattern)
    ),
    rental_data AS (
        SELECT
            public.rental.rental_date AS rd_rental_date,
            public.rental.inventory_id,
            public.customer.first_name || ' ' || public.customer.last_name AS rd_customer_name
        FROM public.rental
        JOIN public.customer ON public.rental.customer_id = public.customer.customer_id
    ),
    available_inventory AS (
        SELECT
            public.inventory.film_id,
            public.inventory.inventory_id
        FROM public.inventory
        LEFT JOIN public.rental ON public.inventory.inventory_id = public.rental.inventory_id
        WHERE public.rental.return_date IS NOT NULL
    ),
    film_stock AS (
        SELECT DISTINCT
            matching_films.mf_title,
            matching_films.mf_language,
            rental_data.rd_customer_name,
            rental_data.rd_rental_date
        FROM matching_films
        JOIN available_inventory ON matching_films.film_id = available_inventory.film_id
        LEFT JOIN rental_data ON available_inventory.inventory_id = rental_data.inventory_id
    )
    SELECT
        ROW_NUMBER() OVER (ORDER BY mf_title)::INT,
        mf_title::TEXT,
        mf_language::TEXT,
        COALESCE(rd_customer_name, '-') AS customer_name,
        rd_rental_date::TIMESTAMP AS rental_date 
    FROM film_stock;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'No films found in stock with title matching %', title_pattern;
    END IF;
END;
$$ LANGUAGE plpgsql;



SELECT * FROM public.films_in_stock_by_title('%love%');


--5.Create a procedure language function called 'new_movie' that takes a movie title as a parameter and inserts a 
--new movie with the given title in the film table. The function should generate a new unique film ID, 
--set the rental rate to 4.99, the rental duration to three days, the replacement cost to 19.99. 
--The release year and language are optional and by default should be current year and Klingon respectively. 
--The function should also verify that the language exists in the 'language' table. 
--Then, ensure that no such function has been created before; if so, replace it.
CREATE OR REPLACE FUNCTION public.new_movie(
    movie_title TEXT,
    movie_release_year INTEGER DEFAULT EXTRACT(YEAR FROM CURRENT_DATE),
    lang_name TEXT DEFAULT 'Klingon'
) RETURNS VOID AS
$$
DECLARE
    lang_id INTEGER;
    new_film_id INTEGER;
BEGIN
    -- Validate title
    IF movie_title IS NULL OR TRIM(movie_title) = '' THEN
        RAISE EXCEPTION 'Movie title cannot be null or empty';
    END IF;

    -- Check if the language exists
    SELECT public.language.language_id INTO lang_id
    FROM public.language
    WHERE UPPER(public.language.name) = UPPER(lang_name);

    IF lang_id IS NULL THEN
        INSERT INTO public.language (name)
        VALUES (lang_name)
        RETURNING public.language.language_id INTO lang_id;
    END IF;

    -- Generate a new film_id
    SELECT MAX(public.film.film_id) + 1 INTO new_film_id
    FROM public.film;

    -- Check for duplicates
    IF EXISTS (
        SELECT 1
        FROM public.film
        WHERE UPPER(public.film.title) = UPPER(movie_title)
          AND public.film.release_year = movie_release_year
          AND public.film.language_id = lang_id
    ) THEN
        RAISE EXCEPTION 'Movie "%" already exists for language "%" and year %',
            movie_title, lang_name, movie_release_year;
    END IF;

    -- Insert new film
    INSERT INTO public.film (
        film_id, title, release_year, language_id,
        rental_duration, rental_rate, replacement_cost
    ) VALUES (
        new_film_id, movie_title, movie_release_year, lang_id,
        3, 4.99, 19.99
    );

    RAISE NOTICE 'New movie "%" added with ID %', movie_title, new_film_id;
END;
$$ LANGUAGE plpgsql;

--Use
SELECT public.new_movie('Pirates of the Caribbean: Dead Man''s Chest', 2006, 'English');

--Test for 6
CREATE OR REPLACE FUNCTION public.rewards_report(
    min_monthly_purchases INTEGER,
    min_dollar_amount_purchased NUMERIC
)
RETURNS SETOF public.customer
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
    last_month_start DATE;
    last_month_end DATE;
    rr RECORD;
BEGIN
    -- Check
    IF min_monthly_purchases <= 0 THEN
        RAISE EXCEPTION 'Minimum monthly purchases must be > 0';
    END IF;
    IF min_dollar_amount_purchased <= 0 THEN
        RAISE EXCEPTION 'Minimum dollar amount must be > 0.00';
    END IF;

    -- Set range to last full month
    last_month_start := date_trunc('month', CURRENT_DATE - INTERVAL '1 month')::DATE;
    last_month_end := (date_trunc('month', CURRENT_DATE))::DATE - INTERVAL '1 day';

    -- DEBUG NOTICE
    RAISE NOTICE 'Date range: % to %', last_month_start, last_month_end;

    -- Temp table for qualifying customers
    CREATE TEMP TABLE public.tmpCustomer (customer_id INTEGER PRIMARY KEY) ON COMMIT DROP;

    -- Insert qualifying customer IDs
    INSERT INTO public.tmpCustomer (customer_id)
    SELECT p.customer_id
    FROM public.payment p
    WHERE DATE(p.payment_date) BETWEEN last_month_start AND last_month_end
    GROUP BY p.customer_id
    HAVING COUNT(*) >= min_monthly_purchases
       AND SUM(p.amount) >= min_dollar_amount_purchased;

    -- Return customer details
    FOR rr IN
        SELECT c.* FROM public.tmpCustomer t
        JOIN public.customer c ON c.customer_id = t.customer_id
    LOOP
        RETURN NEXT rr;
    END LOOP;

    RETURN;
END
$function$;


--6 get_customer_balance

CREATE OR REPLACE FUNCTION public.get_customer_balance(
    p_customer_id INTEGER,
    p_effective_date TIMESTAMPTZ
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $function$
DECLARE
    v_rentfees NUMERIC(5,2);   -- 1) rental fees
    v_overfees NUMERIC(5,2);   -- 2) late fees
    v_replacement NUMERIC(5,2);-- 3) replacement cost for overdue
    v_payments NUMERIC(5,2);   -- 4) payments made
BEGIN
    -- 1) Rental fees for all previous rentals
    SELECT COALESCE(SUM(f.rental_rate), 0)
    INTO v_rentfees
    FROM public.film f
    JOIN public.inventory i ON f.film_id = i.film_id
    JOIN public.rental r ON r.inventory_id = i.inventory_id
    WHERE r.rental_date <= p_effective_date
      AND r.customer_id = p_customer_id;

    -- 2) $1 per day overdue, but not beyond 2x rental_duration
    SELECT COALESCE(SUM(
        CASE 
            WHEN r.return_date IS NOT NULL AND 
                 r.return_date > r.rental_date + (f.rental_duration * INTERVAL '1 day')
            THEN LEAST(
                EXTRACT(DAY FROM r.return_date - r.rental_date - (f.rental_duration * INTERVAL '1 day')),
                f.rental_duration
            )
            ELSE 0
        END
    ), 0)
    INTO v_overfees
    FROM public.film f
    JOIN public.inventory i ON f.film_id = i.film_id
    JOIN public.rental r ON r.inventory_id = i.inventory_id
    WHERE r.rental_date <= p_effective_date
      AND r.customer_id = p_customer_id;

    -- 3) Replacement cost if overdue more than 2x rental duration
    SELECT COALESCE(SUM(
        CASE 
            WHEN r.return_date IS NOT NULL AND 
                 r.return_date > r.rental_date + (f.rental_duration * INTERVAL '2 day')
            THEN f.replacement_cost
            ELSE 0
        END
    ), 0)
    INTO v_replacement
    FROM public.film f
    JOIN public.inventory i ON f.film_id = i.film_id
    JOIN public.rental r ON r.inventory_id = i.inventory_id
    WHERE r.rental_date <= p_effective_date
      AND r.customer_id = p_customer_id;

    -- 4) Subtract all payments before the given date
    SELECT COALESCE(SUM(p.amount), 0)
    INTO v_payments
    FROM public.payment p
    WHERE public.p.payment_date <= p_effective_date
      AND p.customer_id = p_customer_id;

    -- Return total balance
    RETURN v_rentfees + v_overfees + v_replacement - v_payments;
END
$function$;