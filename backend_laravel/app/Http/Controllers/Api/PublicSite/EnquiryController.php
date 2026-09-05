<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Exceptions\EnquiryGuardException;
use App\Http\Controllers\Controller;
use App\Http\Requests\Enquiries\StoreEnquiryRequest;
use App\Services\Enquiries\EnquiryFormToken;
use App\Services\Enquiries\EnquiryService;
use App\Services\Enquiries\EnquirySpamGuard;
use App\Support\ApiResponse;
use App\Support\EnquiryCategory;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The temple's contact form — the only place an anonymous stranger writes to
 * this database.
 *
 * Two endpoints and no third: fetch a form, send a message. There is no public
 * read of an enquiry at any status, so nothing a visitor sends can be served
 * back to anybody, including themselves (PHASE_7_PLAN assumption N1).
 */
class EnquiryController extends Controller
{
    public function __construct(
        private readonly EnquiryService $enquiries,
        private readonly EnquiryFormToken $tokens,
        private readonly EnquirySpamGuard $spam,
    ) {}

    /**
     * GET /api/public/enquiry-form
     *
     * Issues the ticket the form must be submitted with, and — once this
     * address has sent enough messages — the question it must answer.
     */
    public function form(Request $request): JsonResponse
    {
        $ipHash = $this->spam->ipHash($request->ip());

        $form = $this->tokens->issue($ipHash, $this->spam->requiresChallenge($ipHash));

        return ApiResponse::success([
            'token' => $form['token'],
            'challenge' => $form['challenge'],
            'min_fill_seconds' => $form['min_fill_seconds'],
            'expires_in_seconds' => $form['expires_in_seconds'],
            'categories' => array_map(
                static fn (string $code): array => [
                    'code' => $code,
                    'label' => EnquiryCategory::label($code),
                ],
                EnquiryCategory::all(),
            ),
            'max_message_length' => (int) config('enquiries.max_message_length', 2000),
            'min_message_length' => (int) config('enquiries.min_message_length', 20),
        ]);
    }

    /**
     * POST /api/public/enquiries
     *
     * Returns a reference number and nothing else. Echoing the stored row back
     * would make this endpoint a reflector: anybody could POST content and have
     * the temple's own API serve it to them.
     */
    public function store(StoreEnquiryRequest $request): JsonResponse
    {
        $ipHash = $this->spam->ipHash($request->ip());

        // The honeypot, before anything else is spent on this request. The
        // answer is the success shape: a bot that is told it was detected is a
        // bot whose author gets to tune it (assumption N2, layer 2). Nothing is
        // stored, nothing is counted, no mail is sent.
        if (($request->validated('website') ?? '') !== '') {
            return ApiResponse::success(
                ['reference' => null, 'message' => $this->thanks()],
                status: 201,
            );
        }

        $this->spam->assertWithinDailyLimit($ipHash);

        $this->tokens->consume(
            $request->validated('form_token'),
            $request->validated('challenge_answer'),
            $ipHash,
            // Re-evaluated now, not when the form was fetched: a ticket taken
            // before the abuse started is not a way past the threshold.
            $this->spam->requiresChallenge($ipHash),
        );

        $mobile = $request->validated('mobile');
        $email = $request->validated('email');

        if (($mobile ?? '') === '' && ($email ?? '') === '') {
            throw EnquiryGuardException::contactChannelRequired();
        }

        $enquiry = $this->enquiries->record(
            [
                'name' => $request->validated('name'),
                'mobile' => $mobile,
                'email' => $email,
                'category' => $request->validated('category'),
                'message' => $request->validated('message'),
                'preferred_language' => $request->validated('preferred_language')
                    ?? Language::fromRequest($request->query('lang'))->value,
            ],
            $ipHash,
            $request->userAgent(),
        );

        return ApiResponse::success(
            ['reference' => $enquiry->reference, 'message' => $this->thanks()],
            status: 201,
        );
    }

    /**
     * The one line the visitor is told, identical for a real message and for a
     * honeypot hit — so the two cannot be told apart from outside.
     */
    private function thanks(): string
    {
        return 'आपका संदेश प्राप्त हुआ। समिति शीघ्र ही संपर्क करेगी। / '
            .'Your message has been received. The committee will be in touch shortly.';
    }
}
