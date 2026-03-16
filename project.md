# Smart Kitchen App

## Project Overview

Smart Kitchen is a mobile application that helps users manage their food inventory and generate recipes from available ingredients.

The app allows users to:

* Scan food items using barcode or camera
* Track ingredients in their fridge
* Receive recipe suggestions based on available ingredients
* Generate recipes using AI
* Manage a shopping list
* Scan grocery receipts to automatically add items to inventory

Primary goal: **Reduce food waste and simplify cooking decisions.**

---

# Tech Stack

## Frontend

Flutter

Key libraries:

* flutter_riverpod (state management)
* go_router (navigation)
* mobile_scanner (barcode scanning)
* camera
* http / dio
* freezed + json_serializable (models)

Target platforms:

* iOS
* Android

Optional later:

* Web (Flutter Web)

---

## Backend

Supabase

Services used:

* Supabase Auth
* PostgreSQL Database
* Supabase Storage
* Edge Functions
* Realtime (optional)

---

## External APIs

Food database:

OpenFoodFacts API

AI Recipe generation:

OpenAI API (GPT models)

Receipt OCR:

Google Vision API or Tesseract

---

# System Architecture

Flutter App → Supabase Backend → External APIs

Components:

Frontend (Flutter)

Handles:

* UI
* State management
* API communication

Backend (Supabase)

Handles:

* Authentication
* Database
* Storage
* Business logic via Edge Functions

External APIs

* Barcode lookup
* Recipe generation
* OCR processing

---

# Database Schema

## users

Managed by Supabase Auth.

Fields:

id (uuid)
email
created_at

---

## ingredients

Stores global ingredient definitions.

Fields:

id (uuid)
name (text)
category (text)
barcode (text)
created_at (timestamp)

---

## user_inventory

Stores ingredients owned by users.

Fields:

id (uuid)
user_id (uuid)
ingredient_id (uuid)
quantity (numeric)
unit (text)
expiry_date (date)
added_at (timestamp)

---

## recipes

Stores recipes.

Fields:

id (uuid)
title (text)
description (text)
cooking_time (integer)
difficulty (text)
created_at (timestamp)

---

## recipe_ingredients

Many-to-many relationship between recipes and ingredients.

Fields:

id (uuid)
recipe_id (uuid)
ingredient_id (uuid)
quantity (numeric)
unit (text)

---

## shopping_list

Fields:

id (uuid)
user_id (uuid)
ingredient_name (text)
quantity (numeric)
checked (boolean)
created_at (timestamp)

---

# Storage

Supabase Storage buckets:

* food_images
* receipt_images

---

# Feature Specifications

## Feature 1: Barcode Scanner

User scans a barcode.

Flow:

1. Capture barcode
2. Query OpenFoodFacts API
3. Extract product name
4. Store ingredient if not existing
5. Add ingredient to user_inventory

---

## Feature 2: Fridge Inventory

User sees list of all stored ingredients.

Functions:

* add ingredient
* edit ingredient
* delete ingredient
* filter by category
* sort by expiry date

---

## Feature 3: Recipe Suggestions

User clicks "Find Recipes".

System:

1. Fetch user ingredients
2. Send ingredient list to AI API
3. AI generates recipes
4. Show recipe cards

---

## Feature 4: AI Recipe Generator

User inputs ingredients manually.

System:

Send ingredients to AI.

Expected output format:

Recipe Title

Ingredients List

Step-by-step instructions

Cooking time

---

## Feature 5: Shopping List

User can add missing ingredients.

Functions:

* add item
* mark as completed
* delete item

---

## Feature 6: Receipt Scanner

User scans grocery receipt.

Flow:

1. Take photo
2. OCR extracts product names
3. Map to ingredients
4. Add to inventory

---

# Flutter Project Structure

lib/

core/
services/
utils/
constants/

features/

auth/
data/
domain/
presentation/

inventory/
data/
domain/
presentation/

recipes/
data/
domain/
presentation/

shopping_list/
data/
domain/
presentation/

scanner/
data/
domain/
presentation/

models/

widgets/

main.dart

---

# Development Plan

## Phase 1 — Project Setup

Tasks:

* Create Flutter project
* Setup Supabase project
* Configure authentication
* Setup database tables
* Setup Supabase client in Flutter

Deliverable:

User can register and login.

---

## Phase 2 — Inventory System

Tasks:

* Ingredient model
* Inventory CRUD
* Add ingredient manually
* Display inventory list
* Expiry date support

Deliverable:

User can manage fridge inventory.

---

## Phase 3 — Barcode Scanner

Tasks:

* Integrate mobile_scanner
* Query OpenFoodFacts API
* Map product to ingredient
* Add to inventory automatically

Deliverable:

Barcode scan adds ingredient.

---

## Phase 4 — Recipe Suggestions

Tasks:

* Integrate OpenAI API
* Send ingredient list
* Parse AI response
* Display recipe cards

Deliverable:

User receives recipe suggestions.

---

## Phase 5 — Shopping List

Tasks:

* Shopping list database table
* CRUD operations
* UI list with checkboxes

Deliverable:

Working shopping list.

---

## Phase 6 — Receipt Scanner

Tasks:

* Camera integration
* OCR API
* Parse products
* Add ingredients automatically

Deliverable:

Receipt scanning works.

---

# Coding Standards

Use:

* Clean Architecture
* Repository pattern
* Feature-based folder structure

Naming conventions:

Classes → PascalCase
variables → camelCase
files → snake_case

---

# MVP Scope

MVP should include only:

* Authentication
* Ingredient inventory
* Barcode scanning
* Recipe suggestions

Everything else is optional after MVP.

---

# Future Features

* Fridge photo recognition
* Meal planning
* Nutrition tracking
* Social recipes
* Smart grocery integration

---

# Notes for Copilot

When generating code:

* Prefer Riverpod for state management
* Use Supabase Dart client
* Keep business logic out of UI
* Follow clean architecture principles
* Generate models using freezed/json_serializable
* Prefer async/await
* Use strongly typed models
