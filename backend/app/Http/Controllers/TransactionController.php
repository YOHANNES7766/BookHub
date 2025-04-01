<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use Illuminate\Http\Request;

class TransactionController extends Controller
{
    // Store a new transaction
    public function store(Request $request)
    {
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'book_id' => 'required|exists:books,id',
            'transaction_type' => 'required|string',
            'amount' => 'required|numeric',
            'status' => 'required|in:pending,completed,failed',
        ]);

        $transaction = Transaction::create([
            'user_id' => $request->user_id,
            'book_id' => $request->book_id,
            'transaction_type' => $request->transaction_type,
            'amount' => $request->amount,
            'status' => $request->status,
        ]);

        return response()->json($transaction, 201);
    }

    // Get all transactions
    public function index()
    {
        $transactions = Transaction::all();
        return response()->json($transactions);
    }

    // Get a specific transaction
    public function show($id)
    {
        $transaction = Transaction::findOrFail($id);
        return response()->json($transaction);
    }

    // Update a specific transaction
    public function update(Request $request, $id)
    {
        $transaction = Transaction::findOrFail($id);

        $transaction->update([
            'transaction_type' => $request->transaction_type,
            'amount' => $request->amount,
            'status' => $request->status,
        ]);

        return response()->json($transaction);
    }

    // Delete a specific transaction
    public function destroy($id)
    {
        $transaction = Transaction::findOrFail($id);
        $transaction->delete();

        return response()->json(['message' => 'Transaction deleted successfully']);
    }
}
