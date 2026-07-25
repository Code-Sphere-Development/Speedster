<?php

namespace App\Services;

class SocialIdentity
{
    public function __construct(
        public string $providerId,
        public string $email,
        public ?string $name = null,
    ) {}
}
