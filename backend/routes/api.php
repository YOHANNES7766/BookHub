<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\BookController;
use App\Http\Controllers\CategoryController;
use App\Http\Controllers\TransactionController; // Add this line for TransactionController
use App\Http\Controllers\RecommendationController; // Add this line for RecommendationController
use Illuminate\Support\Facades\Route;
use Illuminate\Http\Request;

/*
|---------------------------------------------------------------------------
| API Routes
|---------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// Authentication Routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    // Logout route
    Route::post('/logout', [AuthController::class, 'logout']);
    
    // Get authenticated user info
    Route::get('/user', function (Request $request) {
        return response()->json($request->user());
    });

    // Book Management Routes
    Route::post('/books', [BookController::class, 'store']);  // Create Book
    Route::get('/books', [BookController::class, 'index']);   // Get All Books
    Route::get('/books/{id}', [BookController::class, 'show']); // Get Single Book
    Route::put('/books/{id}', [BookController::class, 'update']); // Update Book
    Route::delete('/books/{id}', [BookController::class, 'destroy']); // Delete Book

    // Transaction Routes
    Route::post('/transactions', [TransactionController::class, 'store']); // Store Transaction
    Route::get('/transactions', [TransactionController::class, 'index']); // Get All Transactions
    Route::get('/transactions/{id}', [TransactionController::class, 'show']); // Get Single Transaction
    Route::put('/transactions/{id}', [TransactionController::class, 'update']); // Update Transaction
    Route::delete('/transactions/{id}', [TransactionController::class, 'destroy']); // Delete Transaction

    // Recommendation Routes
    Route::post('/recommendations', [RecommendationController::class, 'store']); // Store Recommendation
    Route::get('/recommendations', [RecommendationController::class, 'index']); // Get All Recommendations
    Route::get('/recommendations/{id}', [RecommendationController::class, 'show']); // Get Single Recommendation
    Route::put('/recommendations/{id}', [RecommendationController::class, 'update']); // Update Recommendation
    Route::delete('/recommendations/{id}', [RecommendationController::class, 'destroy']); // Delete Recommendation
});

// Category Routes
Route::apiResource('categories', CategoryController::class);
