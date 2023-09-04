-------------------------------------
-- A. Customer Journey --
-------------------------------------
--	Based off the 8 sample customers provided in the sample from the `subscriptions` table, write a brief description about each customer’s onboarding journey. Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!

SELECT su.*,
       plan_name,
       price
FROM foodie_fi.dbo.subscriptions AS su
JOIN foodie_fi.dbo.plans AS pl ON pl.plan_id = su.plan_id
WHERE customer_id IN (1, 2, 11, 13, 15, 16, 18, 19)

--	Drawing from the presented data:
--		- Customer 1: Started trial on August 1, 2020. Upgraded to "Basic Monthly" plan on August 8, 2020.
--		- Customer 2: Started trial on September 20, 2020. Upgraded to "Pro Annual" plan on September 27, 2020.
--		- Customer 11: Started trial on November 19, 2020. Churned out on November 26, 2020.
--		- Customer 13: Started trial on December 15, 2020. Upgraded to "Basic Monthly" plan on December 22, 2020. Further upgraded to "Pro Monthly" plan on March 29, 2021.
--		- Customer 15: Started trial on March 17, 2020. Upgraded to "Pro Monthly" plan on March 24, 2020. Churned out on April 29, 2020.
--		- Customer 16: Started trial on May 31, 2020. Upgraded to "Basic Monthly" plan on June 7, 2020. Further upgraded to "Pro Annual" plan on October 21, 2020.
--		- Customer 18: Started trial on July 6, 2020. Upgraded to "Pro Monthly" plan on July 13, 2020.
--		- Customer 19: Started trial on June 22, 2020. Upgraded to "Pro Monthly" plan on June 29, 2020. Further upgraded to "Pro Annual" plan on August 29, 2020.
