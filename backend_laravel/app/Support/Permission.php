<?php

declare(strict_types=1);

namespace App\Support;

use App\Models\Role;

/**
 * The permission catalogue — every key the permission matrix can grant.
 *
 * Keys are `module.action`. The catalogue deliberately covers modules that do
 * not exist yet (donations, events, media…) so the matrix is designed once and
 * later phases attach their endpoints to keys the committee has already been
 * granting. A key for an unbuilt module is inert: nothing checks it until its
 * phase lands (see PHASE_2_PLAN assumption C2).
 *
 * Super Admin is never listed in the defaults below. It is granted everything by
 * `Gate::before` and its set is not editable, so the temple cannot be locked out
 * of its own administration (assumption C3).
 */
final class Permission
{
    // --- Enforced today -----------------------------------------------------
    public const CONTENT_VIEW = 'content.view';

    public const CONTENT_MANAGE = 'content.manage';

    public const USERS_VIEW = 'users.view';

    public const USERS_MANAGE = 'users.manage';

    public const ROLES_VIEW = 'roles.view';

    public const ROLES_MANAGE = 'roles.manage';

    public const SECURITY_VIEW = 'security.view';

    public const SECURITY_MANAGE = 'security.manage';

    // --- Reserved for later phases (granted now, enforced when built) -------
    public const TEMPLE_MANAGE = 'temple.manage';           // Phase 3

    public const EVENTS_MANAGE = 'events.manage';           // Phase 4

    public const MEDIA_MANAGE = 'media.manage';             // Phase 5

    public const DONATIONS_VIEW = 'donations.view';         // Phase 6

    public const DONATIONS_MANAGE = 'donations.manage';     // Phase 6

    public const ENQUIRIES_MANAGE = 'enquiries.manage';     // Phase 7

    public const ANNOUNCEMENTS_MANAGE = 'announcements.manage'; // Phase 8

    public const ACCOUNTS_VIEW = 'accounts.view';           // Phase 9

    public const ACCOUNTS_MANAGE = 'accounts.manage';       // Phase 9

    public const REPORTS_VIEW = 'reports.view';             // Phase 10

    public const REPORTS_EXPORT = 'reports.export';         // Phase 10

    /**
     * The catalogue, grouped by module, in the order the matrix renders it.
     *
     * `phase` tells the UI which keys are not yet enforced, so the committee is
     * not misled into thinking a toggle already does something.
     *
     * @return array<string, array{label: string, phase: int, permissions: array<string, string>}>
     */
    public static function catalogue(): array
    {
        return [
            'content' => [
                'label' => 'Website content',
                'phase' => 1,
                'permissions' => [
                    self::CONTENT_VIEW => 'View pages and settings',
                    self::CONTENT_MANAGE => 'Edit and publish pages and settings',
                ],
            ],
            'users' => [
                'label' => 'Users',
                'phase' => 2,
                'permissions' => [
                    self::USERS_VIEW => 'View committee accounts',
                    self::USERS_MANAGE => 'Create, edit and deactivate accounts',
                ],
            ],
            'roles' => [
                'label' => 'Roles and permissions',
                'phase' => 2,
                'permissions' => [
                    self::ROLES_VIEW => 'View roles and their permissions',
                    self::ROLES_MANAGE => 'Change what each role may do',
                ],
            ],
            'security' => [
                'label' => 'Security',
                'phase' => 2,
                'permissions' => [
                    self::SECURITY_VIEW => 'View login history',
                    self::SECURITY_MANAGE => 'Change security settings',
                ],
            ],
            'temple' => [
                'label' => 'Temple profile and committee',
                'phase' => 3,
                'permissions' => [self::TEMPLE_MANAGE => 'Edit temple profile and committee'],
            ],
            'events' => [
                'label' => 'Puja and events',
                'phase' => 4,
                'permissions' => [self::EVENTS_MANAGE => 'Manage aarti, festivals and events'],
            ],
            'media' => [
                'label' => 'Gallery and video',
                'phase' => 5,
                'permissions' => [self::MEDIA_MANAGE => 'Upload and publish photos and videos'],
            ],
            'donations' => [
                'label' => 'Donations',
                'phase' => 6,
                'permissions' => [
                    self::DONATIONS_VIEW => 'View donation records',
                    self::DONATIONS_MANAGE => 'Record donations and issue receipts',
                ],
            ],
            'enquiries' => [
                'label' => 'Devotee enquiries',
                'phase' => 7,
                'permissions' => [self::ENQUIRIES_MANAGE => 'Read and answer enquiries'],
            ],
            'announcements' => [
                'label' => 'Announcements',
                'phase' => 8,
                'permissions' => [self::ANNOUNCEMENTS_MANAGE => 'Publish notices and reminders'],
            ],
            'accounts' => [
                'label' => 'Accounts',
                'phase' => 9,
                'permissions' => [
                    self::ACCOUNTS_VIEW => 'View income and expense records',
                    self::ACCOUNTS_MANAGE => 'Record and approve transactions',
                ],
            ],
            'reports' => [
                'label' => 'Reports',
                'phase' => 10,
                'permissions' => [
                    self::REPORTS_VIEW => 'View reports',
                    self::REPORTS_EXPORT => 'Export reports',
                ],
            ],
        ];
    }

    /** Every valid key, flattened. @return list<string> */
    public static function all(): array
    {
        $keys = [];
        foreach (self::catalogue() as $module) {
            foreach (array_keys($module['permissions']) as $key) {
                $keys[] = $key;
            }
        }

        return $keys;
    }

    public static function exists(string $key): bool
    {
        return in_array($key, self::all(), true);
    }

    /**
     * Default permissions per role, encoding the specification's descriptions:
     * a Treasurer runs money but not security; a Content Manager runs content
     * but never sees financial detail.
     *
     * Super Admin is absent on purpose — see the class docblock.
     *
     * @return array<string, list<string>>
     */
    public static function defaultsByRole(): array
    {
        return [
            Role::ADMIN => array_values(array_diff(self::all(), [
                // Day-to-day administration, but not the keys to the kingdom:
                // reshaping roles or security stays with the Super Admin.
                self::ROLES_MANAGE,
                self::SECURITY_MANAGE,
            ])),

            Role::TREASURER => [
                self::CONTENT_VIEW,
                self::DONATIONS_VIEW,
                self::DONATIONS_MANAGE,
                self::ACCOUNTS_VIEW,
                self::ACCOUNTS_MANAGE,
                self::REPORTS_VIEW,
                self::REPORTS_EXPORT,
            ],

            Role::CONTENT_MANAGER => [
                self::CONTENT_VIEW,
                self::CONTENT_MANAGE,
                self::TEMPLE_MANAGE,
                self::EVENTS_MANAGE,
                self::MEDIA_MANAGE,
                self::ANNOUNCEMENTS_MANAGE,
                self::ENQUIRIES_MANAGE,
                // Deliberately no donations.* or accounts.*: the specification
                // says a Content Manager cannot see sensitive financial detail.
            ],

            Role::VIEWER => [
                self::CONTENT_VIEW,
                self::DONATIONS_VIEW,
                self::ACCOUNTS_VIEW,
                self::REPORTS_VIEW,
            ],
        ];
    }
}
