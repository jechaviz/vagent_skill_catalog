module vagent_skill_catalog

import vaction_contracts

fn test_exact_site_action_match() {
	found := match_action('open issues', 'github.com')
	assert found.found
	assert found.action.id == 'github.issues'
	assert resolve_route(found.action, 'https://github.com/jechaviz/hebrowser') ==
		'https://github.com/jechaviz/hebrowser/issues'
}

fn test_side_effect_action_requires_high_risk_confirmation() {
	found := match_action('star repository', 'github.com')
	assert found.found
	assert found.action.side_effect
	action_contract := contract(found.action)
	assert action_contract.risk == .high
	assert action_contract.confirmation_required()
	assert vaction_contracts.Effect.network in action_contract.effects
}

fn test_irrelevant_speech_is_not_forced() {
	assert !match_action('my inbox is a disaster', 'github.com').found
}


fn test_generic_agent_catalog_search_and_stats() {
	entries := [
		AgentSkillEntry{
			name: 'openai-pdf'
			source_author: 'openai'
			source_skill: 'pdf'
			source_slug: 'openai/pdf'
			kind: 'knowledge'
			description: 'PDF processing'
			adapters: ['vimport', 'vhub']
		},
		AgentSkillEntry{
			name: 'frontend-design'
			source_author: 'anthropic'
			source_skill: 'frontend-design'
			source_slug: 'anthropic/frontend-design'
			kind: 'interface'
			description: 'Frontend design'
			adapters: ['waibav']
		},
	]
	stats := catalog_stats(entries)
	assert stats.skills == 2
	assert stats.authors == 2
	assert stats.adapters['vimport'] == 1
	assert stats.kinds['knowledge'] == 1
	assert find_entries(entries, 'pdf').len == 1
	assert find_entries(entries, 'waibav').len == 1
	assert adapters_for(entries) == ['vhub', 'vimport', 'waibav']
	roundtrip := decode_entries(encode_entries(entries)) or { panic(err.msg()) }
	assert roundtrip.len == 2
	assert roundtrip[0].source_slug == 'openai/pdf'
}
