<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\SocialTokenVerifier;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'string', 'min:8'],
            'country' => ['nullable', 'string', 'size:2'],
        ]);

        $user = User::create([
            'name' => $data['name'],
            'email' => $data['email'],
            'password' => Hash::make($data['password']),
            'country' => $data['country'] ?? null,
        ]);

        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'user' => $this->userPayload($user),
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email' => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $user = User::where('email', $data['email'])->first();
        if (! $user || ! $user->password || ! Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['Die Anmeldedaten sind ungültig.'],
            ]);
        }

        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'user' => $this->userPayload($user),
        ]);
    }

    public function social(Request $request, SocialTokenVerifier $verifier)
    {
        $data = $request->validate([
            'provider' => ['required', 'in:apple,google'],
            'id_token' => ['required', 'string'],
        ]);

        $identity = $verifier->verify($data['provider'], $data['id_token']);
        if (! $identity) {
            throw ValidationException::withMessages([
                'id_token' => ['Das Social-Token ist ungültig.'],
            ]);
        }

        $user = User::firstOrCreate(
            ['provider' => $data['provider'], 'provider_id' => $identity->providerId],
            ['name' => $identity->name ?? 'Speedster', 'email' => $identity->email],
        );

        return response()->json([
            'token' => $user->createToken('app')->plainTextToken,
            'user' => $this->userPayload($user),
        ]);
    }

    public function me(Request $request)
    {
        return response()->json($this->userPayload($request->user()));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Abgemeldet.']);
    }

    private function userPayload(User $user): array
    {
        return [
            'id' => $user->id,
            'name' => $user->name,
            'email' => $user->email,
            'country' => $user->country,
        ];
    }
}
