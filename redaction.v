module vaction_contracts

const secret_markers = ['secret', 'token', 'api_key', 'apikey', 'password', 'passwd',
	'authorization', 'auth', 'cookie', 'session', 'private_key']

pub fn is_secret_key(key string) bool {
	low := key.to_lower()
	for marker in secret_markers {
		if low.contains(marker) {
			return true
		}
	}
	return false
}

pub fn redact_text(value string) string {
	if value.len <= 4 {
		return '***'
	}
	return value[..2] + '***' + value[value.len - 2..]
}

pub fn redact_key_value(key string, value string) string {
	if is_secret_key(key) && value.trim_space() != '' {
		return redact_text(value)
	}
	return value
}

pub fn redact_map(values map[string]string) map[string]string {
	mut out := map[string]string{}
	for key, value in values {
		out[key] = redact_key_value(key, value)
	}
	return out
}
