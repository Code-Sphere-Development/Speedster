<?php

namespace App\Services;

/**
 * Test double: treats id_token 'valid' as a known identity, everything else invalid.
 */
class FakeSocialTokenVerifier implements SocialTokenVerifier
{
    public function verify(string $provider, string $idToken): ?SocialIdentity
    {
        if ($idToken !== 'valid') {
            return null;
        }

        return new SocialIdentity(
            providerId: 'social-123',
            email: 'social@example.com',
            name: 'Social User',
        );
    }
}
