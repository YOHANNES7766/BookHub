<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTransactionsTable extends Migration
{
    public function up()
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Reference to users table
            $table->foreignId('book_id')->constrained()->onDelete('cascade'); // Reference to books table
            $table->string('transaction_type'); // e.g., buy, borrow, etc.
            $table->decimal('amount', 8, 2); // For price or fee if applicable
            $table->enum('status', ['pending', 'completed', 'failed']); // Status of the transaction
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('transactions');
    }
}
