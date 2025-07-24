# Rule-Based Classifier: Concepts & Documentation

---

## Table of Contents
1. [Overview](#overview)
2. [Rule Application Flow (Diagram)](#rule-application-flow-diagram)
3. [Rule Coverage and Accuracy](#rule-coverage-and-accuracy)
4. [Example Rule Application](#example-rule-application)
5. [Conflict Resolution](#conflict-resolution)
6. [Rule Scanning and Selection](#rule-scanning-and-selection)

---

## Overview
A **rule-based classifier** uses a set of IF-THEN rules to make predictions about data. Each rule consists of:
- **Antecedent** (the IF part): The condition(s) that must be satisfied.
- **Consequent** (the THEN part): The predicted class or outcome if the antecedent is true.

**Example Rule:**
```
IF age = 'youth' AND student = 'yes' THEN buys_computer = 'yes'
```

---

## Rule Application Flow (Diagram)

```mermaid
graph TD
    A[Start: Input Tuple] --> B{Does any rule match?}
    B -- No --> F[Assign Default Class]
    B -- Yes --> C[Select Most Specific Rule]
    C --> D[Apply Rule Consequent]
    D --> E[End]
    F --> E
```

---

## Rule Coverage and Accuracy

- **Rule Coverage:**
  - The percentage of tuples in the dataset that satisfy the rule's antecedent.
  - **Formula:**
    ```
    coverage(R) = n_covers / |D|
    ```
    - `n_covers`: Number of tuples that satisfy the rule's antecedent
    - `|D|`: Total number of tuples in the dataset
  - **Example:**
    - Dataset size |D| = 14
    - n_covers = 2
    - coverage(R1) = 2 / 14 = 14.28%

- **Rule Accuracy:**
  - The percentage of tuples covered by the rule that are correctly classified by the rule.
  - **Formula:**
    ```
    accuracy(R) = n_correct / n_covers
    ```
    - `n_correct`: Number of tuples correctly classified by the rule
    - `n_covers`: Number of tuples covered by the rule
  - **Example:**
    - n_correct = 2
    - n_covers = 2
    - accuracy(R1) = 2 / 2 = 100%

---

## Example Rule Application

- **Rule:**
  ```
  IF age = 'youth' AND student = 'yes' THEN buys_computer = 'yes'
  ```
- **Tuple:**
  ```
  X = (age = youth, income = medium, student = yes, credit_rating = fair)
  ```
- **Application:**
  - Only count tuples where all conditions in the rule's antecedent are true.

---

## Conflict Resolution

- If multiple rules match a tuple (**conflict**):
  - The rule with **more attributes** (i.e., more specific) is prioritized.
  - Example: If a rule with 3 attributes and a rule with 2 attributes both match, the 3-attribute rule is chosen.
- If **no rule** is triggered:
  - Assign the **default class** (the class with the highest occurrence in the dataset).

---

## Rule Scanning and Selection

- Rules are typically arranged in a **top-down order** (e.g., as in a decision tree).
- When scanning, as soon as a matching rule is found, further scanning stops and that rule is applied.
