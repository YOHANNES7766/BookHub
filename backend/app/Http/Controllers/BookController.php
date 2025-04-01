<?php

namespace App\Http\Controllers;

use App\Models\Book;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Validator;

class BookController extends Controller
{
    // Fetch all books for a user, optionally filtered by category
    public function index(Request $request)
    {
        $query = Book::where('user_id', Auth::id());

        if ($request->has('category_id')) {
            $query->where('category_id', $request->category_id);
        }

        $books = $query->get();
        return response()->json($books, 200);
    }

    // Store a new book in the database
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string|max:255',
            'author' => 'required|string|max:255',
            'category_id' => 'required|exists:categories,id', // Ensure category exists
            'description' => 'nullable|string',
            'cover_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'pdf_file' => 'nullable|file|mimes:pdf|max:10000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 400);
        }

        $bookData = $request->all();
        $bookData['user_id'] = Auth::id(); // Associate book with logged-in user

        // Handle cover image upload
        if ($request->hasFile('cover_image')) {
            $bookData['cover_image'] = $request->file('cover_image')->store('cover_images', 'public');
        }

        // Handle PDF file upload
        if ($request->hasFile('pdf_file')) {
            $bookData['pdf_file'] = $request->file('pdf_file')->store('pdfs', 'public');
        }

        // Create the book record in the database
        $book = Book::create($bookData);
        return response()->json($book, 201); // Return created book
    }

    // Show a specific book
    public function show($id)
    {
        $book = Book::where('id', $id)->where('user_id', Auth::id())->first();
        if (!$book) {
            return response()->json(['message' => 'Book not found'], 404);
        }
        return response()->json($book, 200);
    }

    // Update an existing book
    public function update(Request $request, $id)
    {
        $book = Book::where('id', $id)->where('user_id', Auth::id())->first();
        if (!$book) {
            return response()->json(['message' => 'Book not found'], 404);
        }

        $validator = Validator::make($request->all(), [
            'title' => 'sometimes|string|max:255',
            'author' => 'sometimes|string|max:255',
            'category_id' => 'sometimes|exists:categories,id',
            'description' => 'nullable|string',
            'cover_image' => 'nullable|image|mimes:jpeg,png,jpg,gif|max:2048',
            'pdf_file' => 'nullable|file|mimes:pdf|max:10000',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 400);
        }

        // Handle file updates
        if ($request->hasFile('cover_image')) {
            $book->cover_image = $request->file('cover_image')->store('cover_images', 'public');
        }

        if ($request->hasFile('pdf_file')) {
            $book->pdf_file = $request->file('pdf_file')->store('pdfs', 'public');
        }

        // Update the book data
        $book->update($request->except(['cover_image', 'pdf_file']));
        return response()->json($book, 200);
    }

    // Delete a specific book
    public function destroy($id)
    {
        $book = Book::where('id', $id)->where('user_id', Auth::id())->first();
        if (!$book) {
            return response()->json(['message' => 'Book not found'], 404);
        }

        $book->delete();
        return response()->json(['message' => 'Book deleted successfully'], 200);
    }
}
