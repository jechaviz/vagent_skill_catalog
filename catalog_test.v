module vagent_skill_catalog

fn test_exact_site_action_match() {
	found := match_action('open issues', 'github.com')
	assert found.found
	assert found.action.id == 'github.issues'
	assert resolve_route(found.action, 'https://github.com/jechaviz/hebrowser') ==
		'https://github.com/jechaviz/hebrowser/issues'
}

fn test_side_effect_action_requires_confirmation() {
	found := match_action('star repository', 'github.com')
	assert found.found
	assert found.action.side_effect
	assert contract(found.action).confirmation_required()
}

fn test_irrelevant_speech_is_not_forced() {
	assert !match_action('my inbox is a disaster', 'github.com').found
}
