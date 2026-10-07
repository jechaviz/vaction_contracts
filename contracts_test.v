module vaction_contracts

fn test_action_contract_classification() {
	shell := contract_for_action('Shell.Run')
	assert shell.risk == .high
	assert shell.confirmation_required()
	browser := contract_for_action('Browser.Navigate')
	assert browser.category == 'browser'
	assert browser.risk == .medium
	assert !browser.confirmation_required()
	submit := contract_for_action('Browser.Submit')
	assert submit.category == 'browser'
	assert submit.risk == .high
	assert submit.confirmation_required()
	assert .network in submit.effects
}

fn test_secret_redaction() {
	assert is_secret_key('api_token')
	assert redact_key_value('api_token', 'abcdef') == 'ab***ef'
	assert redact_key_value('name', 'abcdef') == 'abcdef'
}
