# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability within BearWave Android, please send an email to the project maintainer via GitHub.

Please include the following information:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- Initial response: within 48 hours
- Assessment: within 1 week
- Fix deployment: depends on severity

## Scope

This security policy applies to:

- The BearWave Android Flutter application
- API communications with radio-browser.info
- Background audio and Android Auto MediaBrowserService behavior
- Google Cast discovery and Cast session control
- Local data storage (SharedPreferences)

## Best Practices

- The app does not collect or transmit personal data
- All API communication uses HTTPS
- Internet radio stream URLs are loaded from Radio Browser or user-added stations
- Cast device discovery stays on the local network
- No secrets or API keys are hardcoded
- Local storage is limited to app preferences only
