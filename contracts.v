module vaction_contracts

pub enum Risk {
	low
	medium
	high
	critical
}

pub enum Effect {
	read
	local_write
	process
	network
	browser_session
	desktop_input
	external_message
	model_call
	credential_use
}

pub struct ActionContract {
pub:
	action                string
	skill                 string
	category              string
	risk                  Risk = .medium
	effects               []Effect
	evidence              []string
	mockable              bool
	requires_confirmation bool
}

pub fn action_skill(action string) string {
	parts := action.split('.').filter(it.trim_space() != '')
	if parts.len < 2 {
		return ''
	}
	return parts[0]
}

pub fn contract_for_action(action string) ActionContract {
	skill := action_skill(action)
	if skill == '' {
		return match action {
			'Note', 'Set' {
				new_contract(action, '', 'local', .low, [Effect.local_write], ['value'], true, false)
			}
			else {
				new_contract(action, '', 'unknown', .medium, []Effect{}, ['manual_review'], false,
					true)
			}
		}
	}
	return match skill {
		'FS', 'Framework' {
			new_contract(action, skill, 'local', .low, [Effect.local_write], ['path'], true,
				false)
		}
		'Shell' {
			new_contract(action, skill, 'shell', .high, [Effect.process, Effect.local_write],
				['command', 'exit_code'], false, true)
		}
		'HTTP', 'GraphQL', 'WS' {
			new_contract(action, skill, 'network', .medium, [Effect.network], ['status'],
				true, false)
		}
		'CDP', 'Browser', 'BrowserUIA' {
			new_contract(action, skill, 'browser', .medium, [Effect.browser_session],
				['session_id', 'url'], true, false)
		}
		'AppCapture' {
			new_contract(action, skill, 'capture', .medium, [Effect.read], ['window', 'image'],
				true, false)
		}
		'AppDrive' {
			new_contract(action, skill, 'desktop', .high, [Effect.desktop_input],
				['window', 'input_receipt'], true, true)
		}
		'LLM', 'Vision' {
			new_contract(action, skill, 'ai', .medium, [Effect.model_call], ['provider', 'usage'],
				true, false)
		}
		'Messaging' {
			new_contract(action, skill, 'messaging', .high, [Effect.external_message],
				['channel', 'recipient'], true, true)
		}
		'Trace' {
			new_contract(action, skill, 'observability', .low, [Effect.local_write], ['event'],
				true, false)
		}
		else {
			new_contract(action, skill, 'unknown', .medium, []Effect{}, ['manual_review'], false,
				true)
		}
	}
}

pub fn risk_for_categories(categories []string) Risk {
	for category in categories {
		if category in ['shell', 'messaging', 'desktop'] {
			return .high
		}
	}
	for category in categories {
		if category in ['browser', 'network', 'ai', 'capture', 'unknown'] {
			return .medium
		}
	}
	return .low
}

pub fn max_risk(a Risk, b Risk) Risk {
	return if int(a) >= int(b) { a } else { b }
}

pub fn (contract ActionContract) valid() bool {
	return contract.action.trim_space() != '' && contract.category.trim_space() != ''
}

pub fn (contract ActionContract) confirmation_required() bool {
	return contract.requires_confirmation || contract.risk in [.high, .critical]
}

fn new_contract(action string, skill string, category string, risk Risk, effects []Effect,
	evidence []string, mockable bool, requires_confirmation bool) ActionContract {
	return ActionContract{
		action:                action
		skill:                 skill
		category:              category
		risk:                  risk
		effects:               effects
		evidence:              evidence
		mockable:              mockable
		requires_confirmation: requires_confirmation
	}
}
