
-- 2. Insert leading actors into the actor table and associate them with films
INSERT INTO public.actor (first_name, last_name, last_update)
SELECT * FROM (
    VALUES
    ('Johnny', 'Depp', CURRENT_DATE),
    ('Orlando', 'Bloom', CURRENT_DATE),
    ('Elijah', 'Wood', CURRENT_DATE),
    ('Ian', 'McKellen', CURRENT_DATE),
    ('Tsutomu', 'Tatsumi', CURRENT_DATE),
    ('Ayano', 'Shiraishi', CURRENT_DATE)
) AS new_actor(first_name, last_name, last_update)
WHERE NOT EXISTS (SELECT 1 FROM public.actor a WHERE a.first_name = new_actor.first_name AND a.last_name = new_actor.last_name)
RETURNING actor_id, first_name, last_name;

-- 1. Insert my top-3 favorite movies into the film table
WITH new_films AS (
    INSERT INTO public.film (title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
    SELECT * FROM (
        VALUES
        ('Pirates of the Caribbean: The Curse of the Black Pearl', 'Blacksmith Will Turner teams up with eccentric pirate "Captain" Jack Sparrow to save Elizabeth Swann, the governors daughter and his love', 2003, 1, 1, 4.99, 143, 29.99, 'PG-13'::mpaa_rating, CURRENT_DATE),
        ('The Lord of the Rings: The Fellowship of the Ring', 'A meek Hobbit from the Shire and eight companions set out on a journey to destroy the powerful One Ring and save Middle-earth from the Dark Lord Sauron.', 2001, 1, 3, 19.99, 178, 30.99, 'PG'::mpaa_rating, CURRENT_DATE),
        ('Grave of the Fireflies', 'A young boy and his little sister struggle to survive in Japan during World War II.', 1988, 1, 2, 9.99, 89, 49.99, 'PG', CURRENT_DATE)
    ) AS new_film(title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, last_update)
    WHERE NOT EXISTS (SELECT 1 FROM public.film f WHERE f.title = new_film.title)
    RETURNING film_id, title
)


-- 3. Add these movies to an existing store’s inventory
INSERT INTO public.inventory (film_id, store_id, last_update)
SELECT f.film_id, s.store_id, CURRENT_DATE
FROM new_films f
CROSS JOIN (SELECT store_id FROM public.store LIMIT 1) s
WHERE NOT EXISTS (
    SELECT 1 FROM public.inventory i WHERE i.film_id = f.film_id AND i.store_id = s.store_id
);

-- 4. Update an existing customer with at least 43 rentals and payments
UPDATE public.customer
SET first_name = 'Vladislavs', last_name = 'Cuckovs', email = 'vladislavs.cuckovs@gmail.com', address_id = (SELECT address_id FROM public.address LIMIT 1), last_update = CURRENT_DATE
WHERE customer_id = (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.rental r ON c.customer_id = r.customer_id
    JOIN public.payment p ON c.customer_id = p.customer_id
    GROUP BY c.customer_id
    HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43
    LIMIT 1
)
RETURNING customer_id;

-- 5. Delete rental and payment records related to this customer
DELETE FROM public.payment
WHERE rental_id IN (
    SELECT rental_id 
    FROM public.rental 
    WHERE customer_id = (
        SELECT customer_id 
        FROM public.customer 
        WHERE email = 'vladislavs.cuckovs@gmail.com'
        LIMIT 1  
    )
);
DELETE FROM public.rental
WHERE customer_id = (
    SELECT customer_id 
    FROM public.customer 
    WHERE email = 'vladislavs.cuckovs@gmail.com'
    LIMIT 1
);

-- 6. Rent the movies from the store and pay for them
INSERT INTO public.rental (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)
SELECT CURRENT_DATE, i.inventory_id, c.customer_id, CURRENT_DATE + INTERVAL '7 days', 1, CURRENT_DATE
FROM public.inventory i
CROSS JOIN (SELECT customer_id FROM public.customer WHERE email = 'john.doe@example.com' LIMIT 1) c
WHERE i.film_id IN (SELECT film_id FROM public.film WHERE title IN ('Pirates of the Caribbean: The Curse of the Black Pearl', 'The Lord of the Rings: The Fellowship of the Ring', 'Grave of the Fireflies'))
RETURNING rental_id, inventory_id, customer_id;
-- 6.2 Make payments
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)
SELECT r.customer_id, 1, r.rental_id, f.rental_rate, CURRENT_DATE
FROM public.rental r
JOIN public.inventory i ON r.inventory_id = i.inventory_id
JOIN public.film f ON i.film_id = f.film_id
WHERE r.customer_id = (SELECT customer_id FROM public.customer WHERE email = 'vladislavs.cuckovs@gmail.com')
AND f.title IN ('Pirates of the Caribbean: The Curse of the Black Pearl', 'The Lord of the Rings: The Fellowship of the Ring', 'Grave of the Fireflies');