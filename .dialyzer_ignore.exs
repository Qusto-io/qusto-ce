[
  {"lib/plausible/goals/goals.ex", :call_without_opaque},
  {"lib/plausible/sites.ex", :call_without_opaque},
  {"lib/plausible/teams/invitations.ex", :call_without_opaque},
  {"lib/plausible_web/live/components/modal.ex", :pattern_match, 1},
  # Static analysis runs as MIX_ENV=ce_test, so EE-only branches constant-fold
  # away. These warnings are that fold, not a new defect.
  {"lib/plausible/billing/qouta/quota.ex", :pattern_match},
  {"lib/plausible/teams.ex", :pattern_match_cov},
  {"lib/plausible/teams.ex", :exact_eq},
  {"lib/plausible/teams/invitations.ex", :exact_eq},
  {"lib/plausible/teams/memberships.ex", :pattern_match},
  {"lib/plausible/teams/memberships/leave.ex", :exact_eq},
  {"lib/plausible/teams/memberships/remove.ex", :exact_eq},
  {"lib/plausible_web/live/site_transfer_settings.ex", :pattern_match},
  {"lib/plausible_web/templates/settings/preferences.html.heex", :pattern_match},
  {"lib/plausible_web/templates/settings/preferences.html.heex", :exact_eq},
  {"lib/plausible_web/templates/settings/security.html.heex", :pattern_match},
  {"lib/plausible_web/templates/settings/security.html.heex", :exact_eq},
  {"lib/plausible_web/views/layout_view.ex", :pattern_match}
]
