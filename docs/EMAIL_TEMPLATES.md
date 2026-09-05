# The e-mail this system sends

**Date:** 2026-09-15

Four messages, and nothing else leaves this application by e-mail. Each has a
designed bilingual template with an HTML and a plain-text part, signed by the
temple rather than by the software.

## The four

| Message | Goes to | Fires when | Queued? |
|---|---|---|---|
| `AccountInvitation` | a new committee member | an administrator creates their account | no |
| `PasswordResetMail` | a committee member | they use "forgot password", or an administrator resends a link | no |
| `AnnouncementNotification` | every active committee account with an e-mail address | somebody sends a published announcement, by hand | **yes** |
| `EnquiryAcknowledgement` | the visitor who wrote in | an enquiry is submitted — **only when switched on** | **yes** |

**Nothing is sent to devotees, donors or the public**, with the single exception
of the acknowledgement, which is off by default (`ENQUIRY_ACKNOWLEDGEMENT_ENABLED`).
There is no newsletter, no marketing list and no automatic mail about donations:
a donor's e-mail address is given to record a receipt, not to be written to.

## Where they live

```
resources/views/mail/
  layout.blade.php              the shell every message is wrapped in
  button.blade.php              a call to action that survives Outlook
  account-created.blade.php
  password-reset.blade.php
  announcement.blade.php
  enquiry-acknowledgement.blade.php
  text/                         the plain-text half of each of the above
    signature.blade.php         the temple's contact block
```

The temple's name, address, telephone and e-mail come from the CMS through
`App\Support\MailBranding` — never from `APP_NAME` and never compiled in. A
temple that has not filled the profile in still gets a legible message; it
simply says less.

## Design decisions worth knowing before you change one

* **No images, no web fonts, no external stylesheet.** Mail clients block remote
  images by default and many strip `<style>`, so everything that matters is
  inline and made of text. It also costs nothing to open on a village
  connection.
* **Tables and inline styles.** Outlook still lays out with tables.
* **Both languages in one message.** Hindi first, English after a rule. There is
  no per-recipient language column, and sending two messages would double what a
  committee member has to read.
* **Every message has a plain-text alternative.** Some clients show it, some
  readers prefer it, and a message with no text part scores worse with spam
  filters.
* **The acknowledgement quotes nothing the sender typed.** The address it goes
  to was supplied by whoever filled the form and need not be theirs; echoing
  their words would let a stranger send chosen text from the temple's own domain
  to someone else's inbox. It carries a reference number and a category from a
  fixed catalogue, and that is all.
* **The announcement carries the committee's words, escaped.** The author is
  trusted to write the notice, not to have avoided a `<` by accident.
* **The invitation is not the reset.** A new member has never had a password;
  telling them somebody requested a *reset* is confusing at best and reads like
  phishing at worst. The invitation names the account and the role, so a real
  one can be told from a forged one.
* **The reset never says "you requested this".** It cannot know, and claiming it
  is how a phishing habit gets taught. It says what to do if it was *not* them.
* **No password is ever mailed.** An account is created with an unusable random
  hash and the member sets their own.
* **The two password messages are not queued.** Everything else is. A reset
  sitting in a queue nobody is running is indistinguishable from one that
  failed, and the person waiting for it is locked out.

`tests/Feature/Mail/EmailTemplateTest.php` asserts every one of these against
the real rendered templates.

## Before this goes to production

- [ ] Set `MAIL_MAILER` to something real. It is `log` in development, which
      means **nothing is sent** and every message lands in `storage/logs`
- [ ] Set `MAIL_FROM_ADDRESS` to an address on the temple's own domain, and
      publish SPF (and DKIM if the provider offers it). Mail claiming to be from
      a domain with no SPF record is filed as spam, and this is a temple's only
      automated mail
- [ ] **Run a queue worker.** `QUEUE_CONNECTION=database`, and announcements and
      acknowledgements are queued. Without a worker they are written to the jobs
      table and never sent — and the announcement screen will still say it was
      sent, because what it records is what the queue was handed
- [ ] Decide whether to switch on `ENQUIRY_ACKNOWLEDGEMENT_ENABLED`. It is a
      courtesy to a villager who wrote in, and it is also mail sent to an
      address a stranger typed. The per-address cooldown
      (`ENQUIRY_ACK_COOLDOWN_MINUTES`) is what stops it being used to bombard
      somebody
- [ ] Send one of each to a real inbox and read it on a phone. Gmail, Outlook
      and a phone's default client render Devanagari differently, and the only
      way to know is to look
- [ ] Check the temple profile has a name **and** an English name: the English
      half of every message uses the Roman spelling, and falls back to the
      Devanagari when there is none
