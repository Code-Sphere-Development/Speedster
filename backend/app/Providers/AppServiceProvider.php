<?php

namespace App\Providers;

use App\Services\JwksSocialTokenVerifier;
use App\Services\SocialTokenVerifier;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->app->bind(SocialTokenVerifier::class, JwksSocialTokenVerifier::class);
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        //
    }
}
