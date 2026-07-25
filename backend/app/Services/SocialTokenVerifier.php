<?php

namespace App\Services;

interface SocialTokenVerifier
{
    /**
     * Verify a provider id_token server-side. Returns the verified identity,
     * or null if the token is invalid/expired/untrusted.
     */
    public function verify(string $provider, string $idToken): ?SocialIdentity;
}
