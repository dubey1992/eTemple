<?php

declare(strict_types=1);

namespace App\Services\Donations;

use App\Models\Donation;
use App\Services\Temple\TempleProfileService;
use App\Support\DonationPurpose;
use App\Support\Money;
use App\Support\PaymentMode;

/**
 * Renders a donation receipt as a print-ready HTML document.
 *
 * ## Why HTML and not PDF
 *
 * The specification asks for a "printable/PDF receipt", and this produces one
 * by handing the browser a document it can print — to paper or to PDF.
 *
 * The reason is Devanagari. A donor is `श्री रामप्रसाद यादव`, and rendering that
 * means reordering matras and forming conjuncts. `dompdf` and the FPDF family
 * do not shape complex scripts: they would print the letters in the wrong
 * order, on a receipt for money. Every browser ships a shaping engine and a PDF
 * writer, and the committee already has one open
 * (PHASE_6_PLAN assumption N10).
 *
 * ## Why this is not Blade
 *
 * There is exactly **one** place in this class where a value reaches the
 * document — {@see self::escape()} — and every field goes through it. That is a
 * smaller and more checkable surface than a template where `{!! !!}` is one
 * keystroke away, and it needs no view layer for a single document.
 *
 * A reversed donation prints as **CANCELLED**, in the largest type on the page.
 * Handing somebody a receipt for money that is no longer in the books, with
 * nothing to say so, is the one genuinely dangerous thing this file could do.
 */
class ReceiptRenderer
{
    public function __construct(private readonly TempleProfileService $temple) {}

    public function render(Donation $donation): string
    {
        $data = $this->data($donation);

        $rows = [
            ['रसीद संख्या / Receipt No.', $data['receipt_number']],
            ['दिनांक / Date', $data['donation_date']],
            ['दानदाता / Donor', $data['donor_name']],
            ...($data['donor_phone'] !== null ? [['दूरभाष / Phone', $data['donor_phone']]] : []),
            ...($data['donor_address'] !== null ? [['पता / Address', $data['donor_address']]] : []),
            ['उद्देश्य / Purpose', $data['purpose']],
            ['भुगतान माध्यम / Mode', $data['payment_mode']],
            ...($data['reference_number'] !== null
                ? [['संदर्भ / Reference', $data['reference_number']]]
                : []),
        ];

        $lines = '';
        foreach ($rows as [$label, $value]) {
            $lines .= sprintf(
                "        <tr><th>%s</th><td>%s</td></tr>\n",
                $this->escape($label),
                $this->escape((string) $value),
            );
        }

        $cancelled = $data['is_reversed']
            ? sprintf(
                '<div class="cancelled">रद्द / CANCELLED</div>'
                    .'<p class="cancelled-reason">%s</p>',
                $this->escape($data['reversal_reason'] ?? ''),
            )
            : '';

        return sprintf(
            <<<'HTML'
            <!doctype html>
            <html lang="hi">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>%s</title>
            <style>
              :root { --ink:#2f2926; --muted:#6f655f; --primary:#8b1e3f; --line:#e6d8cc; }
              * { box-sizing: border-box; }
              body {
                margin: 0; padding: 24px;
                font-family: "Noto Sans Devanagari","Segoe UI",Arial,sans-serif;
                color: var(--ink); background: #f4efe7; line-height: 1.55;
              }
              .sheet {
                max-width: 720px; margin: 0 auto; background: #fff; padding: 32px;
                border: 1px solid var(--line); border-radius: 14px;
              }
              header { text-align: center; border-bottom: 2px solid var(--primary); padding-bottom: 14px; }
              h1 { margin: 0 0 4px; font-size: 24px; color: var(--primary); }
              .address { margin: 0; font-size: 13px; color: var(--muted); }
              h2 { margin: 22px 0 14px; font-size: 17px; text-align: center; letter-spacing: .04em; }
              table { width: 100%%; border-collapse: collapse; }
              th, td { text-align: left; padding: 8px 0; border-bottom: 1px dashed var(--line); vertical-align: top; }
              th { width: 42%%; font-weight: 600; color: var(--muted); font-size: 13px; }
              td { font-size: 15px; }
              .amount { margin: 22px 0 0; padding: 14px 16px; background: #fff8ec; border: 1px solid var(--line); border-radius: 10px; }
              .amount .figure { font-size: 28px; font-weight: 800; color: var(--primary); }
              .amount .words { font-size: 13px; color: var(--muted); }
              footer { margin-top: 26px; display: flex; justify-content: space-between; gap: 16px; font-size: 12px; color: var(--muted); }
              .sign { margin-top: 44px; border-top: 1px solid var(--line); padding-top: 6px; min-width: 190px; text-align: center; }
              .cancelled {
                margin: 18px 0 0; padding: 10px; text-align: center;
                font-size: 30px; font-weight: 900; letter-spacing: .12em;
                color: #b3261e; border: 3px solid #b3261e; border-radius: 10px;
              }
              .cancelled-reason { text-align: center; font-size: 13px; color: #b3261e; margin: 8px 0 0; }
              .print { display: block; max-width: 720px; margin: 0 auto 14px; text-align: right; }
              .print button {
                font: inherit; padding: 8px 16px; border-radius: 999px; cursor: pointer;
                border: 1px solid var(--primary); background: var(--primary); color: #fff;
              }
              @media print {
                body { background: #fff; padding: 0; }
                .sheet { border: 0; border-radius: 0; padding: 0; max-width: none; }
                .print { display: none; }
              }
            </style>
            </head>
            <body>
            <div class="print"><button type="button" onclick="window.print()">प्रिंट / Print</button></div>
            <div class="sheet">
              <header>
                <h1>%s</h1>
                <p class="address">%s</p>
              </header>
              %s
              <h2>दान रसीद &nbsp;·&nbsp; DONATION RECEIPT</h2>
              <table>
            %s      </table>
              <div class="amount">
                <div class="figure">%s</div>
                <div class="words">%s</div>
              </div>
              <footer>
                <div>%s</div>
                <div class="sign">अधिकृत हस्ताक्षर / Authorised signature</div>
              </footer>
            </div>
            </body>
            </html>

            HTML,
            $this->escape($data['document_title']),
            $this->escape($data['temple_name']),
            $this->escape($data['temple_address']),
            $cancelled,
            $lines,
            $this->escape($data['amount_formatted']),
            $this->escape($data['amount_words']),
            $this->escape($data['issued_line']),
        );
    }

    /**
     * The receipt's content, separately from its presentation.
     *
     * Split out so the wording can be asserted without parsing HTML, and so a
     * real PDF renderer — if a shaping engine ever becomes available — has
     * something to consume.
     *
     * @return array<string, mixed>
     */
    public function data(Donation $donation): array
    {
        $profile = $this->temple->current();

        $templeName = trim((string) ($profile->name_hi ?: $profile->name_en));
        $address = implode(', ', array_filter([
            $profile->address_line1,
            $profile->village,
            $profile->district,
            $profile->state,
            $profile->postal_code,
        ], static fn ($part) => trim((string) $part) !== ''));

        $receiptNumber = $donation->receipt_number
            ?? 'अप्रकाशित / not yet issued';

        return [
            'document_title' => trim($templeName.' — '.$receiptNumber),
            'temple_name' => $templeName !== '' ? $templeName : 'मंदिर',
            'temple_address' => $address,
            'receipt_number' => $receiptNumber,
            'donation_date' => $donation->donation_date->format('d/m/Y'),
            'donor_name' => $donation->donor_name,
            'donor_phone' => $donation->donor_phone,
            'donor_address' => $donation->donor_address,
            // Words, not codes: a receipt that says "cash" to a villager in
            // Amarpur Pankhoriya is not a receipt they can read.
            'purpose' => DonationPurpose::label($donation->purpose),
            'payment_mode' => PaymentMode::label($donation->payment_mode),
            'reference_number' => $donation->reference_number,
            'amount_formatted' => Money::format($donation->amount_paise),
            'amount_words' => Money::toWords($donation->amount_paise),
            'is_reversed' => $donation->isReversed(),
            'reversal_reason' => $donation->reversal_reason,
            'issued_line' => $donation->confirmed_at === null
                ? 'निर्गत नहीं / not issued'
                : 'निर्गत / Issued: '.$donation->confirmed_at->format('d/m/Y')
                    .($donation->confirmedBy?->fullName() !== null
                        ? ' · '.$donation->confirmedBy->fullName()
                        : ''),
        ];
    }

    /**
     * The one place a value becomes part of the document.
     *
     * A donor name is typed by a committee member and may contain anything;
     * this is what stops `<script>` in a name from executing in whatever
     * browser prints the receipt.
     */
    private function escape(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }
}
