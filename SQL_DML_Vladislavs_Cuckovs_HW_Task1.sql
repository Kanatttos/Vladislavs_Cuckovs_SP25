--1.1
INSERT INTO public.film (title, description, release_year, language_id,rental_duration,  --INSERT this information
						rental_rate, length, replacement_cost, rating, last_update)
SELECT * FROM(
VALUES															-- FILMS VALUES
( 'Pirates of the Caribbean: The Curse of the Black Pearl', 
'Blacksmith Will Turner teams up with eccentric pirate "Captain" Jack Sparrow to save Elizabeth Swann, the governors daughter and his love',
2003, (SELECT l.language_id FROM public.language l INNER JOIN public.film f ON l.language_id = f.language_id
	WHERE l.language_id = f.language_id AND f.title = 'Pirates of the Caribbean: The Curse of the Black Pearl'), 1, 4.99, 143, 29.99, 'PG-13'::mpaa_rating, CURRENT_DATE),
( 'The Lord of the Rings: The Fellowship of the Ring','A meek Hobbit from the Shire and eight companions set out on a journey to destroy the powerful One Ring and save Middle-earth from the Dark Lord Sauron.',
2001, (SELECT l.language_id FROM public.language l INNER JOIN public.film f ON l.language_id = f.language_id
	WHERE l.language_id = f.language_id AND f.title = 'The Lord of the Rings: The Fellowship of the Ring'), 3, 19.99, 178, 30.99, 'PG'::mpaa_rating, CURRENT_DATE),
( 'Grave of the Fireflies', 'A young boy and his little sister struggle to survive in Japan during World War II.',
1998, (SELECT l.language_id FROM public.language l INNER JOIN public.film f ON l.language_id = f.language_id
	WHERE l.language_id = f.language_id AND f.title = 'Grave of the Fireflies'), 2, 9.99, 89, 49.99, 'PG'::mpaa_rating, CURRENT_DATE)) AS new_film (title, description, release_year, language_id,rental_duration,
									rental_rate, length, replacement_cost, rating)
WHERE NOT EXISTS (
    SELECT 1 FROM public.film f 
    WHERE f.title = new_film.title 
    AND f.description = new_film.description 
    AND f.release_year = new_film.release_year 
    AND f.language_id = new_film.language_id 
    AND f.rental_duration = new_film.rental_duration
    AND f.rental_rate = new_film.rental_rate 
    AND f.length = new_film.length
    AND f.replacement_cost = new_film.replacement_cost 
    AND f.rating = new_film.rating
)
RETURNING film_id,title, description, release_year, language_id,rental_duration, --RETURN IF RECORDS ARE INSERTED
		rental_rate, length, replacement_cost, rating, last_update;
--1.2
INSERT INTO public.actor(first_name, last_name, last_update) --INSERT this information
SELECT * FROM(
VALUES -- ACTOR VALUES
('Johnny', 'Depp', CURRENT_DATE),
('Orlando', 'Bloom', CURRENT_DATE),
('Elijah', 'Wood', CURRENT_DATE),
('Ian', 'McKellen', CURRENT_DATE),
('Tsutomu', 'Tatsumi', CURRENT_DATE),
('Ayano', 'Shiraishi', CURRENT_DATE)) AS new_actor(first_name, last_name, last_update)
WHERE NOT EXISTS (SELECT 1 FROM public.actor a WHERE a.first_name = new_actor.first_name AND a.last_name = new_actor.last_name) --CHECK IF NOT ALREADY EXISTS
RETURNING actor_id, first_name, last_name; --RETURN IF RECORDS ARE INSERTED

INSERT INTO public.film_actor (actor_id,film_id, last_update) --INSERT this information
SELECT * FROM( 
VALUES -- ACTOR VALUES  NOT HADRCORED
((SELECT actor_id FROM public.actor WHERE UPPER(first_name) LIKE UPPER('Johnny')
									AND UPPER(last_name) LIKE UPPER('Depp')),
(SELECT film_id FROM public.film WHERE title ='Pirates of the Caribbean: The Curse of the Black Pearl'), CURRENT_DATE),

((SELECT actor_id FROM public.actor WHERE UPPER(first_name) LIKE UPPER('Orlando')
									AND UPPER(last_name) LIKE UPPER('Bloom')),
(SELECT film_id FROM public.film WHERE title ='Pirates of the Caribbean: The Curse of the Black Pearl'),CURRENT_DATE),

((SELECT actor_id FROM public.actor WHERE UPPER(first_name) LIKE UPPER('Elijah')
									AND UPPER(last_name) LIKE UPPER('Wood')),
(SELECT film_id FROM public.film WHERE title ='The Lord of the Rings: The Fellowship of the Ring'),CURRENT_DATE),

((SELECT actor_id FROM public.actor WHERE UPPER(first_name) LIKE UPPER('Ian')
									AND UPPER(last_name) LIKE UPPER('McKellen')),
(SELECT film_id FROM public.film WHERE title ='The Lord of the Rings: The Fellowship of the Ring'),CURRENT_DATE),

((SELECT actor_id FROM public.actor WHERE UPPER(first_name) LIKE UPPER('Tsutomu')
									AND UPPER(last_name) LIKE UPPER('Tatsumi')),
(SELECT film_id FROM public.film WHERE title ='Grave of the Fireflies'),CURRENT_DATE),
((SELECT actor_id FROM public.actor WHERE UPPER(first_name) LIKE UPPER('Ayano')
									AND UPPER(last_name) LIKE UPPER('Shiraishi')),
(SELECT film_id FROM public.film WHERE title ='Grave of the Fireflies'),CURRENT_DATE)
) AS new_film_actor (actor_id,film_id,last_update)

WHERE NOT EXISTS (SELECT 1 FROM public.film_actor fa WHERE fa.actor_id = new_film_actor.actor_id AND fa.film_id = new_film_actor.film_id
					AND fa.last_update = new_film_actor.last_update) --CHECK IF NOT ALREADY EXISTS
RETURNING actor_id, film_id, last_update; --RETURN IF RECORDS ARE INSERTED


--1.3
INSERT INTO public.inventory (film_id, store_id, last_update) --INSERT this information
SELECT * FROM(
VALUES --VALUES TO INSERT
((SELECT film_id FROM public.film WHERE title ='Pirates of the Caribbean: The Curse of the Black Pearl'),
	1, CURRENT_DATE),
((SELECT film_id FROM public.film WHERE title ='The Lord of the Rings: The Fellowship of the Ring'),
   1, CURRENT_DATE),
((SELECT film_id FROM public.film WHERE title ='Grave of the Fireflies'),
   1, CURRENT_DATE)) AS new_inventory (film_id, store_id)
WHERE NOT EXISTS(SELECT 1 FROM public.inventory i WHERE i.film_id = new_inventory.film_id  --CHECK IF NOT ALREADY EXISTS
													AND i.store_id = new_inventory.store_id)
RETURNING inventory_id, film_id, store_id, last_update; --RETURN IF RECORDS ARE INSERTED

--1.4
UPDATE public.customer  --UPDATE CUSTOMER TABLE
SET first_name = 'Vladislavs', last_name = 'Cuckovs', email = 'vladislavs.cuckovs@gmail.com', 
address_id = (SELECT address_id FROM public.address LIMIT 1), last_update = CURRENT_DATE -- SET THIS DATA
WHERE customer_id = (
    SELECT c.customer_id
    FROM public.customer c
    JOIN public.rental r ON c.customer_id = r.customer_id
    JOIN public.payment p ON c.customer_id = p.customer_id
   	WHERE c.first_name NOT IN (SELECT first_name FROM public.customer) AND c.last_name NOT IN (SELECT last_name FROM public.customer)
    GROUP BY c.customer_id
    HAVING COUNT(r.rental_id) >= 43 AND COUNT(p.payment_id) >= 43
    LIMIT 1
)
RETURNING customer_id; --RETURN IF It's been updated

--1.5
DELETE FROM public.payment  --DELETE ALL PAYMENT INFORMATION FROM ADDED PERSON
WHERE rental_id IN (
    SELECT rental_id 
    FROM public.rental 
    WHERE customer_id = (
        SELECT customer_id 
        FROM public.customer 
        WHERE UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')
        LIMIT 1
    )
);
DELETE FROM public.rental --DELETE ALL RENTAL INFORMATION FROM ADDED PERSON
WHERE customer_id  IN (
    SELECT customer_id 
    FROM public.customer 
     WHERE UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')
);

-- 1.6

--1.6.1 Renting films
INSERT INTO public.rental (
	rental_date, inventory_id, customer_id, return_date, staff_id, last_update) --INSERT this information
SELECT * FROM(
VALUES  --VALUES TO INSERT BY USING SELECT OPTION TO AVOID HARDCORED ID
('2025-03-26 10:10:10-03:00'::timestamptz, (SELECT inventory_id FROM public.inventory i JOIN
				public.film f ON i.film_id = f.film_id 
				WHERE f.title = 'Pirates of the Caribbean: The Curse of the Black Pearl'),
				(SELECT customer_id FROM public.customer WHERE UPPER(first_name) LIKE UPPER('Vladislavs') 
				AND UPPER(last_name) LIKE UPPER('Cuckovs') AND  UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')),
				'2025-03-29 10:10:10-03:00'::timestamptz, 
				 (SELECT staff_id FROM public.staff s JOIN public.store st ON s.store_id = st.store_id AND s.staff_id =st.manager_staff_id
				 JOIN public.inventory i ON st.store_id = i.store_id 
				 JOIN film f ON i.film_id = f.film_id WHERE f.title = 'Pirates of the Caribbean: The Curse of the Black Pearl'),
				 CURRENT_DATE),
('2025-03-26 10:10:10-03:00'::timestamptz, (SELECT inventory_id FROM public.inventory i JOIN
				public.film f ON i.film_id = f.film_id 
				WHERE f.title = 'The Lord of the Rings: The Fellowship of the Ring'),
				(SELECT customer_id FROM public.customer WHERE UPPER(first_name) LIKE UPPER('Vladislavs') 
				AND UPPER(last_name) LIKE UPPER('Cuckovs') AND UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')),
				 '2025-03-30 10:10:10-03:00'::timestamptz, 
				 (SELECT staff_id FROM public.staff s JOIN public.store st ON s.store_id = st.store_id AND s.staff_id =st.manager_staff_id
				 JOIN public.inventory i ON st.store_id = i.store_id 
				 JOIN film f ON i.film_id = f.film_id WHERE f.title = 'The Lord of the Rings: The Fellowship of the Ring'),
				 CURRENT_DATE),
('2025-03-26 10:10:10-03:00'::timestamptz, (SELECT inventory_id FROM public.inventory i JOIN
				public.film f ON i.film_id = f.film_id 
				WHERE f.title = 'Grave of the Fireflies'),
				(SELECT customer_id FROM public.customer WHERE UPPER(first_name) LIKE UPPER('Vladislavs') 
				AND UPPER(last_name) LIKE UPPER('Cuckovs') AND UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')),
				 '2025-03-31 10:10:10-03:00'::timestamptz, 
				 (SELECT staff_id FROM public.staff s JOIN public.store st ON s.store_id = st.store_id AND s.staff_id =st.manager_staff_id
				 JOIN public.inventory i ON st.store_id = i.store_id 
				 JOIN film f ON i.film_id = f.film_id WHERE f.title = 'Grave of the Fireflies'),
				 CURRENT_DATE)
) AS new_rent  (rental_date, inventory_id, customer_id, return_date, staff_id, last_update)

WHERE NOT EXISTS(SELECT 1 FROM public.rental r WHERE r.rental_date = new_rent.rental_date     --CHECK IF NOT ALREADY EXISTS
													AND r.inventory_id = new_rent.inventory_id 
													AND r.customer_id = new_rent.customer_id
													AND r.return_date = new_rent.return_date
													AND r.staff_id = new_rent.staff_id
													AND r.last_update = new_rent.last_update)	
RETURNING rental_id, rental_date, inventory_id, customer_id, return_date, staff_id, last_update; --RETURN IF RECORDS ARE INSERTED

--1.6.2
INSERT INTO public.payment (customer_id, staff_id, rental_id, amount, payment_date)  --INSERT this information
SELECT * FROM(
VALUES  --VALUES TO INSERT BY USING SELECT OPTION TO AVOID HARDCORED ID
((SELECT customer_id FROM public.customer WHERE UPPER(first_name) LIKE UPPER('Vladislavs') 
				AND UPPER(last_name) LIKE UPPER('Cuckovs') AND UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')),
				(SELECT staff_id FROM public.staff s JOIN public.store st ON s.store_id = st.store_id AND s.staff_id =st.manager_staff_id
				 JOIN public.inventory i ON st.store_id = i.store_id 
				 JOIN film f ON i.film_id = f.film_id WHERE f.title = 'Pirates of the Caribbean: The Curse of the Black Pearl'),
				 (SELECT rental_id FROM public.rental r JOIN inventory i ON r.inventory_id = i.inventory_id
				 JOIN film f ON i.film_id = f.film_id 
				 WHERE f.title = 'Pirates of the Caribbean: The Curse of the Black Pearl'),
				 (SELECT rental_rate FROM public.film WHERE title = 'Pirates of the Caribbean: The Curse of the Black Pearl' ),
				  '2017-03-31 10:10:10-03:00'::timestamptz),
((SELECT customer_id FROM public.customer WHERE UPPER(first_name) LIKE UPPER('Vladislavs') 
				AND UPPER(last_name) LIKE UPPER('Cuckovs') AND UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')),
				(SELECT staff_id FROM public.staff s JOIN public.store st ON s.store_id = st.store_id AND s.staff_id =st.manager_staff_id
				 JOIN public.inventory i ON st.store_id = i.store_id 
				 JOIN film f ON i.film_id = f.film_id WHERE f.title = 'The Lord of the Rings: The Fellowship of the Ring'),
				 (SELECT rental_id FROM public.rental r JOIN inventory i ON r.inventory_id = i.inventory_id
				 JOIN film f ON i.film_id = f.film_id 
				 WHERE f.title = 'The Lord of the Rings: The Fellowship of the Ring'),
				 (SELECT rental_rate FROM public.film WHERE title = 'The Lord of the Rings: The Fellowship of the Ring' ),
				  '2017-03-31 10:10:10-03:00'::timestamptz),
((SELECT customer_id FROM public.customer WHERE UPPER(first_name) LIKE UPPER('Vladislavs') 
				AND UPPER(last_name) LIKE UPPER('Cuckovs') AND UPPER(email) = UPPER('vladislavs.cuckovs@gmail.com')),
				(SELECT staff_id FROM public.staff s JOIN public.store st ON s.store_id = st.store_id AND s.staff_id =st.manager_staff_id
				 JOIN public.inventory i ON st.store_id = i.store_id 
				 JOIN film f ON i.film_id = f.film_id WHERE f.title = 'Grave of the Fireflies'),
				 (SELECT rental_id FROM public.rental r JOIN inventory i ON r.inventory_id = i.inventory_id
				 JOIN film f ON i.film_id = f.film_id 
				 WHERE f.title = 'Grave of the Fireflies'),
				 (SELECT rental_rate FROM public.film WHERE title = 'Grave of the Fireflies' ),
				 '2017-03-31 10:10:10-03:00'::timestamptz)

) AS new_payment (customer_id, staff_id, rental_id, amount, payment_date)
WHERE NOT EXISTS(SELECT 1 FROM public.payment p WHERE p.customer_id = new_payment.customer_id  --CHECK IF NOT ALREADY EXISTS
													AND p.staff_id = new_payment.staff_id 
													AND p.rental_id = new_payment.rental_id
													AND p.amount = new_payment.amount
													AND p.payment_date = new_payment.payment_date)
RETURNING payment_id, customer_id, staff_id, rental_id, amount, payment_date; --RETURN IF RECORDS ARE INSERTED