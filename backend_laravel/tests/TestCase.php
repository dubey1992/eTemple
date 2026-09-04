<?php

declare(strict_types=1);

namespace Tests;

use Illuminate\Foundation\Testing\TestCase as BaseTestCase;

abstract class TestCase extends BaseTestCase
{
    protected function setUp(): void
    {
        parent::setUp();

        // The Flutter Web client always calls the API cross-origin from a
        // stateful domain. Sending the same Origin header here means the tests
        // exercise the real Sanctum stateful (cookie/session) path rather than a
        // stateless shortcut.
        $this->withHeader('Origin', (string) config('app.frontend_url'));
        $this->withHeader('Accept', 'application/json');
    }
}
