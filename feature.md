# Feature Request: User Food Inventory System

## Overview

The Food Inventory System allows users to store and manage all food items they currently have at home.
Items can be added manually, via barcode scanning, or through receipt scanning.

The inventory is used to:

* Track available food items
* Track quantities
* Monitor expiration dates
* Suggest recipes based on available ingredients
* Reduce food waste

---

# Goals

The system should allow users to:

1. See all food items currently available at home
2. Add new food items
3. Track quantity and units
4. Track expiration dates
5. Remove or update items
6. Use inventory data for recipe suggestions

---

# User Stories

### View Inventory

As a user
I want to see all ingredients I currently own
So that I know what food is available at home.

---

### Add Ingredient

As a user
I want to add an ingredient manually
So that I can track it in my inventory.

---

### Add Ingredient by Barcode

As a user
I want to scan a product barcode
So that the product is automatically added to my inventory.

Barcode data should be resolved using the OpenFoodFacts API.

---

### Track Quantity

As a user
I want to store the quantity of each item
So that I know how much of the ingredient I still have.

Example:

* 2 eggs
* 500g pasta
* 1 milk carton

---

### Track Expiration Dates

As a user
I want to track expiration dates
So that I can consume items before they expire.

The system should highlight items that will expire soon.

---

### Remove or Update Items

As a user
I want to update or remove items
So that my inventory remains accurate.

---

### Recipe Suggestions

As a user
I want recipe suggestions based on my inventory
So that I can cook meals with ingredients I already have.

---

# Functional Requirements

The system must allow:

* Adding inventory items
* Updating inventory items
* Deleting inventory items
* Viewing all items
* Sorting items by expiration date
* Filtering items by category
* Linking inventory items to ingredients database

---

# Inventory Data Model

Inventory items are linked to global ingredients.

Relationship:

User → Inventory Item → Ingredient

---

## Database Tables

### ingredients

Stores global ingredient definitions.

Fields:

* id (uuid)
* name (text)
* category (text)
* barcode (text)
* image_url (text)
* created_at (timestamp)

---

### user_inventory

Stores ingredients owned by a specific user.

Fields:

* id (uuid)
* user_id (uuid)
* ingredient_id (uuid)
* quantity (numeric)
* unit (text)
* expiry_date (date)
* added_at (timestamp)

---

# Inventory Item Example

Example entry:

Ingredient: Milk
Quantity: 1
Unit: liter
Expiration date: 2026-04-01

---

# UI Requirements

## Inventory Screen

Displays all items in a list.

Each item should display:

* ingredient name
* quantity
* unit
* expiration date
* product image (optional)

Items close to expiration should be visually highlighted.

Example:

Milk — 1L — expires in 2 days

---

## Add Item Screen

Users can add items with:

* ingredient name
* quantity
* unit
* expiration date

Optionally:

* barcode scan
* product image

---

## Edit Item Screen

Users can update:

* quantity
* expiration date

---

# Barcode Integration

If a user scans a barcode:

1. Scan barcode using mobile_scanner
2. Query OpenFoodFacts API
3. Extract product information
4. Create ingredient if not existing
5. Add ingredient to inventory

---

# Inventory → Recipe Integration

Inventory ingredients are used for recipe generation.

Process:

1. Fetch all ingredients from user_inventory
2. Extract ingredient names
3. Send ingredient list to AI recipe generator
4. Generate recipes that use those ingredients

Example input to AI:

Eggs
Milk
Tomatoes
Cheese

---

# Edge Cases

Product not found in OpenFoodFacts:

User should manually enter ingredient name.

---

Expired items:

Expired items should be flagged in the inventory list.

---

Empty inventory:

User should see message:

"No ingredients in inventory yet."

---

# Performance Considerations

Inventory queries should always be filtered by user_id.

Indexes should be created on:

* user_inventory.user_id
* ingredients.barcode

---

# Security

All inventory data must be restricted to the authenticated user.

Use Supabase Row Level Security.

Policy example:

Users can only access their own inventory items.

---

# MVP Scope

The MVP version should include:

* Add inventory item
* Edit inventory item
* Delete inventory item
* View inventory list
* Barcode scanning
* Recipe suggestions using inventory

Advanced features like receipt scanning can be added later.

---

# Future Enhancements

* Automatic expiration reminders
* Fridge photo recognition
* Smart meal planning
* Nutrition tracking
* Shared household inventory
