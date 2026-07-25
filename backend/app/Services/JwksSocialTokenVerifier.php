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

        // Fail closed: without a configured audience we cannot bind the token to
        // THIS app, so any valid Google/Apple token would otherwise be accepted.
        if (! $audience) {
            return null;
        }

        try {
            $keys = JWK::parseKeySet($this->jwks($provider));
            $claims = (array) JWT::decode($idToken, $keys);

            // Apple may issue `aud` as an array; normalize before comparing.
            $aud = $claims['aud'] ?? null;
            $audMatches = is_array($aud)
                ? in_array($audience, $aud, true)
                : $aud === $audience;
            if (! $audMatches) {
                return null;
            }
            if (! in_array($claims['iss'] ?? '', self::ISSUERS[$provider], true)) {
                return null;
            }
            if (empty($claims['sub']) || empty($claims['email'])) {
                return null;
            }
            // Require an explicitly verified email. Google sends a bool, Apple a
            // string "true"; anything else (incl. a missing claim) is rejected to
            // prevent account takeover via an unverified/attacker-controlled email.
            $emailVerified = $claims['email_verified'] ?? null;
            if ($emailVerified !== true && $emailVerified !== 'true') {
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
        // Short TTL limits exposure if a key is rotated/compromised. TLS verify
        // is on by default; an explicit timeout avoids hanging on a slow endpoint.
        return Cache::remember("jwks.$provider", now()->addMinutes(10), function () use ($provider) {
            $keys = Http::timeout(5)->get(self::JWKS[$provider])->throw()->json();
            if (! is_array($keys) || ! isset($keys['keys']) || ! is_array($keys['keys'])) {
                throw new \RuntimeException("Invalid JWKS response for {$provider}");
            }

            return $keys;
        });
    }
}
