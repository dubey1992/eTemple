<?php

use App\Exceptions\ApiExceptionRenderer;
use App\Http\Middleware\EnsureUserIsActive;
use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Http\Request;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__.'/../routes/web.php',
        api: __DIR__.'/../routes/api.php',
        commands: __DIR__.'/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware) {
        // Sanctum stateful (cookie/session) authentication for the Flutter Web
        // client: adds cookie encryption, session and CSRF validation to API
        // requests that originate from a configured stateful domain.
        // CORS is already part of the framework's global stack.
        $middleware->statefulApi();

        $middleware->alias([
            'active' => EnsureUserIsActive::class,
        ]);

        /*
         * Never redirect an unauthenticated API request.
         *
         * Laravel's default is to send a guest to a route named `login`, which
         * this API does not have — so the redirect threw a
         * RouteNotFoundException and the caller got a 500 where a 401 belonged.
         *
         * It stayed hidden because every test and every live check sends
         * `Accept: application/json`, which takes a different path. What does
         * not is a **top-level browser navigation** — which is exactly how a
         * report export, a donation receipt and a transaction's bill are
         * opened. Returning null here makes the guard throw
         * AuthenticationException, which the renderer already turns into a
         * clean 401.
         */
        $middleware->redirectGuestsTo(
            fn (Request $request) => $request->is('api/*') ? null : '/login',
        );
    })
    ->withExceptions(function (Exceptions $exceptions) {
        ApiExceptionRenderer::register($exceptions);
    })
    ->create();
