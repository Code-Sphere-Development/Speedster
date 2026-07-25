<?php

namespace App\Services;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Production verifier: validates Google/Apple id_tokens against the provider's
 * published JWKS (signature + audience + expiry). Never trusts the client.
 */
class JwksSocialTokenVerifier implements SocialTokenVerifier
{
    private const JWKS = [
        'google' => 'https://www.googleapis.com/oauth2/v3/certs',
        'apple' => 'https://appleid.apple.com/auth/keys',
    ];

    private const ISSUERS = [
        'google' => ['https://accounts.google.com', 'accounts.google.com'],
        'apple' => ['https://appleid.apple.com'],
    ];

    public function verify(string $provider, string $idToken): ?SocialIdentity
    {
        if (! isset(self::JWKS[$provider])) {
            return null;
        }

        $audience = config("services.$provider.client_id");

        try {
            $keys = JWK::parseKeySet($this->jwks($provider));
            $claims = (array) JWT::decode($idToken, $keys);

            if ($audience && ($claims['aud'] ?? null) !== $audience) {
                return null;
            }
            if (! in_array($claims['iss'] ?? '', self::ISSUERS[$provider], true)) {
                return null;
            }
            if (empty($claims['sub']) || empty($claims['email'])) {
                return null;
            }

            return new SocialIdentity(
                providerId: $claims['sub'],
                email: $claims['email'],
                name: $claims['name'] ?? null,
            );
        } catch (Throwable) {
            return null;
        }
    }

    private function jwks(string $provider): array
    {
        return Cache::remember("jwks.$provider", now()->addHour(), function () use ($provider) {
            return Http::get(self::JWKS[$provider])->throw()->json();
        });
    }
}
