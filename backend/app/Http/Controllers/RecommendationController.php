<?php

namespace App\Http\Controllers;

use App\Models\Recommendation;
use Illuminate\Http\Request;

class RecommendationController extends Controller
{
    // Store a new recommendation
    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'book_id' => 'required|exists:books,id',
            'recommendation_message' => 'required|string',
        ]);

        $recommendation = Recommendation::create([
            'user_id' => $request->user_id,
            'book_id' => $request->book_id,
            'recommendation_message' => $request->recommendation_message,
        ]);

        return response()->json($recommendation, 201);
    }

    // Get all recommendations
    public function index()
    {
        $recommendations = Recommendation::all();
        return response()->json($recommendations);
    }

    // Get a specific recommendation
    public function show($id)
    {
        $recommendation = Recommendation::findOrFail($id);
        return response()->json($recommendation);
    }

    // Update a specific recommendation
    public function update(Request $request, $id)
    {
        $recommendation = Recommendation::findOrFail($id);

        $recommendation->update([
            'recommendation_message' => $request->recommendation_message,
        ]);

        return response()->json($recommendation);
    }

    // Delete a specific recommendation
    public function destroy($id)
    {
        $recommendation = Recommendation::findOrFail($id);
        $recommendation->delete();

        return response()->json(['message' => 'Recommendation deleted successfully']);
    }
}
