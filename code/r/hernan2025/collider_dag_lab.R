# TODO: Use dagitty code to create the DAG described above.
# Hint: You'll need arrows from A to S, Y to S, and U to both Y and S.
# Don't forget the main causal arrow from A to Y!

pacman::p_load(dagitty, ggdag, tidyverse, broom, knitr)
my_dag <- dagitty::dagitty(
  "dag {
 A [exposure]
 Y [outcome]
 S 
 U [unobserved]
A -> Y
A -> S
Y -> S
U -> Y
U -> S
}"
)

ggdag::ggdag(my_dag) +
  ggdag::theme_dag()

ggdag::ggdag_status(my_dag)

ggdag::ggdag_adjustment_set(my_dag, exposure = "A", outcome = "Y")

######## ######## Data Simulation ######## ########

set.seed(42)

n_full_pop <- 20000

# 1. Simulate the unmeasured confounder U (Motivation)
u <- rnorm(n_full_pop, mean = 10, sd = 2)

# 2. Simulate the randomized exposure A
a <- rbinom(n_full_pop, 1, 0.5)

# 3. Simulate the outcome Y (Weight Loss)
# Y should depend on A (the true effect) and U.
# The coefficient for 'a' should be 2.
y <- 2 * a + 0.5 * u + rnorm(n_full_pop, mean = 0, sd = 2)

# 4. Simulate the selection mechanism S (Active User)
# S should depend on A, Y, and U. We'll use a logistic model.
# The probability of being active increases with A, Y, and U.
prob_s <- plogis(5 * a + 2 * y - 1 * u - 10) # The -10 is just to scale the probability
s <- rbinom(n_full_pop, 1, prob_s)

# 5. Assemble the full and selected datasets
full_population <- tibble(A = a, Y = y, U = u, S = s)
selected_sample <- dplyr::filter(full_population, S == 1)

# Check the sizes of the datasets
cat("Full population size:", nrow(full_population), "\n")
cat("Selected sample size:", nrow(selected_sample), "\n")
