module vagent_skill_catalog

import json2
import os

pub const agent_catalog_schema = 'vagent.skill_catalog.v1'

pub struct AgentSkillEntry {
pub:
	name          string
	source_author string
	source_skill  string
	source_slug   string
	kind          string
	description   string
	adapters      []string
	source_url    string
	catalog_page  string
	repo_path     string
}

pub struct AgentSkillStats {
pub:
	skills          int
	authors         int
	local_upstreams int
	adapters        map[string]int
	kinds           map[string]int
}

pub fn decode_entries(text string) ![]AgentSkillEntry {
	return json2.decode[[]AgentSkillEntry](text)!
}

pub fn encode_entries(entries []AgentSkillEntry) string {
	return json2.encode(entries)
}

pub fn catalog_stats(entries []AgentSkillEntry) AgentSkillStats {
	mut authors := map[string]bool{}
	mut adapters := map[string]int{}
	mut kinds := map[string]int{}
	mut local_count := 0
	for entry in entries {
		author := entry.source_author.trim_space().to_lower()
		if author != '' {
			authors[author] = true
		}
		kind := entry.kind.trim_space().to_lower()
		if kind != '' {
			kinds[kind] = kinds[kind] + 1
		}
		for raw in entry.adapters {
			adapter := raw.trim_space().to_lower()
			if adapter != '' {
				adapters[adapter] = adapters[adapter] + 1
			}
		}
		if entry.repo_path.trim_space() != ''
			&& os.exists(os.join_path(entry.repo_path, 'upstream')) {
			local_count++
		}
	}
	return AgentSkillStats{
		skills: entries.len
		authors: authors.len
		local_upstreams: local_count
		adapters: adapters
		kinds: kinds
	}
}

pub fn find_entries(entries []AgentSkillEntry, query string) []AgentSkillEntry {
	clean := query.trim_space().to_lower()
	if clean == '' {
		return entries.clone()
	}
	mut matches := []AgentSkillEntry{}
	for entry in entries {
		if entry.name.to_lower().contains(clean)
			|| entry.source_skill.to_lower().contains(clean)
			|| entry.source_slug.to_lower().contains(clean)
			|| entry.kind.to_lower() == clean
			|| entry.description.to_lower().contains(clean)
			|| entry.adapters.any(it.to_lower() == clean) {
			matches << entry
		}
	}
	return matches
}

pub fn adapters_for(entries []AgentSkillEntry) []string {
	mut out := []string{}
	for entry in entries {
		for raw in entry.adapters {
			adapter := raw.trim_space()
			if adapter != '' && adapter !in out {
				out << adapter
			}
		}
	}
	out.sort()
	return out
}
