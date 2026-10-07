module vagent_skill_catalog

import vaction_contracts

pub struct SkillAction {
pub:
	id                    string
	domain                string
	host_suffix           string
	description           string
	phrases               []string
	terms                 []string
	command               string
	route_suffix          string
	action_name           string = 'Browser.Act'
	requires_confirmation bool
	side_effect           bool
}

pub struct Match {
pub:
	found  bool
	action SkillAction
	score  int
	source string
}

pub fn all_actions() []SkillAction {
	mut out := []SkillAction{}
	out << github_actions()
	return out
}

pub fn actions_for_host(host string) []SkillAction {
	normalized := host.trim_space().to_lower()
	return all_actions().filter(normalized == it.host_suffix || normalized.ends_with('.' + it.host_suffix))
}

pub fn match_action(phrase string, host string) Match {
	clean := normalize_phrase(phrase)
	if clean == '' {
		return Match{}
	}
	for action in actions_for_host(host) {
		for candidate in action.phrases {
			if clean == normalize_phrase(candidate) {
				return Match{
					found: true
					action: action
					score: 100
					source: 'phrase'
				}
			}
		}
	}
	words := semantic_words(clean)
	mut best := SkillAction{}
	mut best_score := 0
	mut tied := false
	for action in actions_for_host(host) {
		mut samples := [action.description, action.id.replace('.', ' '), action.command]
		samples << action.terms
		mut score := 0
		for sample in samples {
			for word in semantic_words(sample) {
				if word in words {
					score++
				}
			}
		}
		if score > best_score {
			best = action
			best_score = score
			tied = false
		} else if score > 0 && score == best_score {
			tied = true
		}
	}
	if best_score < 2 || tied {
		return Match{}
	}
	return Match{
		found: true
		action: best
		score: best_score
		source: 'lexical'
	}
}

pub fn contract(action SkillAction) vaction_contracts.ActionContract {
	base := vaction_contracts.contract_for_action(action.action_name)
	return vaction_contracts.ActionContract{
		...base
		action: action.action_name
		requires_confirmation: base.requires_confirmation || action.requires_confirmation || action.side_effect
	}
}

pub fn resolve_route(action SkillAction, current_url string) string {
	if action.route_suffix == '' {
		return ''
	}
	if action.host_suffix == 'github.com' {
		base := github_repo_base(current_url)
		if base == '' {
			return ''
		}
		return base + action.route_suffix
	}
	return ''
}

fn github_actions() []SkillAction {
	return [
		SkillAction{
			id: 'github.issues'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'open repository issues'
			phrases: ['open issues', 'show issues', 'issues', 'abre issues', 'ver issues', 'muestra incidencias']
			terms: ['bug reports', 'reported problems', 'problemas abiertos', 'incidencias']
			command: 'open_issues'
			route_suffix: '/issues'
		},
		SkillAction{
			id: 'github.pull_requests'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'open pull requests'
			phrases: ['open pull requests', 'show pull requests', 'pull requests', 'pulls', 'abre pull requests', 'muestra prs']
			terms: ['proposed changes', 'code reviews', 'cambios por revisar']
			command: 'open_pull_requests'
			route_suffix: '/pulls'
		},
		SkillAction{
			id: 'github.actions'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'open actions and CI runs'
			phrases: ['open actions', 'show actions', 'actions', 'abre actions', 'muestra workflows', 'muestra ci']
			terms: ['build status', 'automation runs', 'continuous integration']
			command: 'open_actions'
			route_suffix: '/actions'
		},
		SkillAction{
			id: 'github.releases'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'open repository releases'
			phrases: ['open releases', 'show releases', 'releases', 'abre releases', 'muestra versiones']
			terms: ['published versions', 'latest version', 'release downloads']
			command: 'open_releases'
			route_suffix: '/releases'
		},
		SkillAction{
			id: 'github.code'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'open repository code'
			phrases: ['open code', 'show code', 'code', 'abre codigo', 'abre código', 'muestra archivos']
			terms: ['source files', 'repository files', 'project files']
			command: 'open_code'
		},
		SkillAction{
			id: 'github.readme'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'show repository readme'
			phrases: ['open readme', 'show readme', 'read readme', 'abre readme', 'muestra documentacion', 'muestra documentación']
			terms: ['project instructions', 'documentation', 'how this project works']
			command: 'open_readme'
			route_suffix: '#readme'
		},
		SkillAction{
			id: 'github.star'
			domain: 'browser.site'
			host_suffix: 'github.com'
			description: 'star this repository'
			phrases: ['star this repository', 'star repository', 'star repo', 'dale star', 'marca con estrella']
			terms: ['save repository to stars', 'favorite project']
			command: 'star_repository'
			requires_confirmation: true
			side_effect: true
		},
	]
}

fn github_repo_base(url string) string {
	mut value := url.trim_space()
	if value.starts_with('https://') {
		value = value[8..]
	} else if value.starts_with('http://') {
		value = value[7..]
	}
	slash := value.index('/') or { return '' }
	host := value[..slash].split(':')[0].to_lower()
	if host != 'github.com' {
		return ''
	}
	parts := value[slash + 1..].split('/').filter(it.trim_space() != '')
	if parts.len < 2 {
		return ''
	}
	owner := parts[0].trim_space()
	repo := parts[1].trim_space().split('#')[0].split('?')[0]
	if owner == '' || repo == '' {
		return ''
	}
	return 'https://github.com/${owner}/${repo}'
}

fn normalize_phrase(input string) string {
	return input.to_lower().split_any(' \t\r\n,.;:!?()[]{}"\'').filter(it != '').join(' ')
}

fn semantic_words(input string) []string {
	mut words := []string{}
	for word in normalize_phrase(input).split(' ') {
		if word == '' || word in ['the', 'a', 'an', 'to', 'this', 'that', 'me', 'my', 'of',
			'and', 'show', 'open', 'go', 'view', 'please', 'el', 'la', 'los', 'las', 'de',
			'y', 'abre', 'muestra', 'ver'] {
			continue
		}
		if word !in words {
			words << word
		}
	}
	return words
}
